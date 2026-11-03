---
description: Changes a phylum needs before it runs on a newer substrate release, with the error each change fixes.
---

# Upgrading a Phylum

Make these changes to your phylum before you upgrade substrate. Each section
gives the error you see, the fix, the first release that needs the fix, and
whether the fix also works on older releases. Every fix on this page except
two (`cc:bptree-open` and `utils:complement`) also works on older releases.
Deploy those fixes first, then upgrade substrate.

The examples use a phylum package named `my-app`. All names are examples.

## Summary

| Change | Needed from | Fix also works on older releases |
|---|---|---|
| [Read the transaction context only inside a transaction](#read-the-transaction-context-only-inside-a-transaction) | All releases (preheat) | Yes |
| [Declare keyword arguments with `&key`](#declare-keyword-arguments-with-key) | v2.237.0 | Yes |
| [Give each parameter a different name](#give-each-parameter-a-different-name) | v2.237.0 | Yes |
| [Do not use a macro as a `thread-first` or `thread-last` step](#do-not-use-a-macro-as-a-thread-first-or-thread-last-step) | v2.237.0 to v2.245.0 | Yes |
| [Keep the `testing` package out of production files](#keep-the-testing-package-out-of-production-files) | v2.235.0 | Yes |
| [Do not rebind core package symbols](#do-not-rebind-core-package-symbols) | v2.245.0 (lint) | Yes |
| [Set the index prefixes with `utils:set-index-prefixes`](#set-the-index-prefixes-with-utilsset-index-prefixes) | v2.245.0 (guard) | Yes, with a fallback |
| [Remove `cc:sleep` from production files](#remove-ccsleep-from-production-files) | v2.245.0 | Yes |
| [Read `cc:storage-metrics` as a map](#read-ccstorage-metrics-as-a-map) | v2.245.0 | Yes, with a type check |
| [Call `cc:bptree-open` with keywords](#call-ccbptree-open-with-keywords) | v2.245.0 | No |
| [Replace `utils:flip`](#replace-utilsflip) | v2.245.0 | Yes, with a lambda |

"Needed from" is the first substrate release that fails, warns or refuses
the old form.

## Pre-upgrade checklist

Run these four checks with the `luthersystems/shirotester` image of the
release you upgrade to. Run them from the phylum directory (the directory
that holds `main.lisp`). Use v2.245.0 or later: earlier images do not have
every check, and `lint .` on an earlier image can report false
`undefined-symbol` errors.

```bash
ST="docker run --rm -v $PWD:/phylum -w /phylum luthersystems/shirotester:v2.247.0"

$ST fmt -l ./...
$ST lint --exclude '*_test.lisp' --exclude '*_testhelpers.lisp' .
$ST preheat-check .
$ST unit-tests .
```

| Check | Passes when |
|---|---|
| `fmt -l ./...` | It prints no file names and exits 0. Run `fmt -w ./...` to format the files. |
| `lint ...` | It exits 0. Errors fail the check. Warnings and info diagnostics do not. |
| `preheat-check .` | It prints `PASS` and exits 0, with no `WARNING:` lines. |
| `unit-tests .` | Every test passes. |

Also run `preheat-check` and `unit-tests` with
`SUBSTRATE_FORBID_CORE_REBIND=true` set in the container
(`docker run -e SUBSTRATE_FORBID_CORE_REBIND=true ...`). A later release
turns this guard on by default.

Run the checks in CI on each change to the phylum.

### Escape hatches

Some changes have an environment variable that restores the old behaviour.
Use a hatch only for a short time, while you deploy the fix. Set it to the
exact string `true`, and set it the same on every peer of the channel. Peers
that disagree can disagree about transaction results.

| Variable | Restores | From |
|---|---|---|
| `SUBSTRATE_ALLOW_LEGACY_KEYWORD_FORMALS=true` | Keyword formal names | v2.239.0 |
| `SUBSTRATE_ALLOW_PHYLUM_TESTING_PACKAGE=true` | The `testing` package in production | v2.235.0 |

The other changes on this page have no hatch.

## Read the transaction context only inside a transaction

**Symptom.** `preheat-check` fails:

```
FAIL: . reads the transaction context at load scope: cc:now (main.lisp:5:58)
```

`lint` reports `context-dependent builtin cc:now called at phylum load scope
(load-scope-context)` as a warning. In production the first transaction on
a peer is slow, because substrate cannot load the phylum in the background.

**Cause.** A top-level form reads the transaction context while the phylum
loads. The clock (`cc:now`), ledger reads (`statedb:*`, `sidedb:*`), the
creator, the random number generator and structured logging all read the
context. The value is also stale: it is computed once, at load time.

**Fix.** Read the value in an endpoint, in a function that an endpoint calls,
or in a transaction pre-hook.

Before:

```lisp
(set 'order-date (timestamp-to-date (cc:timestamp (cc:now))))
```

After:

```lisp
(set 'order-date ())
(add-tx-pre-hook
  (lambda ()
    (set! 'order-date (timestamp-to-date (cc:timestamp (cc:now))))))
```

If a pre-hook already sets the value, delete the top-level line. You can
also call `(utils:date-now)` where you need the date.

| Needed from | Works on older releases |
|---|---|
| All releases | Yes |

## Declare keyword arguments with `&key`

**Symptom.** The phylum does not load:

```
lisp:defun: function formal argument list contains a keyword: :price
```

**Cause.** A function uses a keyword as a parameter name. Older releases
bound such a name by position. Releases from v2.237.0 refuse it.

**Fix.** Declare the keyword arguments with `&key`. Callers do not change.

Before:

```lisp
(defun order-total (:price price :quantity quantity)
  (* price quantity))
```

After:

```lisp
(defun order-total (&key price quantity)
  (* price quantity))

(order-total :price 2 :quantity 3) ; => 6
```

With `&key`, a caller can give the keywords in any order.

| Needed from | Works on older releases | Hatch |
|---|---|---|
| v2.237.0 | Yes | `SUBSTRATE_ALLOW_LEGACY_KEYWORD_FORMALS=true` (v2.239.0 and later) |

## Give each parameter a different name

**Symptom.** The phylum does not load, or a call fails when a macro builds
the function:

```
lisp:defun: duplicate formal argument name: width
```

**Cause.** A parameter list names the same parameter twice. This includes
lists that your own macros build from their arguments. Releases from v2.237.0
refuse it.

**Fix.** Delete the duplicate name, or rename it.

Before:

```lisp
(defun widget-area (width height width)
  (* width height))
```

After:

```lisp
(defun widget-area (width height)
  (* width height))
```

| Needed from | Works on older releases |
|---|---|
| v2.237.0 | Yes |

## Do not use a macro as a `thread-first` or `thread-last` step

**Symptom.** A call fails at run time:

```
lisp:thread-first: thread step is not a regular function: #<builtin>
```

**Cause.** A step of `thread-first` or `thread-last` is a macro or a special
operator. Releases v2.237.0 to v2.245.0 refuse such a step. From v2.240.0,
`default` is a special operator, so a `(default ...)` step fails too.
Releases from v2.246.0 accept these steps again.

**Fix.** Write the calls nested.

Before:

```lisp
(defun widget-color (widget)
  (thread-first widget
                (get "color")
                (default "gray")
                (string:uppercase)))
```

After:

```lisp
(defun widget-color (widget)
  (string:uppercase (default (get widget "color") "gray")))
```

| Fails on | Works on older and newer releases |
|---|---|
| v2.237.0 to v2.245.0 (`default`: v2.240.0 to v2.245.0) | Yes |

## Keep the `testing` package out of production files

**Symptom.** The phylum does not load:

```
lisp:use-package: unknown package: testing
```

`lint` reports a test function such as `assert-equal` in a production file
as `undefined symbol: assert-equal (undefined-symbol)`.

**Cause.** Production environments do not have the `testing` package from
v2.235.0. A production file (any file that `main.lisp` loads) must not use it
at load scope: no top-level `(use-package 'testing)`, no top-level `test`
form, and no top-level `testing:` call.

**Fix.** Move tests and test helpers out of the production files.

| What | Where it goes |
|---|---|
| Tests | A `*_test.lisp` file |
| Helpers that several test files use | A `*_testhelpers.lisp` file in the same directory (v2.242.0 and later) |

Before, in `orders.lisp`:

```lisp
(use-package 'testing)

(defun check-total (got)
  (assert-equal 6 got))
```

After, in `orders_testhelpers.lisp`:

```lisp
(in-package 'my-app)
(use-package 'testing)

(defun check-total (got)
  (assert-equal 6 got))
```

The test harness loads each `*_testhelpers.lisp` file before the test files.
On a release before v2.242.0, put the helper in the `*_test.lisp` file that
uses it.

| Needed from | Works on older releases | Hatch |
|---|---|---|
| v2.235.0 | Yes | `SUBSTRATE_ALLOW_PHYLUM_TESTING_PACKAGE=true` |

## Do not rebind core package symbols

**Symptom.** `lint` reports a `core-rebind` error, for example:

```
(set now-date ...) rebinds now-date, which use-package imported from substrate core package utils: it binds package my-app's copy only, and utils and Go-native code still see utils:now-date; use a name utils does not export (core-rebind)
(set statedb:get ...) rebinds statedb:get in substrate core package statedb, which Go-native ports of shirocore may not see; ... (core-rebind)
```

`preheat-check` prints a `WARNING:` line for each core symbol that the load
rebinds. With `SUBSTRATE_FORBID_CORE_REBIND=true`, the phylum does not load.

**Cause.** The phylum sets a symbol that a core package defines (`router`,
`utils`, `statedb`, `sidedb`, `cc` and the others). Substrate moves core
functions to Go, and the Go code does not see a phylum's rebinding. A
phylum that depends on a rebinding changes behaviour when that function
moves.

**Fix.** Use the fix for the case you have.

| Case | Fix |
|---|---|
| The phylum sets a name that `utils` exports, such as `now` or `now-date`, after `(use-package 'utils)` | Rename the phylum's variable and every use of it. Declare the new name once at load scope. |
| A debugging helper replaces a core function, such as `statedb:get` | Delete the helper, or move it to a `*_test.lisp` file. |
| The phylum sets the index prefixes | See the next section. |
| The phylum sets another core global | Ask for a supported setter in a [substrate issue](https://github.com/luthersystems/substrate/issues). |

Before:

```lisp
(use-package 'utils)

(add-tx-pre-hook
  (lambda ()
    (set 'now-date (timestamp-to-date (cc:timestamp (cc:now))))))

(defun debug-reads ()
  (set 'statedb:get (lambda (key) ...)))
```

After:

```lisp
(use-package 'utils)

(set 'order-date ())
(add-tx-pre-hook
  (lambda ()
    (set! 'order-date (timestamp-to-date (cc:timestamp (cc:now))))))
```

| Needed from | Works on older releases |
|---|---|
| v2.245.0 (`core-rebind` lint and the opt-in guard) | Yes |

## Set the index prefixes with `utils:set-index-prefixes`

**Symptom.** `lint` reports a `core-rebind` error for each prefix:

```
(set index-bimap-prefix ...) inside (in-package 'utils) binds utils:index-bimap-prefix in substrate core package utils, which Go-native ports of shirocore may not see; use (utils:set-index-prefixes :bimap prefix) instead (core-rebind)
```

With `SUBSTRATE_FORBID_CORE_REBIND=true`, the phylum does not load.

**Cause.** The phylum sets the `utils` index prefixes directly. From v2.245.0,
`utils:set-index-prefixes` sets them with the keyword arguments `:bimap`,
`:counter` and `:page`. It stores the same keys and values.

**Fix.** Call `utils:set-index-prefixes` from the phylum's own package. Keep
the same prefix values, so that the phylum reads the data it already
stored. Put the call at the same place in the load order as the old `set`
forms. Do not add or move a `(use-package 'utils)`.

Releases before v2.245.0 do not have the keyword form, so the call raises
there. To deploy one phylum to both old and new releases, wrap the call in
`handler-bind`. The handler sets the prefixes directly, as before.

Before:

```lisp
(in-package 'utils)
(set 'index-bimap-prefix "shop:bimap")
(set 'index-counter-prefix "shop:ctr")
(set 'index-page-prefix "shop:page")
(in-package 'my-app)
```

After, for a phylum that also runs on releases before v2.245.0:

```lisp
(handler-bind ([condition (lambda (&rest _)
                            ;; Delete this fallback after every peer runs v2.245.0 or later.
                            (set 'utils:index-bimap-prefix "shop:bimap")   ; nolint:core-rebind
                            (set 'utils:index-counter-prefix "shop:ctr")   ; nolint:core-rebind
                            (set 'utils:index-page-prefix "shop:page"))])  ; nolint:core-rebind
  (utils:set-index-prefixes :bimap "shop:bimap" :counter "shop:ctr" :page "shop:page"))
```

After, when every peer runs v2.245.0 or later:

```lisp
(utils:set-index-prefixes :bimap "shop:bimap" :counter "shop:ctr" :page "shop:page")
```

With the fallback, `lint` can report `unused-nolint` or
`frozen-package-write` diagnostics on the fallback lines. They are warnings
and info only, so `lint` still exits 0.

Each prefix must be a non-empty string. If the phylum sets only some
prefixes, pass only those keywords. A keyword that you leave out keeps its
value.

| Needed from | Works on older releases |
|---|---|
| v2.245.0 (the guard and the keyword form) | Yes, with the `handler-bind` fallback |

## Remove `cc:sleep` from production files

**Symptom.** `lint` reports an error:

```
cc:sleep is test-only; not available in production: ... (test-only-symbol)
```

At run time a call fails with an unbound symbol. At load scope the phylum
does not load.

**Cause.** From v2.245.0, `cc:sleep` exists only in test environments. A
wall-clock wait lets peers with different timeouts disagree about a
transaction.

**Fix.** Delete the call, or move it to a `*_test.lisp` file.

| Needed from | Works on older releases |
|---|---|
| v2.245.0 | Yes |

## Read `cc:storage-metrics` as a map

**Symptom.** A call fails at run time:

```
lisp:nth: first argument is not a proper sequence: sorted-map
```

**Cause.** From v2.245.0, `cc:storage-metrics` returns a sorted map from
counter name to integer. Older releases return a list of 11 numbers. Lint
cannot find this change for you.

**Fix.** Read each counter with `get`. Search the phylum for
`cc:storage-metrics` and change every list operation on its result (`nth`,
`first`, `rest`, `map`, ...). `cc:log-metrics` needs no change.

Before:

```lisp
(defun put-count ()
  (nth (cc:storage-metrics) 1))
```

After, for v2.245.0 and later:

```lisp
(defun put-count ()
  (get (cc:storage-metrics) "storage::put"))
```

After, for a phylum that also runs on older releases:

```lisp
(defun put-count ()
  (let ([metrics (cc:storage-metrics)])
    (if (sorted-map? metrics)
      (get metrics "storage::put")
      (nth metrics 1))))
```

The list order on older releases is get, put, get-private, put-private,
range-private, range, get-bytes, put-bytes, get-private-bytes,
put-private-bytes, range-pagination. Each map key is the name with a
`storage::` prefix, for example `"storage::get-bytes"`.

| Needed from | Works on older releases |
|---|---|
| v2.245.0 | Yes, with the `sorted-map?` check |

## Call `cc:bptree-open` with keywords

**Symptom.** A call fails at run time:

```
cc-bptree:bptree-open: function called with an odd number of keyword arguments
```

`lint` reports the positional call as a `removed-router-symbol` warning.

**Cause.** From v2.245.0, `cc:bptree-open` takes keyword arguments. Only
`:prefix` is required. The defaults are `:collection ""`, `:compare ()`,
`:hdk 50`, `:hdv 10`, `:autoflush false` and `:withcount false`.

**Fix.** Use keywords. Keep the `hdk`, `hdv`, `compare` and `withcount`
values that the tree was created with. Pass the compare function itself, not
its quoted name.

Before:

```lisp
(cc:bptree-open "" "widget" () 50 10 true false)
```

After:

```lisp
(cc:bptree-open :prefix "widget" :autoflush true)
```

Open a tree inside a transaction, never at load scope.

| Needed from | Works on older releases |
|---|---|
| v2.245.0 | No. Deploy this change together with the upgrade. |

## Replace `utils:flip`

**Symptom.** A call fails at run time:

```
lisp:flip: argument is not a function of two arguments: (x)
```

**Cause.** From v2.245.0, `utils:flip` is renamed `utils:complement`. An
unqualified `flip` can now resolve to the core `lisp:flip`, which swaps the
two arguments of a function.

**Fix.** On v2.245.0 and later, use `complement`. For a phylum that also
runs on older releases, write the lambda.

Before:

```lisp
(select 'list (flip widget-sold?) widgets)
```

After, for v2.245.0 and later:

```lisp
(select 'list (complement widget-sold?) widgets)
```

After, for all releases:

```lisp
(select 'list (lambda (w) (not (widget-sold? w))) widgets)
```

| Needed from | Works on older releases |
|---|---|
| v2.245.0 | Yes, with the lambda |

## Other changes to check

These changes need no code change in most phyla. Check them if your phylum
uses the feature.

| Release | Change | What to check |
|---|---|---|
| v2.240.0 | Shiroclient never commits a failure response. The writes of an endpoint that returns `route-failure` are discarded. | Endpoints that write and then return a failure. `lint` reports them as `write-then-failure`. |
| v2.245.0 | `main.lisp` loads in package `user`. | Start `main.lisp` with `(in-package 'my-app)` and `(use-package 'router)`. |
| v2.245.0 | Handlebars templates use a new engine with limits. | Template output in edge cases. Use `(handlebars:render tpl ctx :strict true)` for strict mode. |
| v2.245.0 | `utils:memoize-wrap` keys calls by value and type. `1` and `1.0` are different keys. | Memoized functions called with numbers of mixed types. `SUBSTRATE_LEGACY_MEMO_KEYS=true` restores the old key for a short time. |
