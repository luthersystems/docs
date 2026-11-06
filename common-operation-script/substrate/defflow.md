---
description: (Experimental) Write a business process that waits for inputs, connector replies and other flows across many transactions as one straight-line defflow body.
---

# Durable Flows (defflow)

> **Experimental.** `defflow` is an experimental feature. Its forms, options,
> endpoints and stored records can change in a later substrate release, and an
> upgrade can need changes to your flows. Test each substrate upgrade with your
> flows before you upgrade production, and read the
> [release notes](../../release-notes.md) for each release. Contact Luther
> before you use a flow in production.

`defflow` defines a durable flow: a process that waits for inputs, connector
replies or other flows across many transactions. You write the body as
straight-line code. Substrate splits the body at each wait (an await). Each
block between two awaits runs in its own transaction, and the flow saves its
local variables on the ledger between blocks.

Use a flow when one business process spans more than one transaction. Without
`defflow`, you must write one endpoint per step and keep the state of the
process in your own records. With `defflow`, substrate generates the endpoints,
stores the state, checks who may send each input, and handles timeouts and
retries.

`defflow` is in substrate v2.252.0 and later. A libschema validator as
`:schema` or `:result-schema` needs v2.253.0. `let` patterns and `match`
around an await need v2.254.0.

| Use a flow for | Example |
|---|---|
| A wait for a person | An underwriter approves a loan |
| A wait for an external system | A credit score from a connector |
| A deadline | Escalate if no decision arrives in 72 hours |
| A process that starts other processes | A claim starts one payment flow per payee |

## A first flow

This flow gets a credit score from a connector. If the score is low, it waits
for an underwriter's decision.

```lisp
(in-package 'loanflow)
(use-package 'router)
(use-package 'defflow)

(defflow loan (ctx app)
  (:connector-msp "Org1MSP" :start-from ("BankMSP") :admin-from ("SchedulerMSP")
   :connector-timeout "1h")
  (let ([score (get (await-connector 'credit-score (credit-event app) :retries 2)
                    "score")])
    (when (< score 650)
      (let ([d (await-input 'underwriter :from ("UnderwriterMSP")
                            :timeout "72h")])
        (unless (equal? (get d "decision") "approve")
          (done (sorted-map "decision" "denied")))))
    (sorted-map "decision" "disbursed")))
```

The form is `(defflow NAME (CTX PARAMS...) (OPTIONS...) BODY...)`.

- `CTX` names the flow context. Read it with the `flow:` accessors (see
  [Flow context](#flow-context)). Do not save it, return it or assign it.
- `PARAMS` are the parameters of the start endpoint.
- The value of the last form is the result of the run.

Without retries or timeouts, this flow runs in up to three transactions:

1. `loan_start` (from `BankMSP`) runs to the first await and sends the
   credit score request to the connector.
2. The connector reply runs the block that checks the score. A low score
   waits at `underwriter`.
3. `loan_underwriter` (from `UnderwriterMSP`) runs the last block, which ends
   the run.

Each connector retry and each expired deadline adds one transaction.

## A full example

The [sandbox](https://github.com/luthersystems/sandbox) reference application
runs an insurance claim as a flow. The claim waits for a claimant input, then
for an identity check and a policy lookup through ConnectorHub.

| File | Content |
|---|---|
| [`phylum/claim.lisp`](https://github.com/luthersystems/sandbox/blob/main/phylum/claim.lisp) | The claim flow |
| [`phylum/claim_test.lisp`](https://github.com/luthersystems/sandbox/blob/main/phylum/claim_test.lisp) | Tests that use the `flow-test` package |
| [`phylum/flows/claim.mmd`](https://github.com/luthersystems/sandbox/blob/main/phylum/flows/claim.mmd) | The flow's state graph, drawn by `shirotester flow-graph` |
| [`phylum/README.md`](https://github.com/luthersystems/sandbox/blob/main/phylum/README.md#the-claim-flow) | A walk through the flow and its endpoints |

## Awaits

Each await has a quoted label. A label must be unique in its flow. The run
stores the label it waits at.

| Form | Waits for | Main options |
|---|---|---|
| `(await-input 'L)` | A call to the flow's `L` input endpoint | `:from` (required: the MSPs that may send the input, for example `("A" "B")`), `:allow` (a predicate for more checks), `:key` (a lookup key), `:schema` (JSON Schema or a [libschema validator](../ellipse-dev-language/schema.md)), `:timeout` |
| `(await-connector 'L EVENT)` | The ConnectorHub reply to `EVENT` | `:retries`, `:timeout` |
| `(await-flow 'L FLOW INPUT)` | A child run of `FLOW` to end | `:timeout` |

The value of an await is the input, the connector reply or the child's result.

`:timeout` is a Go duration string, for example `"90s"`, `"1h30m"` or
`"120h"`. Every `await-connector` needs its own `:timeout` or the flow's
`:connector-timeout`. A connector reply is not delivered again if its
transaction fails, so a connector wait without a deadline could wait forever.

### Errors at an await

Add `:on-error HANDLER` to an await to handle its error. The handler gets a map
with `"kind"`, `"message"` and `"data"`. The value of the handler is the value
of the await.

| Kind | Cause |
|---|---|
| `connector-error` | The connector failed, after all `:retries` |
| `timeout` | The await's deadline passed |
| `child-failed` | A child run failed |
| `cancelled` | An admin cancelled the run |

Without `:on-error`, the error fails the run. You can also catch the error
with `handler-bind` or `ignore-errors` around the await.

```lisp
(await-connector 'payment (payment-event app)
  :timeout "10m"
  :on-error (lambda (e)
              (if (equal? (get e "kind") "timeout")
                  (await-connector 'status (status-event app) :timeout "10m")
                  (fail (get e "message")))))
```

An inline `:on-error` lambda can await, call `done` and call `fail`. It is the
only `lambda` that can await. Its labels get the await's label as a prefix, so
the `status` await above is `payment/status`.

### Other body forms

| Form | Effect |
|---|---|
| `(done VALUE)` | Ends the run in state `done`. A map value is the result |
| `(fail REASON)` | Ends the run in state `failed` |
| `(start-flow 'L FLOW INPUT)` | Starts a detached run of `FLOW` and returns its run ID. The parent does not wait for it |

A run is in one of three states: `waiting`, `done` or `failed`.

`while` loops, `let` and `let*` patterns
([Destructuring in let](../ellipse-dev-language/let-destructuring.md)),
`match` ([Pattern Matching](../ellipse-dev-language/pattern-matching.md)),
`handler-bind`, `ignore-errors`, `flet` and `labels` work across awaits. An
await inside `dotimes`, `with-cleanup` or a `lambda` (other than an inline
`:on-error` handler) is a compile error. Use
`while` for a loop that awaits.

## Values across an await

A run saves only its local variables. Everything else comes from the phylum
again when the run resumes.

- A write to a global variable in a flow body is lost at the next await. Keep
  the state of the process in locals.
- The saved locals of one run must encode to 16 KiB or less. A larger set
  fails the block and names the largest locals. Keep large data in your own
  records and save only the keys in the flow.
- A per-transaction value, such as `(flow:now ctx)` or `(flow:sender ctx)`,
  changes after each await. Read it again after the await. Do not keep it in a
  local across an await.

## Flow context

Read the flow context with these accessors from package `flow`.

| Accessor | Value | Same in every block |
|---|---|---|
| `(flow:run-id ctx)` | Run ID | Yes |
| `(flow:name ctx)` | Flow name | Yes |
| `(flow:caller ctx)` | MSP that started the run | Yes |
| `(flow:started-at ctx)` | Start time, RFC 3339 | Yes |
| `(flow:parent ctx)` | Parent run ID, or nil | Yes |
| `(flow:now ctx)` | This transaction's timestamp | No |
| `(flow:sender ctx)` | MSP that sent this transaction | No |
| `(flow:step ctx)` | The label this block resumed at | No |
| `(flow:step-key ctx)` | The idempotency key of the next await | No |

`(flow:step-key ctx)` gives a key that is the same when a transaction is
retried. Put it in a connector event, so that the external system can drop a
duplicate request.

## Options

| Option | Meaning |
|---|---|
| `:start-from` | The MSPs that may start a run, for example `("BankMSP")` |
| `:public-start` | `true`: any MSP may start a run |
| `:child-of` | Only a run of the named parent flow may start this flow |
| `:connector-msp` | The MSP that must send connector replies. Required when the flow has an `await-connector` |
| `:connector-timeout` | The deadline of each `await-connector` without its own `:timeout` |
| `:admin-from` | The MSPs that may call the admin endpoints and fire deadlines. Required when any await has a deadline |
| `:get-from` | The MSPs that may read a run. The default is `:start-from` and each literal `:from` MSP. Required when there is no default: with `:child-of`, a computed `:from` or an `:allow` |
| `:store` | `:public`, or a private data collection name. The default is the `private` collection |
| `:start-idempotent` | `true` (the default): the start endpoint takes a required `request_key` first. `false`: the key is an optional last parameter |
| `:audit-identity` | `true`: each history row records the sender MSP |
| `:endpoints` | Renames endpoints, for example `(:start "create_claim" :get "get_claim" claimant "add_claimant")`. `nil` in place of a name drops that endpoint |
| `:expose` | Saved locals that `_get` returns under `"vars"` |
| `:result-schema` | A JSON Schema or libschema validator that the result must match |
| `:version` | The flow's version. Raise it when the flow's awaits, labels or saved locals change (see [Upgrades](#upgrades)) |

Use exactly one of `:start-from`, `:public-start` and `:child-of`.

## Endpoints

Substrate registers these endpoints for each flow. The names replace `-` and
`/` with `_`. The `:endpoints` option can rename them.

| Endpoint | Parameters | Caller |
|---|---|---|
| `NAME_start` | `request_key PARAMS...` | `:start-from` |
| `NAME_get` | `run_id` | `:get-from` |
| `NAME_history` | `run_id &optional bookmark` | `:get-from` |
| `NAME_L` (one per `await-input`) | `run_id input gen &optional request_key` | The await's `:from` |
| `NAME_L_by_key` (with `:key`) | `key input gen &optional request_key` | The await's `:from` |
| `NAME_expire` | `run_id gen` | `:admin-from` |
| `NAME_cancel` | `run_id gen &optional reason` | `:admin-from` |
| `NAME_fail` | `run_id gen &optional reason` | `:admin-from` |

- A start runs once for each caller and `request_key`. A retry with the same
  key and parameters returns the first run.
- `gen` is the run's wait generation. Each endpoint returns it. An input names
  the generation it is for, so an input for an old wait is refused as
  `stale-generation`.
- Start, input and admin calls return only `run_id`, `flow`, `state`, `gen`
  and `label`. Read the result and the exposed locals with `NAME_get`.

A refused call answers with an error code: `forbidden`, `bad-request`,
`not-found`, `not-waiting`, `stale-generation`, `deadline-passed`, `not-due`,
`start-rejected`, `request-key-reused` or `schema`.

## Deadlines and the scheduler

A deadline does not fire by itself. A scheduler from an `:admin-from` MSP must
query `$flow_tick` for the due items and call `NAME_expire` for each one.
ConnectorHub (v0.0.26 or later) has this scheduler. Without ConnectorHub, see
[Use defflow without ConnectorHub](#use-defflow-without-connectorhub). Turn it on in the
ConnectorHub configuration:

```yaml
scheduler:
  interval: 30s
```

Add ConnectorHub's MSP to each flow's `:admin-from`, and set `interval`
shorter than your shortest flow timeout. Configure the scheduler on one
ConnectorHub per network, or turn on leader election. See
[Connector Hub](../../connectors/connectorhub.md).

## Use defflow without ConnectorHub

A flow needs ConnectorHub only for `await-connector`. A flow that uses only
`await-input`, `await-flow` and `start-flow` runs without ConnectorHub. Your
own service (for example the oracle) calls the start and input endpoints.

| Feature | Needs ConnectorHub |
|---|---|
| `await-input`, `await-flow`, `start-flow`, `done`, `fail` | No |
| `await-connector` and `:connector-msp` | Yes |
| `:timeout` on an await | No. A scheduler must fire the deadlines (see below) |

A deadline needs a scheduler. Without ConnectorHub, your own service can be the
scheduler. It must use an identity of an `:admin-from` MSP, and at a fixed
interval:

1. Query `$flow_tick`. Pass `max_items` (1 to 100, default 10) as transient
   data. The answer lists the due items as
   `{"due" [{"flow" "run_id" "gen" "kind" "due_at"} ...] "count" N "next" CURSOR}`.
2. For each item, call `NAME_expire` with `run_id` and `gen`, each in its own
   transaction.
3. If `next` is set, query again with `next` as the transient `after`.

Run only one scheduler for each network. Two schedulers expire the same runs,
and the duplicate calls fail.

## Child flows

`await-flow` starts a child run and waits for it to end. `start-flow` starts a
child run and does not wait.

- A child flow must have `:child-of` set to the parent flow, or
  `:public-start true`. A flow with `:child-of` also needs `:get-from`.
- Runs nest at most 4 deep. One transaction starts at most 8 child runs.
- A parent that ends, or leaves an `await-flow`, cancels the child it waits
  for. A `start-flow` child is detached: it keeps running when the parent ends.

## Upgrades

A run stays on the phylum version it started on, until it ends. A new phylum
version does not change the code of a running run, so a new version can remove
or change any label while runs wait there.

To move waiting runs to a new version, add a `defflow-migration` form to the
new phylum. It names the flow versions and, for each label, how to compute the
new version's locals from the old ones:

```lisp
(defflow-migration loan :from "1" :to "2"
  (at 'approval :when (< amount 1000000)
      (let* ([amount-cents (* amount 100)]
             [risk-score (score-risk applicant)]))))
```

In this example, version 1 saved the locals `amount` and `applicant` at the
`approval` await. Version 2 needs `amount-cents` and `risk-score`. A run whose
`:when` test is false stays on version 1.

Only the runs that wait at a label that an `at` clause lists move. The runs
move in bulk when you run `shiroclient init` for the new version. With
`:lazy true` on the form, a run also moves when an event reaches it. Locals that
no clause binds keep their values by name. Test a migration with the
`flow-test` package before you deploy it.

A flow's manifest (its labels, awaits, saved locals and options) is fixed for
each `:version`. If you change the manifest, raise `:version`. An install that
changes the manifest of a stored version is refused.

You cannot disable a phylum version while a run waits on it.

## Test a flow

| Tool | Use |
|---|---|
| `flow-test` package | Test helpers for `*_test.lisp`: `start`, `input`, `reply`, `tick`, `advance`, `run`, `history` and more. Each call runs as its own simulated transaction |
| `shirotester flow-test --phylum DIR SCENARIO.yaml` | Runs YAML scenarios against the phylum in memory |
| `shirotester flow-graph --format mermaid` | Draws each flow's state graph |
| `shirotester lint` | Reports flow errors, for example a connector await without a deadline or a write to a global in a flow body |

## Before you deploy

- Flow records, step counts and endpoint answers are part of consensus.
  Upgrade every peer of a channel together before you install a phylum with a
  flow.
- Give the `:connector-msp` identity to ConnectorHub only. Any identity of that
  MSP can answer a connector request.
- Do not call flow endpoints through another chaincode
  (`cc:invoke-chaincode`). Call them directly.
