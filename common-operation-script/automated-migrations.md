# Automated Migrations with Context

## 1. Introduction

**Version Requirements**
Substrate and Shiroclient CLI must be at least version `v2.205.8`.

In production environments, large data migrations can quickly exceed transaction size limits, hit execution timeouts, and become cumbersome to manage. Historically, users had to comment and uncomment individual migration blocks, deploy each batch manually, and rerun initialization for every segment. This context-based migration feature automates batching, tracks progress via a serialized context map, and orchestrates repeated transactions until completion, ensuring safe, efficient, and resumable migrations.

## 2. Prerequisites

- **Substrate Runtime**: Version `v2.205.8` or later with context-based migration utilities.
- **Shiroclient CLI**: Version `v2.205.8` or later for `init` command enhancements.
- **Phylum Code**: Your application business logic written in ELPS.
- **Testing Framework**: Version `v2.205.8` or later of `shirotester`, available in your local development environment.

## 3. Overview of Context-Based Migrations

Context-based migrations allow large data migrations to be split into multiple, safe transactions. Each migration step:

1. Receives a context map from the previous step (or empty for the first run).
2. Processes a batch of data.
3. Returns a new context to continue, or empty to finish.
4. Is idempotent for each unique context.

The CLI automatically loops until no further context is returned, up to a configured iteration limit.

## 4. Substrate Runtime Utilities

The following utilities are provided in the `utils.lisp` runtime package:

### 4.1 `ctx-migrations` Vector

A registry that holds all registered context migration functions.

### 4.2 `register-migration-ctx`

Macro to register a migration by ID and function body.

### 4.3 `def-migration-ctx`

Convenience macro that wraps `register-migration-ctx` and tracks execution history in state.

### 4.4 `run-ctx-migrations`

Function that executes all registered migrations in order, passing and collecting context maps.

## 5. Phylum Endpoint: `run_ctx_migrations`

This feature adds a new internal endpoint to the platform that is called by shiroclient automatically:

```elps
(defendpointnames "run_ctx_migrations" '("ctx") (ctx)
  (route-success (utils:run-ctx-migrations ctx)))
```

This endpoint is called by the CLI in a loop, passing the context map and returning the next context.

## 6. CLI Integration: the `init` Command

The `shiroclient init` command has been enhanced to support context-based migrations:

- **`--iterations` / `-l`**: Maximum number of migration iterations (default: 0). The CLI will call `run_ctx_migrations` up to this many times or stop early if an empty context is returned.
- **`--initial-ctx` / `-m`**: JSON string to seed the first migration context. Defaults to an empty map `{}` if omitted.
  Provide a JSON object whose keys are your migration IDs (the strings you passed to `def-migration-ctx`) and whose values are the per-migration context maps. Any migration not mentioned will start with an empty context. You also can use this to resume a migration that may have failed part way through execution.

  - **Format**:

    ```json
    {
      "<migration-id-1>": {
        /* context for first migration */
      },
      "<migration-id-2>": {
        /* context for second migration */
      }
      // …and so on
    }
    ```

- **Example**: if you have two context-based migrations registered as
  `def-migration-ctx "RD-451-update-property-location" …` and
  `def-migration-ctx "RD-12-normalize-user-emails" …`, you might write:

  ```bash
  shiroclient init \
    -l 10 \
    -m '{
          "RD-451-update-property-location": { "bookmark": "", "batch_size": 500 },
          "RD-12-normalize-user-emails": { "last_id": "user_123" }
        }' \
  ...
  ```

  This tells the CLI to seed each named migration with its initial sub-context.

- **Defaults**:

  - If you omit `--initial-ctx`, the CLI uses an empty map: all migrations begin at their default starting point.
  - If you include only some migration IDs, the others still run but start from an empty context.

- **Execution Loop & Dependent Block Handling**:
  Shiroclient executes the following steps for the `init` command:

  1. Deploy the phylum via the `init` endpoint.
  2. Reinitialize the CLI client and sleep briefly for propagation.
  3. Loop up to `--iterations`, invoking `run_ctx_migrations` with the last context and dependent block number.
  4. Exit early if the migration returns an empty context or an error occurs.

## 7. Writing Migrations in Your Phylum

### 7.1 Syntax of `def-migration-ctx`

Define a context-aware migration with an ID and a single parameter (the context map):

```elps
(def-migration-ctx "your-migration-id" (ctx)
  ;; migration body, returning next context or empty map when complete
)
```

_NOTE_: you can specify multiple `def-migration-ctx`, all of which are executed within each iteration of the migration loop.

### 7.2 Context Parameter & Return Semantics

- Developers decide what to store in `ctx`—it must be serializable to JSON and contain all information required for the next transaction to continue where the last one left off.
- Return a **non-empty** map to continue migration; return an **empty** map (e.g. `(sorted-map)`) to signal completion.
- **IMPORTANT**: Each unique context is tracked in state; re-running with the same context is a no-op. Therefore, be mindful to include an incrementing counter, or some other field that changes across steps.

### 7.3 JSON Serialization Requirements

- All keys and values in the context map must be serializable via `json:dump-bytes`.
- Complex values should be converted to strings or basic types before returning.

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

## 8. Testing with `shirotester`

### 8.1 Unit Tests in `utils_test.lisp`

- **`register-migration-ctx`**: assert that the migration is added to `ctx-migrations` and returns `nil` for the first run.
- **`def-migration-ctx`**: define a migration that returns a value, verify `run-ctx-migrations` returns the expected map, and that rerunning yields no output.

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

## 9. Best Practices & Caveats

### 9.1 Pagination via `statedb:range-page`

- Instead of scanning all keys, `statedb:range-page` retrieves up to `page-size` keys and returns a `bookmark` for continuation. This drastically reduces the total number of keys scanned in the ledger, shrinks the read/write set, and keeps transaction payloads small (avoiding size and timeouts).
- Tombstoned keys still occupy pagination space, which may result in more or fewer results than the specified `page-size` (see semantics section below), but no data is skipped across batches.

### 9.2 Handling Partial Batches & Tombstones

- Design your migration logic to handle smaller and greater-than-expected batches gracefully.
- If strict batch sizes are required, loop internally and resize the result sets until the desired count is processed.

### 9.3 Safety Guards with `maxMigrations`

- The CLI’s `--iterations` (`-l`) flag prevents infinite loops by capping the number of `run_ctx_migrations` calls in a single invocation.
- Set this flag to the maximum number of batches you expect for your migration; avoid setting it significantly higher than necessary. If a migration returns an empty context early, the loop exits regardless of the cap.
- By default, `--iterations` is `0`, and no context-based migrations run unless you specify a positive number.

## 10. FAQ

**Q: Is each migration executed as a single transaction?**
Each context migration step runs in its own transaction. Large data sets are processed in batches to stay within size and time limits.

**Q: Are migrations paginated?**
Yes. Under the hood, migrations should use `statedb:range-page` (or a custom paging loop) to fetch a subset of keys and a bookmark for the next batch.

**Q: Do we pass full migration logic for each step?**
Yes. Every step includes the complete migration function body; only the context map changes between invocations.

**Q: Why do we need to set `--iterations`?**
As a safety guard, `--iterations` caps the number of automated steps to prevent infinite loops due to logic errors. The loop still exits early if the migration returns an empty context.

**Q: What do the new features automate?**
Previously, developers managed batching and transaction control manually. With `def-migration-ctx` and CLI looping. Now migrations run across multiple transactions automatically—no manual intervention needed.

**Q: Why can’t we run the entire migration in one transaction?**
Transactions have limits on size, key count, and execution time. Splitting into batches ensures reliable commits without hitting gRPC or ledger constraints.

## 11. Pagination `range-page` / `range-page-bytes`

### 11.1 `statedb:range-page-bytes`

Similar to `range` and `range-bytes`, but with pagination.

```elps
(range-page-bytes fn z start end page-size bookmark)
```

Best used to minimize ledger reads and transaction payloads.

- **fn** (function): signature `(acc curr-key curr-val bookmark) -> new-acc`, where `curr-val` is raw bytes.
- **z**: initial accumulator value `acc`.
- **start**: inclusive start key string.
- **end**: exclusive end key string.
- **page-size**: maximum entries to process per page (integer).
- **bookmark**: pagination token (string), `""` for the first page. Set this aside in your `acc`.

**Returns**: `new-acc`:

- `new-acc`: the accumulator value after processing this page.

**Example**:

```elps
(let* ([result (range-page-bytes collect-keys
                                  '()
                                  "user:"
                                  "user;"
                                  100
                                  "")]
       [next-bmk (get result "bookmark")])
  ;; collect-keys stores the keys and bookmark in a sorted map
  (when next-bmk
    (cc:infof "More pages available with bookmark: {}" next-bmk)))
```

### 11.2 `statedb:range-page`

```elps
(range-page fn z start end page-size bookmark)
```

- Same parameters as `range-page-bytes`, except `fn` has signature `(acc curr-key curr-val bookmark)` where `curr-val` is automatically deserialized.

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
  (cc:infof "Fetched orders: {}" orders))
```

### 11.3 Page Size Semantics

- **Page size as a hint**: The `page-size` parameter caps how many keys the Fabric ledger scan will perform per call, but actual returned counts vary:

  - You may get **more items** than `page-size` if the transaction cache holds extra entries in the same range.
  - You may get **fewer items** than `page-size` if tombstoned keys occupy slots but are filtered out.

- **Merged sources**: Each pagination call unifies two data sources:

  1. **Paginated ledger query** (up to `page-size` keys).
  2. **Unbounded in-memory cache query**.

- **Bookmark control**: We pass and manage a `bookmark` (the last processed key) between calls via the iterator function `fn`. To keep the API consistent with the existing non-paginated `range` variants, `range-page`/`range-page-bytes` return only the accumulator (`acc`) instead of a tuple `(acc, bookmark)`. Therefore, the pagination utility does **not** update the bookmark internally; it is the caller’s responsibility to capture the final `bookmark` value within `fn` (for example, storing it in a sorted map or variable) and then supply that bookmark in the next invocation to continue without overlap.

In summary,

- Capture the last processed key within `fn`.
- Supply it as the next `bookmark` in the following call.

#### 11.3.1 Technical Details / Algorithm

Under the hood, the platform uses the following algorithm:

1. **Shim query**: Perform a paginated range query on the ledger from `bookmark` (inclusive) to `endKey`, limited by `pageSize`.
2. **Cache query**: Perform a full range query on the in-memory transaction cache over the same bounds (no `pageSize` limit).
3. **Merge & dedupe**: Combine both sorted lists of keys, remove duplicates, and preserve sort order.
4. **Skip bookmark**: Omit the first key if it equals the input `bookmark`, preventing reprocessing.
5. **Determine next bookmark**: The **last key** in the merged result becomes the next `bookmark` for subsequent calls.

#### 11.3.2 Design Considerations

- **No data loss**: By merging and deduping, we include newly written and uncommitted keys and exclude deleted ones.
- **Consistent progress**: Using the last processed key as the next `bookmark` ensures forward-only paging without overlap.
- **Performance bound**: While `page-size` bounds ledger scan work, total returned items may vary. Including cached items in the same pass leverages already-loaded data and avoids additional queries.
- **Simplified implementation**: Merging ledger and cache streams abstracts complexity inside the pagination utility, so your migration logic remains straightforward.
- **Disabling pagination**: Setting `pageSize ≤ 0` returns all keys in the range at once (both ledger and cache).

_By understanding these semantics, you can reliably implement batch processing loops that adapt to both ledger and cache behaviors, while controlling transaction size and duration._

## 12. Appendix

### 12.1 Sample JSON Contexts

```json
{ "bookmark": "", "batch_size": 500 }
{ "i": 3 }
{ "cursor": "abc123", "step": 2 }
```
