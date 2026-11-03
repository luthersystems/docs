---
description: These utility functions are provided in the utils package for writing migration transactions.
---

# Automated Migrations

## Automated Migrations with Context

## 1\. Introduction

**Version Requirements** Substrate and Shiroclient CLI must be at least version `v2.208.0` (the first release containing the idempotency fix and the recursive in-transaction execution loop).

In production environments, large data migrations can quickly exceed transaction size limits, hit execution timeouts, and become cumbersome to manage. Historically, users had to comment and uncomment individual migration blocks, deploy each batch manually, and rerun initialization for every segment. This context-based migration feature automates batching, tracks progress via a serialized context map, and orchestrates repeated transactions until completion, ensuring safe, efficient, and resumable migrations.

## 2\. Prerequisites

-   **Substrate Runtime**: Version `v2.208.0` or later with context-based migration utilities.
-   **Shiroclient CLI**: Version `v2.208.0` or later for `init` command enhancements.
-   **Phylum Code**: Your application business logic written in ELPS.
-   **Testing Framework**: Version `v2.208.0` or later of `shirotester`, available in your local development environment.

## 3\. Overview of Context-Based Migrations

Context-based migrations allow large data migrations to be split into multiple, safe transactions. Each migration step:

1.  Receives a context map from the previous step (or empty for the first run).
2.  Processes a batch of data.
3.  Returns a new context to continue, or empty to finish.
4.  Is idempotent: each `(migration-id, serialized-input-context)` pair caches its output, so re-execution with the same input returns the cached next-context without running the body again.

Two loops drive the work:

-   **Inner loop (inside a single transaction).** Each call to `run_ctx_migrations` feeds the result of every registered migration back into itself in the per-migration loop (§4.5), stopping when the migration returns empty (done), hits a fixed point (output equals input), crosses a per-transaction storage budget, or reaches the safety cap of 10,000 inner iterations. Cached steps return instantly, so an inner loop typically fast-forwards through already-completed work and then executes fresh body code until the transaction's read/write set fills up.
-   **Outer loop (driven by the CLI).** `shiroclient init` calls `run_ctx_migrations` repeatedly, threading each call's commit block forward as the dependent block of the next call. It stops when an iteration returns an empty result or the `--iterations` cap is hit.

## 4\. Substrate Runtime Utilities

The following utilities are provided in the `utils` package. The migration engine is written in Go, so the registry and the per-migration loop have no Lisp names.

### 4.1 The ctx migration registry

A registry that holds all registered context migration functions, in the order they were registered. It has no Lisp name (in substrate v2.248.0 and earlier it was the exported vector `utils:ctx-migrations`). A phylum adds to it only with the macros below.

### 4.2 `register-migration-ctx`

Macro to register a migration by ID and function body.

### 4.3 `def-migration-ctx`

Convenience macro that wraps `register-migration-ctx` with an idempotency cache. Each call serializes its input context to JSON and looks up the key `("utl" "migration-ctx" <id> <serialized-input-ctx>)` in statedb. On a hit the cached output is returned without running the body; on a miss the body runs once and its return value is written to that key. This means a re-run with the same input context is free, and an MVCC retry of a partially-executed transaction is safe.

### 4.4 `run-ctx-migrations`

Walks the ctx migration registry and, for each registered migration, runs the per-migration loop (§4.5) with the relevant slice of the supplied context map.

### 4.5 The per-migration loop

The loop (in substrate v2.248.0 and earlier it was the Lisp function `run-migration-to-completion`) repeatedly feeds a migration's output back as its next input until one of these things happens:

1.  The iteration safety cap is hit (`"max-iterations"`, default 10,000, shared by all registered migrations) — return the context the loop was about to run (a warning is logged).
2.  The migration returns an empty map — done, drop from the result.
3.  Output equals input — fixed point reached, return as-is.
4.  A per-transaction storage budget is crossed (`"tx-max-keys"`, `"tx-max-write-bytes"`) — return the new context so the transaction commits its progress.
5.  The migration has done its allotted fresh steps for the transaction (`"max-fresh-steps-per-tx"`, default 10,000).

Change a limit at phylum load with `(utils:set-migration-loop-limit name value)`; the value must be a positive integer.

Because `def-migration-ctx` caches each step, this loop typically scans through any already-completed steps for free, then performs fresh work until the surrounding Fabric transaction's read/write set is full. The remaining state is returned to the CLI, which commits and starts the next transaction.

## 5\. Phylum Endpoint: `run_ctx_migrations`

This feature adds a new internal endpoint to the platform that is called by shiroclient automatically:

```elps
(defendpointnames "run_ctx_migrations" '("ctx") (ctx)
  (route-success (utils:run-ctx-migrations ctx)))
```

This endpoint is called by the CLI in a loop, passing the context map and returning the next context.

## 6\. CLI Integration: the `init` Command

The `shiroclient init` command has been enhanced to support context-based migrations. Two new flags drive the migration loop:

-   **`--iterations` / `-l`**: Maximum number of migration iterations (default: 0). The CLI will call `run_ctx_migrations` up to this many times or stop early if an empty context is returned.
-   **`--initial-ctx` / `-m`**: JSON string to seed the first migration context. Defaults to an empty map `{}` if omitted. Provide a JSON object whose keys are your migration IDs (the strings you passed to `def-migration-ctx`) and whose values are the per-migration context maps. Any migration not mentioned will start with an empty context. You also can use this to resume a migration that may have failed part way through execution.

**Format of `--initial-ctx`:**

```json
{
  "<migration-id-1>": { "...": "context for first migration" },
  "<migration-id-2>": { "...": "context for second migration" }
}
```

**Example:** if you have two context-based migrations registered as `def-migration-ctx "RD-451-update-property-location" …` and `def-migration-ctx "RD-12-normalize-user-emails" …`, you might write:

```bash
shiroclient init \
  -l 10 \
  -m '{
        "RD-451-update-property-location": { "bookmark": "", "batch_size": 500 },
        "RD-12-normalize-user-emails": { "last_id": "user_123" }
      }' \
  <version> <phylum.zip>
```

This tells the CLI to seed each named migration with its initial sub-context.

**Defaults:**

-   If you omit `--initial-ctx`, the CLI uses an empty map: all migrations begin at their default starting point.
-   If you include only some migration IDs, the others still run but start from an empty context.

**Execution loop and dependent-block handling.** Shiroclient executes the following steps for the `init` command:

1.  Deploy the phylum via the `update` call.
2.  Reinitialize the CLI client against the new phylum version and sleep briefly for propagation.
3.  Loop up to `--iterations`, invoking `run_ctx_migrations` with the previous response context. Each call after the first passes the prior transaction's commit block number as the dependent block, so the new transaction is guaranteed to observe the cached results written by the previous step.
4.  Exit early if a call returns an empty context (all migrations finished) or an error occurs.

A single iteration may advance through many already-cached steps and then execute one or more fresh steps until the transaction's read/write set is full — so the number of iterations needed is roughly the number of full transactions of fresh work the migration produces, not the total number of steps.

## 7\. Writing Migrations in Your Phylum

### 7.1 Syntax of `def-migration-ctx`

Define a context-aware migration with an ID and a single parameter (the context map):

```elps
(def-migration-ctx "your-migration-id" (ctx)
  ;; migration body, returning next context or empty map when complete
)
```

*NOTE*: you can specify multiple `def-migration-ctx`, all of which are executed within each iteration of the migration loop.

### 7.2 Context Parameter & Return Semantics

-   Developers decide what to store in `ctx`—it must be serializable to JSON and contain all information required for the next transaction to continue where the last one left off.
-   Return a **non-empty** map to continue migration; return an **empty** map (e.g. `(sorted-map)`) to signal completion.
-   **IMPORTANT**: Each step is cached under its serialized input context. If a step returns the same context it was given (e.g. you forgot to advance a cursor), the per-migration loop detects the fixed point and stops — but the cached output and the in-tx loop both block forward progress. Always change at least one field (bookmark, cursor, counter, etc.) when you want the migration to continue.
-   The inner loop is capped at 10,000 iterations per call (`"max-iterations"`) as a safety valve against runaway migrations; if you hit this cap it almost always means a bug in your migration body.

### 7.3 JSON Serialization Requirements

-   All keys and values in the context map must be serializable via `json:dump-bytes`.
-   Complex values should be converted to strings or basic types before returning.

### 7.4 Example Migration Definition

```elps
(defun reduce-collector-page (acc key val bookmark)
  (sorted-map "keys" (concat 'list (get acc "keys")
                             (list (sorted-map "key" key "val" val)))
              "bookmark" bookmark))
...

(def-migration-ctx "RD-1337-update-property-location" (ctx)
  (let* ([bookmark    (default (get ctx "bookmark") "")]
         [batch-size  (default (get ctx "batch_size") 1000)]
         [result      (range-page-bytes reduce-collector-page
                                        (sorted-map "keys" '() "bookmark" "")
                                        "property-index:"
                                        "property-index^"
                                        batch-size
                                        bookmark)]
         [properties  (get result "keys")]
         [next-bookmark (get result "bookmark")])
    (map () (lambda (pid)
              (migrate-property (get pid "key")))
         properties)
    (if (string? next-bookmark)
      (sorted-map "bookmark" next-bookmark "batch_size" batch-size)
      (sorted-map))))
```

## 8\. Testing with `shirotester`

### 8.1 Unit Tests in `utils_test.lisp`

The current test suite covers four scenarios — see `internal/substrate/shirocore/utils_test.lisp`:

-   **`register-migration-ctx`**: registration appends to the ctx migration registry and the wrapped lambda runs without caching.
-   **`def-migration-ctx`**: a one-shot migration returns its next context and writes the cache key; a second `run-ctx-migrations` call with the same input returns the cached output without re-running the body (verified via a call counter).
-   **`def-migration-ctx-iterative`**: a multi-step migration runs through several steps within a single `run-ctx-migrations` call (the inner loop), and a subsequent call with the same starting context completes entirely from cache.
-   **`def-migration-ctx-fixed-point`** and **`def-migration-ctx-max-iters`**: exercise the fixed-point and iteration-cap exit paths of the per-migration loop.

### 8.2 Invoking `run_ctx_migrations` in Tests

```elps
(in-package 'utils)

(use-package 'utils)
(use-package 'testing)

(test "def-migration-ctx"
  ;; Define a migration that returns a next-context map
  (def-migration-ctx "test-migration" (context)
    (cc:infof (sorted-map "context" context) "Executing migration")
    (sorted-map "next_key" "next_value"))

  (let* ([ctx (sorted-map "test-migration" (sorted-map "key" "value"))]
         [result (run-ctx-migrations ctx)])
    (assert-deep-equal
      (sorted-map "next_key" "next_value")
      (get result "test-migration"))))
```

## 9\. Best Practices & Caveats

### 9.1 Pagination via `statedb:range-page`

-   Instead of scanning all keys, `statedb:range-page` retrieves up to `page-size` keys and returns a `bookmark` for continuation. This drastically reduces the total number of keys scanned in the ledger, shrinks the read/write set, and keeps transaction payloads small (avoiding size and timeouts).
-   Tombstoned keys still occupy pagination space, which may result in more or fewer results than the specified `page-size` (see semantics section below), but no data is skipped across batches.

### 9.2 Handling Partial Batches & Tombstones

-   Design your migration logic to handle smaller and greater-than-expected batches gracefully.
-   If strict batch sizes are required, loop internally and resize the result sets until the desired count is processed.

### 9.3 Safety Guards with `--iterations`

-   The CLI’s `--iterations` (`-l`) flag caps the number of `run_ctx_migrations` transactions in a single `init` invocation. Each transaction can advance through any number of cached steps for free plus enough fresh steps to fill its read/write set, so size `-l` against the expected number of full transactions of fresh work — not the total number of migration steps. The loop exits early as soon as a transaction returns an empty result.
-   Independently, every call has an internal cap of 10,000 iterations (`"max-iterations"`) in the per-migration loop to catch runaway migrations. Hitting this almost always indicates a logic bug.
-   By default, `--iterations` is `0`, and no context-based migrations run unless you specify a positive number.

## 10\. FAQ

**Q: Is each migration step executed as a single transaction?** No — each `run_ctx_migrations` call is a single transaction, and that transaction may execute many migration steps via the inner per-migration loop. Cached steps from prior transactions resolve instantly; fresh steps execute until the transaction's read/write set fills up, at which point the CLI commits and starts the next transaction.

**Q: Are migrations paginated?** Yes. Under the hood, migrations should use `statedb:range-page` (or a custom paging loop) to fetch a subset of keys and a bookmark for the next batch.

**Q: Do we pass full migration logic for each step?** Yes. Every step includes the complete migration function body; only the context map changes between invocations.

**Q: Why do we need to set `--iterations`?** As a safety guard, `--iterations` caps the number of automated steps to prevent infinite loops due to logic errors. The loop still exits early if the migration returns an empty context.

**Q: What do the new features automate?** Previously, developers managed batching and transaction control manually. With `def-migration-ctx` and CLI looping. Now migrations run across multiple transactions automatically—no manual intervention needed.

**Q: Why can’t we run the entire migration in one transaction?** Transactions have limits on size, key count, and execution time. Splitting into batches ensures reliable commits without hitting gRPC or ledger constraints.

## 11\. Pagination `range-page` / `range-page-bytes`

### 11.1 `statedb:range-page-bytes`

Similar to `range` and `range-bytes`, but with pagination.

```elps
(range-page-bytes fn z start end page-size bookmark)
```

Best used to minimize ledger reads and transaction payloads.

-   **fn** (function): signature `(acc curr-key curr-val bookmark) -> new-acc`, where `curr-val` is raw bytes.
-   **z**: initial accumulator value `acc`.
-   **start**: inclusive start key string.
-   **end**: exclusive end key string.
-   **page-size**: maximum entries to process per page (integer).
-   **bookmark**: pagination token (string), `""` for the first page. Set this aside in your `acc`.

**Returns**: `new-acc`:

-   `new-acc`: the accumulator value after processing this page.

**Example**:

```elps
(let* ([result (range-page-bytes collect-keys
                                  '()
                                  "user:"
                                  "user;"
                                  100
                                  "")]
       [next-bmk (get result "bookmark")])
  ;; collect-keys stores the keys and bookmark in a sorted map.
  ;; An empty bookmark means there are no more pages.
  (unless (empty? next-bmk)
    (cc:infof (sorted-map "bookmark" next-bmk) "More pages available")))
```

### 11.2 `statedb:range-page`

```elps
(range-page fn z start end page-size bookmark)
```

-   Same parameters as `range-page-bytes`, except `fn` has signature `(acc curr-key curr-val bookmark)` where `curr-val` is automatically deserialized.

Under the hood, `range-page` calls `deserialize` on each raw value before invoking `fn`.

**Example**:

```elps
(let* ([result (range-page collect-objects
                             '()
                             "order:"
                             "order;"
                             50
                             "")]
       [next-bmk (get result "bookmark")]
       [orders (get result "values")])
  ;; collect-objects stores the values and bookmark in a sorted map
  ;; orders is a list of maps, next-bmk a token for further pages
  ;; Log the count. A whole list makes a long line that nobody can search.
  (cc:infof (sorted-map "count" (length orders)) "Fetched orders"))
```

### 11.3 Page Size Semantics

-   **Page size as a hint**: The `page-size` parameter caps how many keys the Fabric ledger scan will perform per call, but actual returned counts vary:

    -   You may get **more items** than `page-size` if the transaction cache holds extra entries in the same range.
    -   You may get **fewer items** than `page-size` if tombstoned keys occupy slots but are filtered out.
-   **Merged sources**: Each pagination call unifies two data sources:

    1.  **Paginated ledger query** (up to `page-size` keys).
    2.  **Unbounded in-memory cache query**.
-   **Bookmark control**: We pass and manage a `bookmark` (the last processed key) between calls via the iterator function `fn`. To keep the API consistent with the existing non-paginated `range` variants, `range-page`/`range-page-bytes` return only the accumulator (`acc`) instead of a tuple `(acc, bookmark)`. Therefore, the pagination utility does **not** update the bookmark internally; it is the caller’s responsibility to capture the final `bookmark` value within `fn` (for example, storing it in a sorted map or variable) and then supply that bookmark in the next invocation to continue without overlap.

In summary,

-   Capture the last processed key within `fn`.
-   Supply it as the next `bookmark` in the following call.

#### 11.3.1 Technical Details / Algorithm

Under the hood, the platform uses the following algorithm:

1.  **Shim query**: Perform a paginated range query on the ledger from `bookmark` (inclusive) to `endKey`, limited by `pageSize`.
2.  **Cache query**: Perform a full range query on the in-memory transaction cache over the same bounds (no `pageSize` limit).
3.  **Merge & dedupe**: Combine both sorted lists of keys, remove duplicates, and preserve sort order.
4.  **Skip bookmark**: Omit the first key if it equals the input `bookmark`, preventing reprocessing.
5.  **Determine next bookmark**: The **last key** in the merged result becomes the next `bookmark` for subsequent calls.

#### 11.3.2 Design Considerations

-   **No data loss**: By merging and deduping, we include newly written and uncommitted keys and exclude deleted ones.
-   **Consistent progress**: Using the last processed key as the next `bookmark` ensures forward-only paging without overlap.
-   **Performance bound**: While `page-size` bounds ledger scan work, total returned items may vary. Including cached items in the same pass leverages already-loaded data and avoids additional queries.
-   **Simplified implementation**: Merging ledger and cache streams abstracts complexity inside the pagination utility, so your migration logic remains straightforward.
-   **Disabling pagination**: Setting `pageSize ≤ 0` returns all keys in the range at once (both ledger and cache).

*By understanding these semantics, you can reliably implement batch processing loops that adapt to both ledger and cache behaviors, while controlling transaction size and duration.*

## 12\. Appendix

### 12.1 Sample JSON Contexts

```json
{ "bookmark": "", "batch_size": 500 }
```

```json
{ "i": 3 }
```

```json
{ "cursor": "abc123", "step": 2 }
```
