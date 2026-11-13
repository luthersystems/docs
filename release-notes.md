---
description: Versioned releases of platform artifacts and their changes.
---

# Release Notes

<div class="docs-banner">
<p><strong>Security notice (2026-10-22):</strong> the eMudhra (emSign) CA
compromise (CVE-2026-111943) affects the trust stores of container images and
Go programs. See <a href="security-notice-emsign.md">Security Notice:
eMudhra (emSign) CA Distrust</a> for the versions to use.</p>
<p><strong>Known issue:</strong> on substrate v2.237.0 to v2.245.0, a
<code>thread-first</code> or <code>thread-last</code> step fails when its head
is a macro. Upgrade to v2.246.0. See <a href="known-issues.md">Known
Issues</a>.</p>
<p><strong>Known issue:</strong> on Luther Auth v4.12.0 with refresh tokens on
and a Redis user limited to <code>f_*</code> keys, every refresh fails with
<code>500</code>. Use v4.13.0. See <a href="known-issues.md">Known
Issues</a>.</p>
</div>

Operator settings applied to the chaincode container are catalogued in
[Chaincode Environment Variables](common-operation-script/substrate/chaincode-environment-variables.md).

## 2026-11-13: substrate v2.259.0

- **substrate**: **Upgrade note:** some transactions take fewer ELPS steps. If you set a step limit (`SUBSTRATE_ELPS_MAX_STEPS`), upgrade every peer and pre-deploy checker of a channel together. See the [upgrade notes](https://github.com/luthersystems/substrate/blob/v2.259.0/docs/substrate-api.md)
- **substrate**: Substrate runs on Fabric 3.1 peers. On a 3.1 peer the chaincode sends a transaction's writes to the peer in one batch. Set `CHAINCODE_WRITE_BATCH=false` to turn this off. A Fabric 2.5 peer does not change. **Upgrade note:** set the variable the same on every peer of a channel. During a rolling upgrade from 2.5 to 3.1, set it to `false` if your phylum catches the error of a failed put
- **substrate**: The gateway does not retry a write batch that the peer refused. A transport failure is still retried
- **substrate**: New `statedb:get-many`, `statedb:get-many-bytes`, `sidedb:get-many` and `sidedb:get-many-bytes` read a list of keys in one call. They return what `(map 'list statedb:get keys)` returns. On a Fabric 3.1 peer the keys are read in one batched call: 100 keys take 16 ms, not 43 ms. A refused key fails the whole call before any key is read
- **substrate**: A data migration defined with `def-migration-ctx` takes fewer ELPS steps
- **substrate**: The in-process mock of the Go SDK takes the cc-fetchurl proxy and downgrade options. It refuses a request whose fetchurl settings are different from the mock's
- **substrate**: Bundles elps v1.98.0. A path read checks only the containers on its path, so its cost follows the path, not the document size
- **Tooling**: In the VS Code extension, hover and completion know the new `get-many` functions. The language server no longer reports a function that a phylum defines with its own macro as undefined. The extension is published with Marketplace Trusted Publishing; nothing changes for users

Details: [substrate v2.259.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.259.0).

## 2026-11-13: elps v1.98.0

- **Language**: An `elpspath` read (`?`) with a path checks only the containers that path steps into. A fault elsewhere in the document does not change its answer, and its cost follows the path, not the document size. Writes, and a read with no path, still check the whole document
- **Language**: `elpspath` refuses a malformed array or map header with an error. Before, it could panic
- **Language**: `macroexpand-all` takes `:lower true`, and the new `macroexpand-all-lowered` is the same call with one argument. Each expands `get-default` as the macro it replaced expanded it, for tools that model that macro
- **Tooling**: The VS Code extension is published with Marketplace Trusted Publishing, and its `minimatch` dependency is 11.0.1 or later, except where `vscode-languageclient` needs version 10

Details: [elps v1.98.0 release](https://github.com/luthersystems/elps/releases/tag/v1.98.0).

## 2026-11-12: elps v1.97.0

- **Language**: `get-default` is a special operator, not a macro. Calls give the same results, and the map and key are each evaluated once. A call costs fewer steps
- **Language**: `to-float` accepts only decimal text, such as `"-12.75"`, `".5"` or `"1e5"`. The strings `"nan"`, `"inf"` and `"infinity"`, hexadecimal floats, digits with `_` and text with spaces are now errors, as is a number too large for a float
- **Language**: `time:time-from` returns an error for two times more than about 292 years apart. Before, it returned about 292 years with no error
- **Language**: The reader refuses a sign joined to a `#x` or `#o` literal, such as `-#x10`. Before, it read the symbol `-` and then the number 16
- **Language**: `?set!`, `?nil!` and `?del!` with a path that ends in `'*` write each element of a vector
- **Language**: `regexp:regexp-match?` charges steps by the size of the text and of the pattern
- **JSON**: The JSON functions give the same output and the same error text on both of Go 1.27's JSON engines, also for native Go values. A strict load refuses non-canonical integer text past the 64-bit range
- **Tooling**: The language server, `elps lint` and `elps mcp` expand macros defined in the workspace, so a function that a macro in another file defines is found, not reported as undefined. References, hover, definition and rename work on files the editor has not opened. A file with no problems now clears its old diagnostics
- **Tooling**: `elps fmt -d` prints a unified diff, and `elps fmt` keeps LF line endings for a file with CRLF endings
- **Performance**: Fewer allocations for function calls, integers, sorted-map copies and the JSON functions
- **Security**: built with Go 1.27.4, which fixes GO-2026-6859

Details: [elps v1.97.0 release](https://github.com/luthersystems/elps/releases/tag/v1.97.0).

## 2026-11-12: substrate v2.258.0

- **substrate**: **Upgrade note:** this release is consensus-visible. It has no setting that turns the changes off. Upgrade every peer and pre-deploy checker of a channel in one maintenance window. The upgrade notes in [substrate-api.md](https://github.com/luthersystems/substrate/blob/v2.258.0/docs/substrate-api.md) give the read sets, write sets and step counts of each change
- **substrate**: Security: `cc:valid-json?` no longer loads a document that a schema `$ref` names. Before, each peer read an `http://`, `https://` or `file://` reference itself, with no timeout, so two peers could give different results. Now a `$ref` to another document is an error. A `$ref` to the schema's own text works as before
- **substrate**: Security: decimal calls have bounds. `decimal-string` with `:places` and `decimal-round` take places from -1000 to 1000, and `decimal-pow` refuses a result too large to compute. Before, one call could run until the transaction timed out. Now each such call raises an ordinary error before the work starts
- **substrate**: The batch package keeps one state key per queued item. Schedules of one queue no longer conflict in a block. A batch holds at most 100 items, and an item with no request record no longer blocks the queue. **Upgrade note:** queues of an earlier release are not migrated. If your phylum uses the batch package, empty its queues before you upgrade: pause the schedules and let the batch processor collect and answer every batch
- **substrate**: B+-tree fixes. A query or a delete of a tree that does not exist no longer creates the tree, and writes nothing. A delete that shrinks the root removes the old root from state. After `cc:bptree-delete-tree`, the handle works again. A node is searched with a binary search. Step counts change, see the upgrade notes
- **substrate**: `utils:storage-pcounter` and `utils:storage-pcounter-vec` without `:prand` pick the shard from the transaction ID, not from the clock. Before, all transactions in one second wrote the same shard, and all but one failed validation
- **substrate**: `validations:validate-address` checks the whole GB postcode. Before, a postcode with text after it, such as `"SW1A 1AA, London"`, passed
- **substrate**: A request for the `latest` phylum version finds a version that was enabled up to 10 years ago. Before, the limit was 5.33 years
- **substrate**: A failed flow migration records its outcome for any error text. Before, an error text with many quotes, newlines or `<` characters could not be recorded
- **substrate**: Less work for each request: the request is decoded once, a B+-tree flush writes only its changed keys, and the state cache iterator uses no goroutine. A large request is up to 47% faster
- **substrate**: Security: built with Go 1.27.4, which fixes GO-2026-6859 (a crash of the HTTP/1 server in `net/http`)
- **shiroclient**: Fixes in the gateway: a deadlock when `Close` runs during a write, and three panics on a failed proposal or a missing block cache. A request body that takes more than 60 seconds to read gets HTTP 408. The Prometheus `method` label holds only known method names
- **shiroclient**: With tracing on, the gateway starts as a user that has no entry in `/etc/passwd`. Before, it stopped with `user: Current requires cgo or $USER set in environment` (svc v0.21.1)
- **shiroclient**: In the plugin mock, `cc-fetchurl` sends an `https` URL as `https`. Before, it sent it as plain `http`. A test on the in-process mock that sends `https` through a plain-`http` proxy must add `shiroclient.WithCCFetchURLDowngrade(true)`
- **shirotester**: `shirotester package` needs Go 1.27 or later for a WebAssembly module. A deployed `.wasm` file still loads and runs

Details: [substrate v2.258.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.258.0).

## 2026-11-11: svc v0.21.1

- **svc**: With tracing on, a service starts when its process owner is not known, for example a container that runs as a user with no entry in `/etc/passwd`. The trace resource then has no `process.owner` and the service logs a warning. Before, `opttrace.New` failed and the service stopped. Other errors in the resource attributes (`OTEL_RESOURCE_ATTRIBUTES`) still stop it
- **svc**: Security: built with Go 1.26.11, which fixes GO-2026-6859

Details: [svc v0.21.1 release](https://github.com/luthersystems/svc/releases/tag/v0.21.1).

## 2026-11-11: fabric-network-builder v0.1.2

- **fabric-network-builder**: Each `CHAINCODE_*`, `SUBSTRATE_*` and `OTEL_*` variable that you give the builder goes to the chaincode containers. For example, `OTEL_BSP_SCHEDULE_DELAY` now reaches the chaincode's tracer. A value that the compose file sets is kept
- **fabric-network-builder**: Security: the network's ports are published on `127.0.0.1` only. Before, they were open on every interface of the host. To publish on another address, set `FNB_PUBLISH_ADDR`. The first `up` after the upgrade recreates the containers

Details: [fabric-network-builder v0.1.2 release](https://github.com/luthersystems/fabric-network-builder/releases/tag/v0.1.2).

## 2026-11-11: buildenv v0.1.59

- **General**: Security: the Go images (`build-api`, `build-go`, `build-go-alpine`, `build-godynamic`) and `build-java`, `build-js` and `build-e2e` ship Go 1.27.4, which fixes GO-2026-6859
- **build-api, build-go**: The Debian openssh-client finding CVE-2026-123158 does not apply: the vulnerable code is in `sshd`, and the images have only the client. The images carry an OpenVEX `not_affected` statement for it
- **General**: All images are rebuilt on the latest base images and OS packages

Details: [buildenv v0.1.59 release](https://github.com/luthersystems/buildenv/releases/tag/v0.1.59).

## 2026-11-06: substrate v2.257.0

- **substrate**: **Upgrade note:** substrate is built with Go 1.27.3. Go 1.27 changes the bytes of zlib output and, for strings with invalid UTF-8, of JSON output. Both are consensus-visible. Upgrade every peer and pre-deploy checker of a channel in one maintenance window. While peers mix Go 1.26 and Go 1.27 builds, a transaction that compresses data fails endorsement: for example a `put-mxf` with the `zlib` compressor, or a response that holds `compress:zlib-compress` output. Reads and other transactions are not affected. Data that a Go 1.26 peer wrote still decodes
- **substrate**: Bump ELPS to v1.96.0: the Lisp JSON functions write the same bytes on Go 1.27's JSON v2 engine as before, invalid UTF-8 included
- **shiroclient**: The gateway health check can make one real write, to show that the network can endorse, order and commit a transaction, not only answer a query. It is off by default. Turn it on with `--health-check-write` or `SHIROCLIENT_GATEWAY_HEALTH_CHECK_WRITE=true`, then call `GET /health_check?write=true`. The write overwrites one key (`luther:healthcheck:heartbeat`), so the state does not grow. The report gets a `write` row with the transaction id and the commit time. A failed write is a `DOWN` row and HTTP 503. Checks that arrive while a write is in flight share it
- **substrate**: Security: only a creator of the channel's admin MSP can run the heartbeat write. The chaincode cannot tell one user from another, so the service in front of the gateway (the oracle) must decide which callers may ask for it. Turn the write on only on a gateway that such a service fronts. The `luther:healthcheck:` key space is reserved: a phylum read or write of it fails

Details: [substrate v2.257.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.257.0).

## 2026-11-05: Luther Auth v4.15.0

- **General**: Fix: with refresh tokens and `AUTH_OAUTH_PROTECT_CSRF` on, the CSRF token cookie now lasts the whole refresh session, and each `POST /v1/auth/refresh` sets it again. Before, it expired after the access token lifetime (30 minutes by default), and every call that a service checked for CSRF failed after that. See [CSRF Protection and Cookie Mode](connectors/lutherauth/csrf.md)
- **General**: Security: a refresh that is in progress when `revoke-user` runs no longer returns a new access token. A rotated refresh token keeps the time of its login, so `revoke-user` refuses every token of a session that started before it
- **General**: Sign-out revokes the refresh token family also when the token lookup fails. **Behavior change:** if the revoke fails two times (for example, Redis is down), sign-out answers `503` and does not redirect. It keeps the refresh, CSRF token and ID token cookies, so the user can sign out again. See [Sign out](connectors/lutherauth/sessions.md#sign-out)
- **General**: Every Redis call of the refresh store has a 5-second timeout. The connection pool holds at most 64 connections. A call that waits for a free connection gives up after the timeout
- **General**: **Behavior change:** a login whose `sub` is empty is refused, because `revoke-user` cannot end it
- **General**: Security: the OAuth callback refuses a nonce cookie of the wrong length with `400`. Before, a short nonce cookie such as `0` gave every such login the same refresh token family and CSRF token
- **General**: Security: logs no longer contain refresh tokens or raw issuer values

Details: [Luther Auth v4.15.0 release](https://github.com/luthersystems/lutherauth/releases/tag/v4.15.0).

## 2026-11-05: fabric-snapshot-archiver v0.0.9

- **fabric-snapshot-archiver**: `serve --snapshot-schedule` takes a snapshot on a cron schedule (UTC), uploads it to S3, and keeps the newest `--keep-archives` archives of the channel (default 14). The IAM role needs `s3:DeleteObject` to delete old archives. Prometheus metrics report the last success, so you can alert when snapshots stop. See [Take snapshots on a schedule](operations/fabric-snapshot-archiver.md#take-snapshots-on-a-schedule)
- **fabric-snapshot-archiver**: `serve --metrics-addr` serves `/metrics` and the health endpoints on a listener of their own, so the API, which has no authentication, can listen on localhost only
- **fabric-snapshot-archiver**: `archive-blocks` moves the sealed block files of the peer ledger to a cheap volume (sc1) and leaves a symlink, so the peer keeps its hot path on a fast volume (gp3). A crash at any step leaves the original file or a complete copy
- **fabric-snapshot-archiver**: `serve` stops cleanly on SIGTERM, so a pod shutdown cancels a running snapshot
- **fabric-snapshot-archiver**: Updates `golang.org/x/net` to v0.62.0

## 2026-11-05: Luther Auth v4.14.0

- **General**: New `AUTH_GENERIC_REQUIRE_ACCESS_TOKEN_ISSUER`, off by default. On, the generic OAuth backend refuses an IdP access token whose issuer is not `AUTH_GENERIC_BACKEND_ISSUER`. Turn it on only if your IdP puts the same issuer in the access token and the ID token. The ID token issuer check does not change

Details: [Luther Auth v4.14.0 release](https://github.com/luthersystems/lutherauth/releases/tag/v4.14.0).

## 2026-11-05: Luther Auth v4.13.1

- **General**: Updates dependencies, including the AWS SDK for Go and `golang.org/x/crypto` v0.58.0. No change in behavior

Details: [Luther Auth v4.13.1 release](https://github.com/luthersystems/lutherauth/releases/tag/v4.13.1).

## 2026-11-04: substrate v2.256.0

- **substrate**: The in-memory mock ledger (`shirotester`, the Go mock client and offline tests) uses less memory and restores snapshots faster. Its memtable drops from 16 MB to 8 MB. An empty mock holds about 10.5 MB, down from about 26 MB. A snapshot restore plus its first call is about 30% faster. Peers do not change
- **substrate**: One size of test transaction commits slower in the mock: one that writes 1.2 MB to 2.4 MB, or about 13k to 26k keys. Such a transaction measured 60% to 83% slower. It still commits. Smaller and larger transactions cost the same as before

Details: [substrate v2.256.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.256.0).

## 2026-11-04: substrate v2.255.0

- **substrate**: Mock ledger snapshots are faster to make and use less memory. A snapshot of a 10k-key ledger now allocates about 7.7 MB, down from about 363 MB. A restore makes 42% fewer allocations. The snapshot format does not change: older snapshots still load, and new ones load on older versions
- **substrate**: The gateway uses less CPU per request. With tracing off, it does less work for each request but still passes the caller's trace context to the chaincode. A read no longer builds the orderer clients. Each change saved about 4% of the gateway's CPU on a read benchmark
- **substrate**: Fix: the gateway no longer panics when it cannot make a transaction header. If the gateway cannot build its orderer clients, the transaction fails and is not reported as possibly sent
- **substrate**: The chaincode metrics listener (`CHAINCODE_PROM_LISTEN_ADDR`) serves the named pprof profiles under `/debug/pprof/`, such as `heap`, `allocs` and `goroutine`. Before, these returned 404, so a memory profile of a running chaincode could not be taken. The CPU profile and trace were already served
- **substrate**: Security: the profiles have no authentication, and they show goroutine stacks and heap contents. Keep the metrics port inside the cluster

Details: [substrate v2.255.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.255.0).

## 2026-11-04: Luther Auth v4.13.0

- **General**: Fix: with refresh tokens on and a Redis user limited to `f_*` keys, every refresh on v4.12.0 failed with `500`. The `revoke-user` record is now under `f_`, and the store runs only GET, SET, PING and its scripts. See [Redis user permissions](connectors/lutherauth/sessions.md#redis-user-permissions)
- **General**: Security: sign-out can also end the IdP's own session, so the next login in the same browser asks for the password again. Set `AUTH_OAUTH_IDP_LOGOUT_URL` (an OIDC `end_session_endpoint`, or Auth0 `/v2/logout`) and, if needed, `AUTH_OAUTH_IDP_LOGOUT_RETURN_PARAM`. Off by default. See [End the IdP session too](connectors/lutherauth/sessions.md#end-the-idp-session-too)
- **General**: New `AUTH_OAUTH_IDP_LOGOUT_ID_TOKEN_HINT` sends the user's ID token as `id_token_hint` to the IdP logout, for an IdP that requires it. The token is kept in an HttpOnly cookie on `AUTH_OAUTH_IDP_LOGOUT_ID_TOKEN_COOKIE_PATH` (default `/v1/auth`)

Details: [Luther Auth v4.13.0 release](https://github.com/luthersystems/lutherauth/releases/tag/v4.13.0).

## 2026-11-04: Luther Auth v4.12.0

**Known issue:** do not deploy this version with refresh tokens on and a Redis user limited to `f_*` keys. Every refresh fails with `500`. Use v4.13.0. See [Known Issues](known-issues.md).

- **General**: New `revoke-user` command, run in the LutherAuth pod, ends every refresh session of a user at once. Use it after you disable a user at the IdP. It needs the Redis refresh store. See [Revoke a user](connectors/lutherauth/sessions.md#revoke-a-user)
- **General**: A minted token (`mint-token`, or a `mint_only` client) lasts at most 90 days by default. Before, the cap was one year. **Upgrade note:** a `mint_only` client with a `ttl` above 90 days stops LutherAuth at startup, and `mint-token` refuses a longer `--ttl`. Set `AUTH_CLIENT_CREDENTIALS_MINT_MAX_TTL` or lower the `ttl` before you upgrade
- **General**: Security: every LutherAuth response now sends `Cache-Control: no-store`, except the JWKS. A CDN that cached the login response gave every user in the cache window the same OAuth state, nonce and PKCE verifier. See [Behind a CDN](connectors/lutherauth/behind-a-cdn.md)
- **General**: A bad login, callback or sign-out request (an expired login, a replayed or cancelled callback, a malformed query, a disallowed sign-out redirect) now gets `400` instead of `500`. The response never carries the IdP's error text
- **General**: Each refresh token has its own `jti`, and a refreshed access token does not carry it. Before, two rotations in the same second could issue the same refresh token

Details: [Luther Auth v4.12.0 release](https://github.com/luthersystems/lutherauth/releases/tag/v4.12.0).

## 2026-11-04: Luther Auth v4.11.0

- **General**: New `AUTH_REFRESH_ALLOW_LEGACY_LOGIN` keeps the legacy login beside refresh tokens, so apps move to refresh tokens one at a time
- **General**: An access token made by a refresh lasts `AUTH_JWT_REFRESH_INTERVAL` (30 minutes by default). A legacy login token keeps `AUTH_JWT_TIMEOUT`

Details: [Luther Auth v4.11.0 release](https://github.com/luthersystems/lutherauth/releases/tag/v4.11.0).

## 2026-11-03: Luther Auth v4.10.0

- **General**: Security: refresh tokens are signed with their own key, which services cannot verify, so a refresh token is never accepted as an access token. Refresh tokens signed the old way still work, so no session ends at the upgrade. **Upgrade note:** keep the rollout to one replica set switch, because an old pod cannot verify a new refresh token, and a rollback to v4.9 signs those users out
- **General**: Security: the Redis refresh store keeps only digests of refresh tokens, rotates a token family in one atomic step, and keeps revocations
- **General**: Sign-out revokes the refresh token family and always deletes the refresh cookie
- **General**: The refresh store can authenticate to AWS ElastiCache with IAM (`AUTH_JWT_REFRESH_REDIS_IAM_CACHE_NAME`), so no Redis password is stored
- **General**: A magic link signs in only once. The Azure backend can pin the token issuer. The generic OAuth backend has an opt-in `email_verified` check

Details: [Luther Auth v4.10.0 release](https://github.com/luthersystems/lutherauth/releases/tag/v4.10.0).

## 2026-11-03: lutherauth-sdk-go v0.0.12

- **lutherauth-sdk-go**: New `jwk.WithIssuerPolicy` sets, in one place, each issuer a service trusts, its JWKS URL and the audiences (and subjects) its tokens must carry. A token from an issuer that is not in the policy is refused before a key is fetched. An empty policy accepts no token, so a pin that failed to load does not turn into no pin. See [Verify Tokens in Go](connectors/lutherauth/verify-tokens.md)

Details: [lutherauth-sdk-go v0.0.12 release](https://github.com/luthersystems/lutherauth-sdk-go/releases/tag/v0.0.12).

## 2026-11-03: lutherauth-sdk-go v0.0.11

- **lutherauth-sdk-go**: Security: a LutherAuth refresh token is always refused as a bearer token
- **lutherauth-sdk-go**: New `jwk.WithExpectedIssuers` refuses a token from any issuer that is not listed

Details: [lutherauth-sdk-go v0.0.11 release](https://github.com/luthersystems/lutherauth-sdk-go/releases/tag/v0.0.11).

## 2026-11-03: Luther Auth v4.9.0

- **General**: New OAuth 2.0 client credentials grant at `/v1/auth/token`, for a service that calls a Luther API with no person behind it. Only a registered client that sends its secret gets a token, and the claims come from the server configuration. Off by default. See [Service Tokens](connectors/lutherauth/service-tokens.md)
- **General**: New `mint-token` command, run in the LutherAuth pod, signs one long-lived token for a registered client. The signing key does not leave the cluster. It replaces the fake IdP for long-lived service tokens
- **General**: Magic link emails are rate limited for each client IP and each email address. A request over a limit gets `429 Too Many Requests`. **Upgrade note:** behind a load balancer or a CDN, set `AUTH_MAGIC_LINK_TRUSTED_PROXY_HOPS`. See [Upgrade LutherAuth](connectors/lutherauth/upgrade-v4-9-0.md)

## 2026-11-02: substrate v2.254.0

- **substrate**: New `connector:mk-sql-req` builds a SQL request for the Oracle, Oracle read-only, MySQL and SAP HANA connectors, with each value bound to a placeholder, so a phylum never formats a value into SQL text. A value is a string, an int, a float or nil for `NULL`. Any other value, and `NULL` for SAP HANA, raises `error`. It needs a connector hub with bound SQL arguments (luthersystems/connectorhub#296), which is in connectorhub v0.0.29 snapshot builds and in no stable connectorhub release yet. A phylum package that uses `connector` and defines its own `mk-sql-req` must rename it. **Upgrade note:** upgrade every peer of a channel before a phylum calls it
- **substrate**: `cc:valid-json?` accepts the document as a string as well as bytes. Before, a string document raised `internal-panic`. A document of another type (int, nil, symbol) now raises `error` in place of `internal-panic`. **Upgrade note:** both cases change the response, so upgrade every peer of a channel together
- **substrate**: A defflow body that awaits can use `let` and `let*` binding patterns ([Destructuring in let](common-operation-script/ellipse-dev-language/let-destructuring.md)) and `match` ([Pattern Matching](common-operation-script/ellipse-dev-language/pattern-matching.md)). A clause of `match` can hold `done`, `fail` or an await. A flow with no such form compiles to the same code. **Upgrade note:** check your deployed flows before you upgrade. A `match` whose scrutinee awaits used to fail each run with `flow-unsavable` and now runs. A pattern in such a form that binds a name twice now fails the flow load. An older peer refuses a flow that awaits in one of these forms, so upgrade every peer of a channel together
- **substrate**: **Upgrade note:** a bad argument to a `cc` time builtin (`cc:date`, `cc:timestamp`, `cc:timestamp-unix`, `cc:timestamp-unix-reverse`, `cc:weekday`, `cc:add-seconds`, `cc:add-days`, `cc:add-months`, `cc:add-years`, `cc:add-date`, `cc:days-in`), and a `years-back` with a fraction to `validations:validate-ymd-date-within-years-or-nil`, now raises `argument-error`, a child of `error`. The messages do not change. If a handler reads or returns the condition symbol, upgrade every peer of a channel together
- **substrate**: Security: update `golang.org/x/net` to v0.62.0 (GO-2026-6860, GO-2026-6866). In the chaincode adapter, the same update from v0.60.0 also fixes five HTTP/2 advisories

Details: [substrate v2.254.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.254.0).

## 2026-10-30: substrate v2.253.0

- **substrate**: A phylum no longer needs its own `healthcheck` and `init` endpoints. Call `(router:set-service-info name version build-id)` once at load scope: the default `healthcheck` reports the service name and version, and the default `init` logs the install or upgrade. A phylum that defines its own `healthcheck` or `init` keeps it. A health check of a phylum version that is not in service answers "Method not found"
- **substrate**: **Upgrade note:** the libschema package `s` (validators and record types) is now loaded on every peer, not only with `SUBSTRATE_ENABLE_WASM=true`. A phylum that defines its own package named `s` must rename it. Upgrade every peer of a channel together if a phylum uses `s`
- **substrate**: The `:schema` of `await-input` and the `:result-schema` of `defflow` can be a libschema validator, as well as JSON Schema text
- **substrate**: With `SUBSTRATE_FORBID_CORE_REBIND=true`, a phylum's rebinding of a core symbol is detected in more cases, and a rebind at transaction time fails the transaction. `preheat-check` warns for each one
- **substrate**: Before you upgrade a phylum that reads or writes a `luther:` key to v2.252.0 or later, move that key out of the reserved space (see the v2.252.0 upgrade note)

Details: [substrate v2.253.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.253.0).

## 2026-10-30: substrate v2.252.0

- **substrate**: **Upgrade note:** a phylum write to, or read of, a key that the framework reserves under `luther:` is now refused by default. A write fails the transaction and commits nothing. A point read raises the condition `reserved-key-read`. A range read hides the row. Before you upgrade, check the `substrate_reserved_key_writes_total` and `substrate_reserved_key_reads_total` counters with `outcome="measured"` on each peer, and run `shirotester lint`. The app control settings `substrate_allow_reserved_key_write` and `substrate_allow_reserved_key_read` allow the access again for one channel
- **substrate**: **Upgrade note:** core symbols that were internal are removed, not exported, or not bound. A call of one fails with an unbound symbol. `shirotester lint` reports each qualified use with the `removed-symbol` check, and names the public replacement where there is one
- **substrate**: Bundled ELPS is v1.95.0. It adds the special operator `match` ([Pattern Matching](common-operation-script/ellipse-dev-language/pattern-matching.md)) and patterns in `let` and `let*` bindings ([Destructuring in let](common-operation-script/ellipse-dev-language/let-destructuring.md)). A phylum that does `(set 'match ...)` must rename that symbol: the `core-rebind` lint reports it. Upgrade every peer of a channel together if a phylum uses `match` or a binding pattern
- **substrate**: With `SUBSTRATE_ENABLE_WASM=true`, a flow local can hold a record object across a wait. The resume checks each saved record against its type before the flow continues. `s:set!` is renamed `s:set-field!`
- **substrate**: Lint: `load-scope-context` reports a read of the transaction context in a record type's `:check` and in the functions of the same file that the check calls
- **substrate**: Performance: the private endpoints, the storage constructors, the closure helpers, the batch and connector hooks, `register-endpoint` and the last core macros run in Go. Their names, arguments and responses do not change, and they use fewer ELPS steps
- **substrate**: The `wrap-cc` chaincode container runs as a non-root user

Details: [substrate v2.252.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.252.0).

## 2026-10-30: elps v1.95.0

- **Embedding**: New `Package.Seal` lets an embedder seal its own package, so Lisp code cannot rebind its symbols
- **Embedding**: New Go helpers for hosts: `LEnv.CheckAllocs`, `LEnv.PanicError`, `ResetOwnershipTable`, `MapLoadCache` (a load cache with no eviction), `NewDurableTimeCodec`, `NewDurableDurationCodec` and `libstring.SplitCount`. `libstring.Split` and `libstring.Repeat` are now exported
- **Testing**: `Runner.LoadHelpers` and `Runner.LoadHelpersFn` let another test runner load the `*_testhelpers.lisp` files

Details: [elps v1.95.0 release](https://github.com/luthersystems/elps/releases/tag/v1.95.0).

## 2026-10-30: elps v1.94.0

- **Embedding**: New `(*DurableRegistry).FunCaptures` returns the captures that a `DurableFunCodec` saves, so an embedder that walks saved values can enter them. It returns the object's own value, not a copy

Details: [elps v1.94.0 release](https://github.com/luthersystems/elps/releases/tag/v1.94.0).

## 2026-10-29: elps v1.93.0

- **lisp**: New special operator `match`, with list and vector patterns ([Pattern Matching](common-operation-script/ellipse-dev-language/pattern-matching.md)). `let` and `let*` bindings accept the same destructuring patterns ([Destructuring in let](common-operation-script/ellipse-dev-language/let-destructuring.md)). **Upgrade note:** code that binds its own `match`, for example with `(set 'match ...)`, must rename that symbol
- **libschema**: New record types with methods (`s:defmethod`), fields set with `s:set-field!`, interfaces (`s:make-interface`), `s:is?`, `s:as` and `match` on records. A record's `:check` runs after each method, and a failed check restores the fields. A field write outside one of the type's methods, a write in a `:check`, and an `s:defmethod` outside a load are refused at run time with `record-error`
- **lint**: New checks for records (unknown members, method arity, method types, writes in a `:check`, a `set!` of a closure local in a method, `s:defmethod` that is not at top level) and for a repeated `match` pattern
- **Embedding**: Go function objects (`lisp.NewCapturedFun`) can be saved in durable dumps. New `Template.ExpandChecked` and `LEnv.RegisterBuiltins`

Details: [elps v1.93.0 release](https://github.com/luthersystems/elps/releases/tag/v1.93.0).

## 2026-10-26: elps v1.92.0

- **lval**: New package `lval` reads and writes ELPS values as typed JSON in Go without the interpreter, for example in a WebAssembly guest

Details: [elps v1.92.0 release](https://github.com/luthersystems/elps/releases/tag/v1.92.0).

## 2026-10-26: substrate v2.251.0

- **substrate**: Performance: the utils macros, `invoke-phylum`, the connector package, the B+-tree cursors and the merged toset iterator run in Go. Their names, arguments and responses do not change
- **substrate**: Performance: calls of customer built-ins (preview) are faster

Details: [substrate v2.251.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.251.0).

## 2026-10-25: substrate v2.250.0

- **substrate**: Preview: customer built-ins. With `SUBSTRATE_ENABLE_WASM=true` set the same on every channel peer, a phylum can call customer Go compiled to WebAssembly with the `wasm` package (`wasm:load`, `wasm:call`, `wasm:call-bytes`). The setting is off by default
- **substrate**: The first successful `update` stores the chaincode name on the ledger, so every peer uses the same name for its own-request check. An admin can correct it with `$set_chaincode_name`. **Upgrade note:** this adds one read to each privileged method, so upgrade every peer of a channel together
- **substrate**: Performance: the router, the decimal money helpers, the parallel counters, the MXF codec, the private and batch packages, the appctrl readers, the last statedb functions and more utils helpers run in Go. Their names, arguments and responses do not change
- **substrate**: Bundled ELPS moves to v1.91.0

Details: [substrate v2.250.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.250.0).

## 2026-10-24: svc v0.19.2

- **svc**: The elps dependency moves from v1.75.1 to v1.91.0, so a program that uses svc v0.19.2 also builds with elps v1.91.0 or later. **Upgrade note:** if your own Go code calls the elps Go API, apply the elps v1.90.0 and v1.91.0 upgrade notes below
- **svc**: Update the AWS SDK for Go v2, OpenTelemetry v1.47.0, the Prometheus client v1.25.0 and `golang.org/x/crypto` v0.58.0

Details: [svc v0.19.2 release](https://github.com/luthersystems/svc/releases/tag/v0.19.2).

## 2026-10-24: elps v1.91.0

- **Embedding**: **Upgrade note:** every Go form of a builtin now returns its value with a Go `error`, and every check returns `error`. Test `err != nil` in place of `v.IsError()`. `lisp.Error(err)` returns the error as an `LError`. One change of behaviour: `Car`, `First`, `Second`, `Nth` and `MapLookup` now return an error value stored in a list or map as their Go error. Before, they returned it as a value with a nil error. The step counts do not change

Details: [elps v1.91.0 release](https://github.com/luthersystems/elps/releases/tag/v1.91.0).

## 2026-10-24: elps v1.90.0

- **Embedding**: **Upgrade note:** a Go form of a builtin whose result has one type, for example `LEnv.Length` or `LEnv.ToString`, returns `(T, error)`. Read the Go value and test `err != nil` in place of `IsError`

Details: [elps v1.90.0 release](https://github.com/luthersystems/elps/releases/tag/v1.90.0).

## 2026-10-23: elps v1.89.0

- **Testing**: More tests for the type predicates. The language and the Go API do not change

Details: [elps v1.89.0 release](https://github.com/luthersystems/elps/releases/tag/v1.89.0).

## 2026-10-23: mars v0.143.0

- **fabric-peer chart**: Security: a peer that runs Docker chaincode now builds it in `luthersystems/fabric-ccenv` and runs it in `luthersystems/fabric-baseos` (buildenv v0.1.48). These images block the 25 certificates of CVE-2026-111943. The chart picks the tag from the Fabric minor of the peer (2.2, 2.4 or 2.5). On 2.5, only the builder changes, because the upstream runtime image has no CA bundle. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md#set-the-images-with-mars)
- **fabric-peer chart**: New Ansible values `k8s_fabric_peer_chaincode_images_version`, `k8s_fabric_peer_chaincode_builder_image` and `k8s_fabric_peer_chaincode_golang_runtime_image` change the images
- **fabric-peer chart**: **Upgrade note:** the peer keeps the chaincode images that it built before on its persistent volume. In the `docker-chaincodes` sidecar, remove the old `dev-<peer ID>-` containers, then their images, then restart the peer. A peer that uses chaincode as a service does not change
- **fabric-peer chart**: **Upgrade note:** for Fabric 2.2, 2.4 and 2.5, a `buildImage.repository` override no longer sets the builder. To use a private mirror, set the two full image values. To keep the upstream images, set `k8s_fabric_peer_chaincode_images_version` to `""`

Details: [mars v0.143.0 release](https://github.com/luthersystems/mars/releases/tag/v0.143.0).

## 2026-10-23: elps v1.88.0

- **Go interop**: Go structs now decode and encode as sorted maps
- **Embedding**: Each builtin's Go helper is registered, and `BuiltinFunc` reports when a builtin has one

Details: [elps v1.88.0 release](https://github.com/luthersystems/elps/releases/tag/v1.88.0).

## 2026-10-23: elps v1.87.1

- **Performance**: Forked VMs share the docstring of a registered builtin. They do not copy it

Details: [elps v1.87.1 release](https://github.com/luthersystems/elps/releases/tag/v1.87.1).

## 2026-10-23: buildenv v0.1.48

- **fabric-ccenv and fabric-baseos**: New images for peers that run Docker chaincode. Each is the upstream Hyperledger image with the 25 certificates blocked. fabric-ccenv is for Fabric 2.2, 2.4 and 2.5, and fabric-baseos for 2.2 and 2.4. Tags are `<Fabric minor>-v0.1.48`. See [Docker chaincode](security-notice-emsign.md#docker-chaincode-fabric-ccenv-and-fabric-baseos)
- **build-harden**: The kit now also checks that the roots the images need stay trusted after hardening
- **General**: All images are rebuilt on the latest base images and OS packages

Details: [buildenv v0.1.48 release](https://github.com/luthersystems/buildenv/releases/tag/v0.1.48).

## 2026-10-23: elps v1.87.0

- **lisp**: New Go helpers for ports of Lisp code: `CallValue`, `CheckCallable` and `MapSeqFunc`

Details: [elps v1.87.0 release](https://github.com/luthersystems/elps/releases/tag/v1.87.0).

## 2026-10-23: elps v1.86.0

- **libschema**: New type names `list`, `sequence` and `nil`. New `map-of` checks every key and value of a map. New `describe` returns the definition of a validator as a sorted map

Details: [elps v1.86.0 release](https://github.com/luthersystems/elps/releases/tag/v1.86.0).

## 2026-10-22: substrate v2.249.0

- **substrate**: Performance: the ctx migration engine runs in Go (`def-migration-ctx`, `run-ctx-migrations`, `migration-tuning` and `set-migration-loop-limit`). Their names and arguments do not change. Cached steps and frontier records keep the same keys and values, so a migration in progress continues after the upgrade. See [Automated Migrations](common-operation-script/automated-migrations.md)
- **substrate**: **Upgrade note:** `utils:ctx-migrations`, `utils:up-migrations` and `utils:migration-loop-limits` are no longer exported. Register migrations with the macros and set loop limits with `utils:set-migration-loop-limit`. `shirotester lint` reports each reference and names the replacement
- **substrate**: `pvtdata_health_check` answers a new `pending` member: `true` means wait, `false` with `synced: false` means stop once the peer has caught up. A sentinel under `luther:private:` now works when reserved key reads are refused
- **shiroclient**: When a usage tick drops blocks older than the last 10,000, the gateway sends the dropped range to the license server, logs a warning and counts the blocks in `luther_license_usage_blocks_lost_total`
- **substrate**: Performance: the 3 log lines of each transaction take less CPU. The bytes of each line do not change

Details: [substrate v2.249.0 release](https://github.com/luthersystems/substrate/releases/tag/v2.249.0).

## 2026-10-22: mars v0.142.0

- **supergateway and mcp-inspector charts**: Security: the charts run the hardened `luthersystems/supergateway-uvx-git:3.4.3-2` in place of the third-party `supercorp/supergateway:uvx` (CVE-2026-111943). See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **supergateway and mcp-inspector charts**: **Upgrade note:** the default image changes repository, and the tag moves from the floating `uvx` to the pinned 3.4.3-2. If you override `image.tag` in these charts, also set `image.repository`, or remove both overrides. A tag of the old image does not exist in the new repository

Details: [mars v0.142.0 release](https://github.com/luthersystems/mars/releases/tag/v0.142.0).

## 2026-10-22: buildenv v0.1.47

- **build-js**: azure-cli's own Python now uses certifi 2026.10.19, so scanners no longer report GHSA-6q48-6c7w-9gw2 for its old certifi 2024.7.4. Trust does not change: since v0.1.45 the image removes the emSign roots and AAA Certificate Services from that bundle. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **General**: All images are rebuilt on the latest base images and OS packages

Details: [buildenv v0.1.47 release](https://github.com/luthersystems/buildenv/releases/tag/v0.1.47).

## 2026-10-22: connectorhub v0.0.28

- **connectorhub**: Security: every connector now runs on the hardened supergateway 3.4.3-2 images (CVE-2026-111943). No connector uses `supercorp/supergateway` any more. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **connectorhub**: **Upgrade note:** remove the supergateway 3.4.3-2 pins that the security notice gave for v0.0.27, or keep them at 3.4.3-2 or later

Details: [connectorhub v0.0.28 release](https://github.com/luthersystems/connectorhub/releases/tag/v0.0.28).

## 2026-10-22: mars v0.141.0

- **fabric charts**: Security: the chart defaults use the hardened images (CVE-2026-111943). The AWS CLI init containers of every Fabric and shiroclient chart run `luthersystems/awscli:v0.1.46`, the peer's Docker sidecar runs `luthersystems/dind:v0.1.46`, the fabric-cli chart runs `luthersystems/fabric-tools:v0.1.46` and the snapshot archiver defaults to v0.0.8. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **fabric charts**: **Upgrade note:** remove the manual image overrides that the security notice gave for v0.140.0, or keep them at v0.1.46 or later

Details: [mars v0.141.0 release](https://github.com/luthersystems/mars/releases/tag/v0.141.0).

## 2026-10-22: mars v0.140.0

- **mars**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image blocks 25 certificates in every trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). The Go binaries are built with Go 1.26.10 (GO-2026-6809)
- **prometheus**: The pushprox chart runs the hardened `luthersystems/pushprox:v0.1.0` as a non-root user. **Upgrade note:** pushprox is deprecated and off by default (`k8s_prometheus_pushproxy: false`)
- **fabric charts**: **Upgrade note:** the chart defaults do not use the hardened images yet. The peer, orderer, CA, CLI and shiroclient charts run the AWS CLI in init containers that copy MSP, TLS, chaincode and config files from S3. Set these values in your inventory:

  ```yaml
  luther_buildenv_images_version: v0.1.45   # luthersystems/awscli
  k8s_fabric_peer_dind_version: v0.1.45     # Docker 28.5.2, the same as v0.1.43
  k8s_fabric_peer_snapshot_archiver_version: v0.0.8
  ```

Details: [mars v0.140.0 release](https://github.com/luthersystems/mars/releases/tag/v0.140.0).

## 2026-10-22: buildenv v0.1.46

- **General**: Fix for images that other repositories build on a Debian or Ubuntu JDK: the hardening step now also blocks the 25 certificates in that JDK's `blocked.certs`, which is a link on those systems. The buildenv images themselves do not change. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).

## 2026-10-22: fabric-network-builder v0.0.10

- **fabric-network-builder**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image blocks 25 certificates in every trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). This includes pip's certifi bundle

Details: [fabric-network-builder v0.0.10 release](https://github.com/luthersystems/fabric-network-builder/releases/tag/v0.0.10).

## 2026-10-22: fabric-snapshot-archiver v0.0.8

- **fabric-snapshot-archiver**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image blocks 25 certificates in every trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). The archiver uses this trust store for its S3 uploads. Built with Go 1.26.10 (GO-2026-6809)

## 2026-10-22: supergateway images 3.4.3-2

Part of Connector Hub. The images are `luthersystems/supergateway-debian`, `luthersystems/supergateway-npx-git` and `luthersystems/supergateway-uvx-git`.

- **supergateway**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image blocks 25 certificates in every trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). Node.js, npm, npx, uv, httpx and requests read the hardened system bundle
- **supergateway**: **Upgrade note:** Connector Hub v0.0.28 and later use 3.4.3-2 by default. The Connector Hub v0.0.27 connector defaults still name 3.4.3-1: upgrade to v0.0.28, or pin the 3.4.3-2 images by digest in your connector configs

## 2026-10-22: substrate v2.248.0

- **substrate**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The `luthersystems/substrate`, `luthersystems/shiroclient` and `luthersystems/shirotester` images block 25 certificates in their trust stores, and are built with Go 1.26.10, which refuses the compromised eMudhra intermediates (GO-2026-6809). See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **substrate**: **Upgrade note:** this release changes transaction results for some phyla. Upgrade every peer of a channel together. Run `shirotester lint` and `shirotester preheat-check` on each phylum before you upgrade
- **substrate**: **Upgrade note:** batch and connector keys move under `luther:`. Drain pending batch requests and connector callbacks before you upgrade, and upgrade Connector Hub to v0.0.26 or later at the same time
- **substrate**: **Upgrade note:** keys under `luther:` are reserved for substrate. A phylum read or write of such a key is logged now, and a later release refuses it. Move phylum data under `luther:` to a prefix of your own. `shirotester lint` reports literal reserved keys
- **substrate**: **Upgrade note:** a paginated range counts rows the transaction deleted toward the page size. Continue while the bookmark is not empty; a short page does not mean that the range ended. `SUBSTRATE_LEGACY_RANGE_PAGES=true` restores the old pages
- **substrate**: **Upgrade note:** behaviour changes in `decimal-pow` with a fractional or negative exponent, MXF encode with overlapping private paths (now refused), field-mask entries that start with `.` (now nested paths) and `handler-bind` with several matching bindings (the most specific runs). `shirotester lint` reports affected `handler-bind` forms
- **substrate**: **Upgrade note:** some `utils:` and `validations:` exports and router internals are removed. `shirotester lint` reports each reference and names the replacement
- **substrate**: Security: the router refuses privileged methods (`update`, `enable`, `disable`, `init`, `run_ctx_migrations` and others) when another chaincode passes the call on. Set `CHAINCODE_NAME` to the chaincode definition name on every peer. A phylum checks its own endpoints with `(cc:own-request?)`
- **substrate**: New `SUBSTRATE_AUTH_CLAIMS_JWKS_SOURCE=ledger` reads the auth token keys from the ledger, so a key rotation is one transaction (`$auth_set_jwks`, for a creator of the admin MSP)
- **substrate**: Performance: more core functions run in Go (statedb ranges, sidedb, storage indexes, validators and log functions). Results do not change and ELPS step counts go down. Log lines are written in batches with less CPU
- **shiroclient**: The gateway keeps numbers exact in params, results and error data, also above 2^53, and passes results as the phylum wrote them
- **shiroclient**: A malformed `Authorization` header answers 400, and `/health_check?service=fabric_peer` answers 503 when the peer check fails
- **shirotester**: New `unit-tests --creator <MSP>` gives each test a creator MSP
- **substrate**: Bump ELPS to v1.85.0

## 2026-10-22: connectorhub v0.0.27

- **connectorhub**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image blocks 25 certificates in every trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). Built with Go 1.26.10 (GO-2026-6809)

## 2026-10-22: pushprox v0.1.0

- **pushprox**: **Upgrade note:** pushprox is deprecated. It belongs to the older buildpack chaincode setup. v0.1.0 is a hardened rebuild for deployments that still run it
- **pushprox**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image blocks 25 certificates in every trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). Built with Go 1.26.10 (GO-2026-6809). The image runs as `nobody`

Details: [pushprox v0.1.0 release](https://github.com/luthersystems/pushproxng/releases/tag/v0.1.0).

## 2026-10-22: hyphae v1.2.0

One hyphae tag publishes the `luthersystems/pdfserv` and `luthersystems/martin` images.

- **pdfserv**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image blocks 25 certificates in every trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). Chrome uses an NSS database that distrusts the 25 certificates. Startup fails when Chrome does not use the database
- **martin**: Security: the image blocks the same 25 certificates. **Upgrade note:** martin runs as `nobody` (uid 65534) in `/opt`. Make each report mount writable by uid 65534
- **pdfserv, martin**: Security: built with Go 1.26.10 (GO-2026-6809, and GO-2026-6599 and GO-2026-6600 in `html/template`). Update `golang.org/x/net` to v0.60.0

Details: [hyphae v1.2.0 release](https://github.com/luthersystems/hyphae/releases/tag/v1.2.0).

## 2026-10-22: insideout-mcp v0.50.4

- **insideout-mcp**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image blocks 25 certificates in every trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **insideout-mcp**: **Upgrade note:** the image runs as `nobody` (uid 65534). Check volume permissions and any `runAsUser` setting in your deployment
- **insideout-mcp**: No MCP tool or A2A changes

## 2026-10-22: mars v0.139.1

- **mars**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image blocks 25 certificates in every trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). This includes the Python packages (certifi, botocore), the AWS CLI and the Google Cloud CLI

Details: [mars v0.139.1 release](https://github.com/luthersystems/mars/releases/tag/v0.139.1).

## 2026-10-22: Luther Auth v4.8.3

- **General**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The `luthersystems/auth` image blocks 25 certificates in its trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. It is built with Go 1.26.10, which refuses the compromised eMudhra intermediates (GO-2026-6809). See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).

## 2026-10-22: sandbox v0.0.2

The release publishes `luthersystems/oracle:v0.0.2`, the example application image of Luther Enterprise.

- **oracle**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image blocks 25 certificates in every trust store: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). Built with Go 1.26.10 (GO-2026-6809)
- **oracle**: Security: update gRPC to v1.83.2 and `golang.org/x/net` to v0.60.0
- **sandbox**: **Upgrade note:** the local network still uses substrate v2.240.0, fabric-network-builder v0.0.9 and martin v1.0.0, which predate the emSign fix. For the fix, set substrate v2.248.0, fabric-network-builder v0.0.10 and martin (hyphae) v1.2.0
- **phylum**: Fix: the sample phylum loads on ELPS v1.62 and later

Details: [sandbox v0.0.2 release](https://github.com/luthersystems/sandbox/releases/tag/v0.0.2).

## 2026-10-22: buildenv v0.1.45

- **General**: Security: full fix for the eMudhra (emSign) CA issue (CVE-2026-111943). Every image blocks 25 certificates: 6 emSign roots, 18 eMudhra intermediates and Comodo AAA Certificate Services, which cross-signed them. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **General**: The images remove or block these certificates in the OS bundle, Java, Python certifi, Node.js and Chrome/NSS. The build fails if a listed certificate still verifies, on amd64 and arm64
- **build-js**, **build-e2e**: Node.js uses the hardened system bundle (`NODE_OPTIONS=--use-openssl-ca` and `SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt`)

## 2026-10-22: libmxf v0.1.1

- **libmxf**: **Upgrade note:** use v0.1.1, not v0.1.0. With v0.1.0, `go get` delivers a broken decoder file, so `decode-go` cannot decode
- **libmxf**: Binaries that link `decode-go` are about 6 MB smaller
- **libmxf**: Security: the module's toolchain is Go 1.26.10, which refuses the compromised eMudhra intermediates (CVE-2026-111943, GO-2026-6809). A library does not set the Go that builds your program, so build with Go 1.26.10 or later. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).

Details: [libmxf v0.1.1 release](https://github.com/luthersystems/libmxf/releases/tag/v0.1.1).

## 2026-10-22: connectorhub v0.0.26

- **connectorhub**: Security: partial fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image removes the emSign root CAs only. Use v0.0.27. Built with Go 1.26.10 (GO-2026-6809). The Python connectors use certifi 2026.10.19
- **connectorhub**: **Upgrade note:** use substrate v2.248.0 or later. The hub reads connector events and callback states under the `luther:` prefix
- **connectorhub**: **Upgrade note:** the config, test and call endpoints require a Luther Auth JWT. Set `CH_AUTH_ISSUER` and `CH_AUTH_JWKS_URL`. `GetConfig` and `CallConnector` need `CH_AUTH_ADMIN_GROUPS`. `TestConnection` needs `CH_AUTH_AUDIENCE` or `CH_AUTH_REQUIRED_GROUPS`. Without them, these calls return 401
- **connectorhub**: **Upgrade note:** an MCP tool is denied unless the connector allows it (`allowed_tools`). Each MCP image must come from an allowed registry (`CH_IMAGE_REGISTRIES`) and be pinned by digest
- **connectorhub**: The hub runs with leader election and moves its block stream to another peer when the primary is down. A malformed request fails alone, not the whole block, and the hub never resends a tool call that is not idempotent
- **connectors**: New generic remote MCP connector for your own server. DocuSign, ServiceNow and Zoho Books use the vendors' hosted MCP servers. Connector containers run read-only, with no capabilities, deny-by-default egress and no access to cloud metadata

## 2026-10-22: Luther Auth v4.8.2

- **General**: **Upgrade note:** with an OAuth backend enabled, Luther Auth fails to start when `AUTH_OAUTH_VALID_FRONTEND_REDIRECT_URLS` is empty. Before, an empty list turned the redirect check off. Set the list before you upgrade
- **General**: **Upgrade note:** the OAuth code flow to the IdP uses PKCE (S256). During the rolling deploy that turns PKCE on, a login that starts on a new pod and finishes on an old pod fails, and the user must log in again. Set `AUTH_OAUTH_DISABLE_PKCE=true` only for an IdP that refuses the PKCE parameters. Auth0, Cognito and Azure AD B2C accept them
- **General**: Security: PKCE stops code injection. An attacker who holds a victim's authorization code cannot redeem it through the callback
- **General**: Security: the callback checks the frontend redirect URL against `AUTH_OAUTH_VALID_FRONTEND_REDIRECT_URLS` again before it redirects, so a forged cookie cannot redirect a session token off the allowlist
- **General**: On SIGINT or SIGTERM the server stops accepting connections and lets requests in progress complete. New setting `AUTH_SHUTDOWN_TIMEOUT` (default 20s) bounds the wait. It fits the Kubernetes default `terminationGracePeriodSeconds` of 30s
- **General**: Security: build with Go 1.26.10, whose crypto/x509 refuses the compromised eMudhra intermediate CAs (GO-2026-6809). The image is built on buildenv v0.1.41, which only removes the emSign root CAs from the trust store (CVE-2026-111943). Upgrade to v4.8.3 for the full fix. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **General**: Upgrade Go dependencies, including svc v0.19.0, gRPC v1.83.2 and the AWS SDK for Go v2

## 2026-10-22: blockinspector v0.1.0

- **blockinspector**: First tagged release. Commands: `range-peer`, `range-orderer`, `snapshot` and `pvtdata-keys`. The `ledger` Go package reads private data keys from a peer's ledger
- **blockinspector**: Security: `go install` builds with Go 1.26.10, which refuses the compromised eMudhra intermediates (CVE-2026-111943, GO-2026-6809). Update gRPC to v1.83.2 and `golang.org/x/net` to v0.60.0. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).

Details: [blockinspector v0.1.0 release](https://github.com/luthersystems/blockinspector/releases/tag/v0.1.0).

## 2026-10-22: insideout-mcp v0.50.3

- **insideout-mcp**: Security: built with Go 1.26.10, which refuses the compromised eMudhra intermediates (GO-2026-6809). See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). Use v0.50.4 for the full fix
- **insideout-mcp**: No MCP tool or A2A changes

## 2026-10-22: insideout-terraform-presets v0.12.0

- **insideout-terraform-presets**: Security: the module's toolchain is Go 1.26.10, which refuses the compromised eMudhra intermediates (CVE-2026-111943, GO-2026-6809). A library does not set the Go that builds your program, so build with Go 1.26.10 or later. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md). Also update gRPC to v1.83.2 and `golang.org/x/net` to v0.60.0
- **composer**: **Upgrade note:** composed stacks pin the AWS provider to `= 6.52.0` and the Google providers to `= 6.10.0`. The default `.terraform-version` is 1.9.8
- **composer**: **Upgrade note:** the AWS imported-provider credential variables are `bootstrap_role` and `aws_external_id`. `bootstrap_role_arn`, `external_id` and `/variables-imported.tf` are removed
- **aws**: New components: Bedrock Knowledge Base, Bedrock Agent, GPU, vector stores, SageMaker inference endpoint, Kendra and AgentCore gateway
- **gcp**: New components: Vertex AI Agent Engine, Vertex AI endpoint, GPU on GKE and Compute Engine, Document AI, Model Armor and VPC Private Services Access
- **reverse import**: New reverse import SDK and CLI. One run covers many regions, skips AWS-managed resources and reports a partial result when some resources fail

Details: [insideout-terraform-presets v0.12.0 release](https://github.com/luthersystems/insideout-terraform-presets/releases/tag/v0.12.0).

## 2026-10-22: mars v0.139.0

- **mars**: Security: partial fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image removes the emSign root CAs only. Use v0.140.0

Details: [mars v0.139.0 release](https://github.com/luthersystems/mars/releases/tag/v0.139.0).

## 2026-10-22: supergateway images 3.4.3-1

- **supergateway**: Security: partial fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image removes the emSign root CAs only. Use 3.4.3-2
- **supergateway**: Node.js, npm and npx read the system bundle (`NODE_OPTIONS=--use-openssl-ca`). **Upgrade note:** if your connector sets `NODE_OPTIONS`, keep `--use-openssl-ca` in it

## 2026-10-22: libmxf v0.1.0

- **libmxf**: First tagged release, with the `decode-go` and `decode-js` MXF decoders
- **libmxf**: **Upgrade note:** do not use v0.1.0 with `go get`. Use v0.1.1

Details: [libmxf v0.1.0 release](https://github.com/luthersystems/libmxf/releases/tag/v0.1.0).

## 2026-10-21: shiroclient-sdk-go v0.18.0

- **shiroclient-sdk-go**: Security: the module's toolchain is Go 1.26.10, which refuses the compromised eMudhra intermediates (CVE-2026-111943, GO-2026-6809). A library does not set the Go that builds your program, so build with Go 1.26.10 or later. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **shiroclient-sdk-go**: New `update.SetAuthJWKS` and `update.SetAuthAdminMSP` call substrate's `$auth_set_jwks` and `$auth_set_admin_msp` methods
- **shiroclient-sdk-go**: **Upgrade note:** a new mock client sets the creator MSP to `Org1MSP` (`mock.DefaultCreator`). Use `mock.WithCreator("")` to keep the creator unset
- **shiroclient-sdk-go**: Security: update `golang.org/x/net` to v0.60.0

Details: [shiroclient-sdk-go v0.18.0 release](https://github.com/luthersystems/shiroclient-sdk-go/releases/tag/v0.18.0).

## 2026-10-21: svc v0.19.1

- **svc**: Security: the module's toolchain is Go 1.26.10, which refuses the compromised eMudhra intermediates (CVE-2026-111943, GO-2026-6809). A library does not set the Go that builds your program, so build with Go 1.26.10 or later. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **svc**: Security: update `golang.org/x/net` to v0.60.0

Details: [svc v0.19.1 release](https://github.com/luthersystems/svc/releases/tag/v0.19.1).

## 2026-10-21: lutherauth-sdk-go v0.0.10

- **lutherauth-sdk-go**: Security: the module's toolchain is Go 1.26.10, which refuses the compromised eMudhra intermediates (CVE-2026-111943, GO-2026-6809). A library does not set the Go that builds your program, so build with Go 1.26.10 or later. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **lutherauth-sdk-go**: Fix: the JWKS fetch closes its response body. Fetch errors wrap their cause, so `errors.Is` and `errors.As` work on them

Details: [lutherauth-sdk-go v0.0.10 release](https://github.com/luthersystems/lutherauth-sdk-go/releases/tag/v0.0.10).

## 2026-10-21: buildenv v0.1.44

- **General**: Security: remove the emSign roots from every text CA bundle in the image by content, whatever the file name (for example grpc `roots.pem` and gsutil `cacerts.txt`). This release removes only the roots. Use v0.1.45 or later for the full fix (CVE-2026-111943). See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).

## 2026-10-21: mars v0.138.0

- **mars**: Security: partial fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image removes the emSign root CAs only. Use v0.140.0. The Go binaries are built with Go 1.26.10 (GO-2026-6809)
- **fabric charts**: The AWS CLI init containers run `luthersystems/awscli` in place of `amazon/aws-cli`. `luther_buildenv_images_version` sets the tag. **Upgrade note:** each `*_aws_cli_version` variable now holds a buildenv tag. Remove a value that names an AWS CLI version
- **fabric-peer**: The Docker sidecar (Docker chaincode, deprecated) runs `luthersystems/dind` with Docker 28.5.2 in place of Docker 19.03. **Upgrade note:** Docker 28 upgrades the peer's Docker volume in place. A rollback to Docker 19.03 is not safe
- **fabric-peer, fabric-orderer**: The liveness probe restarts a node only after 3 failed checks (about 30 s). Change a probe with `k8s_fabric_peer_probes` or `k8s_fabric_orderer_probes`
- **fabric-chaincode**: External and CCaaS substrate chaincode pods get `CHAINCODE_NAME`. With it, substrate refuses privileged requests that another chaincode passes on

Details: [mars v0.138.0 release](https://github.com/luthersystems/mars/releases/tag/v0.138.0).

## 2026-10-21: elps v1.85.0

- **lisp**: New `LEnv.StepEach` charges evaluation steps for a loop and stops at the same point as the equivalent `Step` calls
- **lisp**: New embedder helpers: `LEnv.MapSeqCells` (the sequence read of `map`), `CallStack.SourceSite`, `elpsutil.FileLoader` for constant source and `elpsutil.DumpErrorStack`
- **elpstest**: New helpers measure the step charge of a builtin. `Runner` writes Lisp error traces with `elpsutil.DumpErrorStack`

## 2026-10-21: fabric-snapshot-archiver v0.0.7

- **fabric-snapshot-archiver**: Security: partial fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image removes the emSign root CAs only. Use v0.0.8. Built with Go 1.26.10 (GO-2026-6809)
- **fabric-snapshot-archiver**: S3 archives are stored at `<prefix>/<channel>/<block>`, so one bucket prefix serves every channel. A restore also reads the old layout. **Upgrade note:** upgrade all archivers that share a bucket prefix together

## 2026-10-21: fabric-network-builder v0.0.9

- **fabric-network-builder**: Security: partial fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image removes the emSign root CAs only. Use v0.0.10
- **fabric-network-builder**: Update cryptography to 50.0.2. With the same flags, `generate` writes the same files and config as before

Details: [fabric-network-builder v0.0.9 release](https://github.com/luthersystems/fabric-network-builder/releases/tag/v0.0.9).

## 2026-10-21: buildenv v0.1.43

- **dind**: Move to Docker 28.5.2. Fabric 2.5 peers build, install and run Go chaincode on it
- **dind**: Start on a `/var/lib/docker` volume that Docker 19.03 wrote. The entrypoint removes the old build cache metadata that newer Docker refuses
- **dind**: Upgrade the Alpine packages of the base image
- **General**: Security: this release removes only the emSign roots. Use v0.1.45 or later for the full fix (CVE-2026-111943). See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).

## 2026-10-21: fabric-snapshot-archiver v0.0.6

- **fabric-snapshot-archiver**: Security: partial fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image removes the emSign root CAs only. Use v0.0.8
- **fabric-snapshot-archiver**: Fix: the binary is `fabric-snapshot-archiver` again
- **fabric-snapshot-archiver**: New `restore --wait-pvtdata` waits for private data reconciliation

## 2026-10-21: fabric-snapshot-archiver v0.0.5

- **fabric-snapshot-archiver**: Security: partial fix for the eMudhra (emSign) CA issue (CVE-2026-111943). The image removes the emSign root CAs only. Use v0.0.8
- **fabric-snapshot-archiver**: **Upgrade note:** this image ships the binary as `archiver`. Use v0.0.6 or later
- **fabric-snapshot-archiver**: New `serve` command starts a gRPC API (port 50051) and an HTTP gateway (port 8080) to start, cancel and report snapshots and restores

## 2026-10-21: buildenv v0.1.42

- **awscli**: New image `luthersystems/awscli`: `amazon/aws-cli` 2.35.11 with the emSign roots removed
- **dind**: New image `luthersystems/dind`: `docker:19.03.14-dind` with the emSign roots removed
- **fabric-tools**: New image `luthersystems/fabric-tools`: `hyperledger/fabric-tools` 2.5.6 with the emSign roots removed
- **General**: Security: remove the emSign roots from the Red Hat and Amazon Linux trust store (`/etc/pki/ca-trust`) too. This release removes only the roots. Use v0.1.45 or later for the full fix (CVE-2026-111943). See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).

## 2026-10-21: buildenv v0.1.41

- **General**: Security: remove the four eMudhra emSign root CAs from the system bundle, every Java `cacerts` keystore and bundled Python `cacert.pem` files (CVE-2026-111943). The build fails if one remains. This release removes only the roots. Use v0.1.45 or later for the full fix. See [Security Notice: eMudhra (emSign) CA Distrust](security-notice-emsign.md).
- **General**: Security: Go 1.26.10. It fixes GO-2026-6809: `crypto/x509` refuses the eMudhra intermediates
- **build-js**: **Upgrade note:** move to Node.js 24.22.1. Node.js 20 is past end of life. Node.js 24.22.1 drops the eMudhra roots from its built-in CA list
- **build-godynamic**: Security: certifi 2026.10.19 and pip 26.2.2 in the Azure CLI environment (GHSA-6q48-6c7w-9gw2)
- **build-api**: Security: build buf with klauspost/compress 1.18.7 (CVE-2026-63209)

## 2026-10-21: elps v1.84.0

- **lisp**: `Runtime` can hold Lisp values per VM, so an embedder keeps state that each template VM gets its own copy of
- **elps**: Security: build with Go 1.26.10, which fixes GO-2026-6809 in `crypto/x509`

## 2026-10-21: elps v1.83.0

- **lisp**: **Upgrade note:** the Go sequence forms `LEnv.Concat`, `LEnv.MapSeq`, `LEnv.Slice` and `LEnv.Zip` take a `SeqKind` constant in place of a type specifier symbol, so the compiler checks the type. Pass `lisp.SeqList`, `lisp.SeqVector`, `lisp.SeqString`, `lisp.SeqBytes` or `lisp.SeqNil` in place of `lisp.Symbol(...)` or `lisp.Nil()`

## 2026-10-20: elps v1.82.0

- **lisp**: More core builtins have an exported Go form, so Go code can call them directly without a Lisp evaluation

## 2026-10-20: elps v1.81.2

- **lisp**: Function name index updates apply at the next lookup, which lowers the cost of binding many functions
- **elps**: The integrity check in `elpscheck` builds for frozen packages is cheaper

## 2026-10-20: elps v1.81.1

- **lisp**: Functions with one name take their name list from a shared spare block, which cuts allocations when a phylum defines many functions

## 2026-10-19: buildenv v0.1.40

- **build-godynamic**: Security: build Docker Compose with containerd 2.2.7 (CVE-2026-95837)
- **build-godynamic**, **nginx-frontend**: Security: curl and libcurl 8.23.0 (CVE-2026-92392)
- **nginx-frontend**: Security: libx11 1.8.14 (CVE-2026-88806)

## 2026-10-19: buildenv v0.1.39

- **General**: Rebuild on current base images and packages.

## 2026-10-19: elps v1.81.0

- **lisp**: Fix: a builtin that `LEnv.CallBuiltin` calls keeps the correct caller frame when the call stack grows
- **lisp**: Function names are found through an index by function ID, which makes name lookup faster

## 2026-10-19: elps v1.80.0

- **lisp**: The evaluator does less work for each call form, and template VMs prewarm only the values that most VMs read
- **lisp**: New Go helpers: `LEnv.CallFunction`, `LEnv.ApplyFunction`, `LEnv.MapKeys`, `Length`, `IsEmpty`, `First` and `Second`. `elpsutil.Function` seals builtin formals
- **lisp**: Fix: a nil head in a call form goes to `eval` before its step, and `list` called from Go with an s-expression returns a data list
- **elpstest**: New `elpstest/oracle` package compares a Go copy of a builtin with the original

## 2026-10-17: buildenv v0.1.38

- **General**: Rebuild on current base images and packages.

## 2026-10-16: elps v1.79.1

- **lisp**: Argument type checks in `CellReader` reads are inline, which makes typed builtins faster

## 2026-10-15: buildenv v0.1.37

- **General**: Rebuild on current base images and packages.

## 2026-10-15: elps v1.79.0

- **json**: New durable sharing query and `LEnv.CheckClosure` check that a saved value graph and its closures can be restored
- **json**: Fix: a durable array of rank 0 loads as rank 0
- **elps**: Dependency updates

## 2026-10-12: buildenv v0.1.36

- **General**: Rebuild on current base images and packages.

## 2026-10-10: buildenv v0.1.35

- **build-godynamic**, **build-js**: Security: Azure CLI 2.91.0. In build-godynamic it brings cryptography 50.0.2, which fixes CVE-2026-69247, CVE-2026-69248 and CVE-2026-69249
- **build-api**, **build-go**, **build-go-alpine**, **build-godynamic**, **build-java**: Security: build the bundled Go tools with golang.org/x/net 0.60.0 (CVE-2026-78663, CVE-2026-78659, CVE-2026-78660, CVE-2026-78669)

## 2026-10-10: elps v1.78.0

- **lisp**: **Upgrade note:** `handler-bind` now runs the most specific matching handler first. Before, it ran the first binding that matched. Run the new `handler-order` lint check to find code that behaves differently
- **lisp**: New `argument-error` condition, a child of `error`. A `handler-bind` on `error` still catches it
- **lisp**: New `define-condition` defines your own conditions. New `condition-is?` tests a condition against a type and its ancestors
- **lisp**: New `rethrow :context` and `error-message` wrap an error with context, in the style of Go's `%w`. To give a wrapped error a different type, raise it explicitly
- **lint**: New `handler-order` check warns when a `handler-bind` binding comes after a binding for its own type or an ancestor

Details: [elps v1.78.0 release](https://github.com/luthersystems/elps/releases/tag/v1.78.0).

## 2026-10-10: elps v1.77.0

- **lisp**: **Upgrade note:** the Go methods `LVal.MapGet`, `LVal.MapGetLVal` and `LVal.MapGetString` are removed. Use `lisp.AsMap` and then `lisp.Lookup[T](m, key)`. A missing key returns `ok=false` instead of an error value
- **lisp**: New Go helpers for builtins in `(value, error)` form: `FuncE`, `Func1E`, `Func2E`, `Func3E`, `Text`, `ArgReader` and `Cells`, with `Result`, `ConditionOf`, `ResultAs` and `Name`
- **lisp**: New map, sequence and array helpers: `MapView`, `AsMap`, `Lookup[T]`, `MapOf`, `SortedMapOf`, `MapPut`, `MapLookup`, `All`, `Keys`, `SeqCells`, `StringList`, `ArrayParts`, `SetArrayData` and `SetArrayCells`
- **lisp**: `LVal.IsError` and `LVal.IsSymbol` return false for a nil `*LVal`
- **elps**: Security: build with Go 1.26.9 and `golang.org/x/net` v0.60.0, which fix GO-2026-6617 in `net/http`
- **docs**: API compatibility covers tagged releases only

Details: [elps v1.77.0 release](https://github.com/luthersystems/elps/releases/tag/v1.77.0).

## 2026-10-09: buildenv v0.1.34

- **build-api**, **build-go**, **build-go-alpine**, **build-godynamic**: Security: build gotestsum and golangci-lint with golang.org/x/text 0.41.0 (CVE-2026-56851)

## 2026-10-09: buildenv v0.1.33

- **General**: Security: Go 1.26.9. It fixes `html/template` (GO-2026-6599, GO-2026-6600) and `net/http` (GO-2026-6617)
- **nginx-frontend**: Move the base to nginx 1.30 on Alpine 3.24. Security: this fixes tiff (CVE-2026-4775)
- **build-godynamic**, **nginx-frontend**: Security: libexpat 2.9.0 (CVE-2026-102633, CVE-2026-77214)

## 2026-10-09: elps v1.76.0

- **json**: New durable codec values (`libjson.DurableCodec[T]`) and `NewFrozenDurableRegistry` let an embedder save and restore its own native values in a durable dump
- **regexp**: A durable dump saves compiled regexps
- **elpsvet**: New `elpsdurablenative` analyzer requires each native payload type to have a durable codec or a transient mark. `elpsnativepayload` moves to the importable `elpsvet/nativepayload` package
- **docs**: The thread-first macro-step regression is listed as a known issue. See [Known issue: thread-first and thread-last refuse macro steps](known-issues.md#thread-first-and-thread-last-refuse-macro-steps)

## 2026-10-07: substrate v2.247.0

- **shiroclient**: **Upgrade note:** writes stop when the license expires. Reads continue until the license grace period ends. Before, writes also continued until the grace period ended
- **shiroclient**: The gateway restarts while the license metrics server is down. When the license does not allow reads and the server sends no answer (transport error, timeout, 429 or 5xx), the gateway serves reads and writes for 2 hours, then reads only for 7 more days. A renewal or an answer from the server ends the window. Gauges: `luther_license_startup_grace` and `luther_license_startup_grace_writes`
- **shiroclient**: New optional setting `SHIROCLIENT_LICENSE_STATE_DIR` names a writable directory. The gateway stores each renewed license there and uses it at start-up when it is valid longer than the license file. Use a volume that survives a restart
- **shiroclient**: Security: a renewed license that does not decode or verify never replaces a valid installed license, and a failed install leaves the gateway refusing requests, never unlicensed
- **shiroclient**: At start-up the gateway waits at most 10 s for a renewal, and only when the license expires within 7 days. Demo mode does not wait
- **shiroclient**: The gateway reads at most 1 MiB of a metrics server answer, and stops a usage report when its context ends

## 2026-10-07: buildenv v0.1.32

- **General**: Rebuild on current base images and packages.

## 2026-10-06: hyphae v1.1.0

One hyphae tag publishes the `luthersystems/pdfserv` and `luthersystems/martin` images.

- **pdfserv**: **Upgrade note:** `luthersystems/pdfserv:latest` now renders with headless Chrome instead of QtWebKit (wkhtmltopdf). Pin `luthersystems/pdfserv:v1.0.0` until you check your documents with v1.1.0. To roll back, deploy the prior image tag
- **pdfserv**: The API does not change. `/pdfserv.PDF/Generate`, `/pdfserv.PDF/HealthCheck`, the base64 fields and all render flags stay the same
- **pdfserv**: Layout can change. A4 margins are physical millimetres (server defaults 10/10/20/10 mm). DPI has no effect on layout. Page breaks and table splits can occur in different places than with QtWebKit
- **pdfserv**: New limits: one active render, 16 queued, 30 s per request including queue time, 3 MiB decoded HTML and 16 MiB PDF. Set the client gRPC receive limit to about 22.4 MB or more for the base64 PDF
- **pdfserv**: Deploy with `pdfserv/deploy/deployment.yaml`: UID 65532, read-only root filesystem, no capabilities and 256 MiB `/dev/shm`. Request 512 MiB memory and 1 CPU, with limits of 4 GiB and 2 CPU. Readiness on `:9603/readyz` now checks browser capacity
- **pdfserv**: Security: pdfserv fetches assets only from public HTTP and HTTPS addresses on ports 80 and 443. Add internal ranges to deny with `extra-denied-cidrs`
- **martin**: New `run --parallel N` option (default 1) runs up to N per-file invocations at the same time. Output, JSON and JUnit reports and exit status are the same as with `--parallel 1`. Use it only for files that do not depend on each other's server-side effects
- **martin**: Security: new opt-in `run --deny-private-networks` option refuses connections to loopback, private, CGNAT, link-local (including 169.254.169.254) and other reserved ranges. It also checks redirects and proxies. `--deny-cidr CIDR` adds ranges. It is off by default
- **martin**: CI tests the image on arm64 and amd64 before each release

Details: [hyphae v1.1.0 release](https://github.com/luthersystems/hyphae/releases/tag/v1.1.0).

## 2026-10-06: substrate v2.246.0

- **substrate**: **Upgrade note:** upgrade every peer of a channel together. A range query that reaches its end now makes one more, empty query, so the read set of such a transaction changes
- **substrate**: Fix: a `thread-first` or `thread-last` step whose head is a macro or special operator, such as `default`, `when`, `and` or `or`, works again. See [Known issue: thread-first and thread-last refuse macro steps](known-issues.md#thread-first-and-thread-last-refuse-macro-steps)
- **substrate**: A range query continues across pages when a peer limits the rows that one query returns, so the peer's limit cannot hide rows
- **substrate**: Bump ELPS to v1.75.3

## 2026-10-06: elps v1.75.3

- **lisp**: Fix: `thread-first` and `thread-last` accept a step whose head is a macro or special operator, such as `default`, `when`, `and` or `or`. A macro step gets the value as a quoted datum, and `nil` stays `nil`. See [Known issue: thread-first and thread-last refuse macro steps](known-issues.md#thread-first-and-thread-last-refuse-macro-steps)
- **lisp**: `eval` recovers from a panic in its own frame

## 2026-10-05: substrate v2.245.0

- **substrate**: **Upgrade note:** this release changes transaction results for some phyla, so upgrade every peer of a channel together. Run `shirotester lint` and `shirotester preheat-check` on each phylum before you upgrade
- **substrate**: **Known issue:** a `thread-first` or `thread-last` step whose head is a macro or special operator, such as `default`, fails. See [Known issue: thread-first and thread-last refuse macro steps](known-issues.md#thread-first-and-thread-last-refuse-macro-steps)
- **substrate**: `utils:set-index-prefixes` takes keyword arguments: `(utils:set-index-prefixes :bimap b :counter c :page p)`. `shirotester lint` reports a positional call
- **substrate**: New opt-in guard `SUBSTRATE_FORBID_CORE_REBIND=true` fails the load of a phylum that rebinds a symbol of a core package, such as `statedb:get`. The new `core-rebind` lint check reports these rebinds in source. Set the guard uniformly across a channel's peers
- **substrate**: The `handlebars` package uses a deterministic engine with limits on template size, depth, output size and steps. Results match the previous engine except for documented edge cases, and each render costs more ELPS steps. `(handlebars:render tpl ctx :strict true)` turns on strict mode
- **substrate**: The core storage functions (`statedb:get`, `statedb:put`, the `cc:storage-*` functions, `utils:join-index-cols` and `validations:validate-not-nil`) and the router's internals run in Go. Responses, read sets and write sets do not change. ELPS step counts change, so size `SUBSTRATE_ELPS_MAX_STEPS` from measurements on this version if you set it. The router ignores a phylum's rebinding of these functions
- **substrate**: `cc:load-chaincode` is removed. Substrate loads phylum archives itself, with limits on archive size
- **substrate**: `cc:bptree-open` takes keyword arguments, such as `(cc:bptree-open :prefix "p" :compare my-cmp)`. `cc:storage-metrics` returns a sorted map; read a counter with `get`
- **substrate**: `cc:sleep` is available only in tests. A phylum that calls it at run time fails, and `shirotester lint` reports each call
- **substrate**: `utils:memoize-wrap` keys its cache by value and type, so `1` and `1.0` are separate entries. `SUBSTRATE_LEGACY_MEMO_KEYS=true` restores the old key; set it uniformly across a channel's peers
- **substrate**: The optional unique-key limit also counts rich-query rows and paginated range rows
- **substrate**: New opt-in `SUBSTRATE_VERIFY_AUTH_CLAIMS=true` verifies the auth token signature before the router records `txIssuerEmail`. The keys come from `SUBSTRATE_AUTH_CLAIMS_JWKS`, a JWKS document in config
- **substrate**: A cancelled request fails and commits nothing. The new `--request-timeout` setting (`CHAINCODE_REQUEST_TIMEOUT`, off by default) ends a request that runs too long; set it above the peer's `chaincode.executetimeout`
- **substrate**: Each request logs its ELPS step count, the step limit and its storage counters in one `elps steps` log line
- **substrate**: Init logs the warning `init installed no phylum` when it installs no phylum, and fails on an unexpected response
- **connector**: A connector event's `idempotency_key` reaches the callback's context
- **shiroclient**: `SHIROCLIENT_METRICS_URL` overrides the license metrics endpoint
- **substrate**: `shirotester unit-tests` loads a test file's shared helpers once per file instead of once per test
- **substrate**: Security: `cc-fetchurl:fetchurl` refuses metadata, link-local, loopback and private network destinations with a catchable error
- **substrate**: Security: mock mode and the debug REPL load phylum files only from inside the phylum root
- **substrate**: Security: update the OpenTelemetry trace exporters to v1.46.0 (GO-2026-6505)
- **substrate**: Private data `put-hashed` and `get-hashed` reject a key that is not a string, and a B+ tree flush writes its nodes in key order
- **substrate**: Bump ELPS to v1.75.2 (via v1.72.0 to v1.75.1) and svc to v0.19.0

## 2026-10-05: elps v1.75.2

- **analysis**: A bare file (one without `in-package`) is analyzed in the package of the file that loads it, also when load paths are relative

## 2026-10-05: elps v1.75.1

- **json**: `json:dump-bytes` and the other walks of native Go maps visit entries in key-name order, so the same input gives the same error on every run. Output of a successful encode does not change

## 2026-10-04: hyphae v1.0.0

- **martin**: **Upgrade note:** `luthersystems/martin:latest` now runs collections with a Go engine and an embedded JavaScript sandbox. Node and Newman are not used, and there is no Newman fallback. Pin your previous Martin image tag with `MARTIN_VERSION` until you finish upgrade tests
- **martin**: Run `martin vet` before you upgrade. It checks collections, `--pre` files and scripts for features that the new engine does not support, and exits 1 when it finds one. It does not send requests or run scripts. A clean result does not replace a test run
- **martin**: `run` validates all files before it sends a request. An unsupported feature or a load error in any file stops the whole run, also with `--bail=false`. Setup errors, unsupported features and cancellation exit 1
- **martin**: Supported in scripts: `pm.test`, `pm.expect` (Chai 4.4.1), scoped variables, response JSON, text and headers, lodash 4, UUID, `atob` and `btoa`, and timers. Supported in HTTP: raw and multipart bodies, uploads, cookies, redirects, gzip, deflate and Brotli
- **martin**: Unsupported script APIs fail the test, also when the script catches the error. These include `pm.sendRequest`, request changes, cookies in scripts, async `pm.test(done)` and `Intl`
- **martin**: `--iterations` defaults to 0. With more than one file, each file runs once, then the combined collection runs `--iterations` times. With 0, the combined run executes no requests. `--batch-run` (`-r`) runs only the combined collection
- **martin**: A run of one file with `--bail=false` exits 0 for test failures, as before. The reports still show the failures
- **martin**: The image base is Alpine 3.24.2, pinned by digest

Details: [hyphae v1.0.0 release](https://github.com/luthersystems/hyphae/releases/tag/v1.0.0).

## 2026-10-04: elps v1.75.0

- **json**: Durable typed JSON saves value graphs. It keeps shared lists and arrays as views, keeps program literals literal and saves error values and closures (only the names a closure reads)
- **lisp**: New builtin registry. Builtins are looked up by identity, and new `builtin` and `builtin-name` functions read the registry. Durable JSON writes a registered builtin as `~#builtin`
- **lisp**: New `CapturedNames` returns the names that a lambda's frames bind. Vector capacity is now part of the language
- **json**: `json:dump-*` bounds, meters and converts native values once

## 2026-10-02: buildenv v0.1.31

- **build-godynamic**: Security: the published OpenVEX document marks CVE-2026-97689 and CVE-2026-97687 as not affecting the image. They are in the urllib3 copy that pip vendors, which fetches only from the configured package index. The Azure CLI uses urllib3 2.8.0

## 2026-10-02: buildenv v0.1.30

- **General**: Rebuild on current base images and packages.

## 2026-10-02: elps v1.74.0

- **lisp**: **Upgrade note:** `lisp.ArgDecoder` is now a struct, so typed builtins decode arguments without a heap allocation. The constructors `ValueArg`, `TypedArg` and `StringArg` do not change. Wrap a decoder written as a plain function in `lisp.CustomArg`
- **json**: New canonical typed JSON in the `json` package. `json:canonize` is faster
- **lisp**: New value settings on `Runtime`
- **analysis**: The macro expansion cache is keyed by package and carries an expanded `in-package` forward

## 2026-09-30: buildenv v0.1.29

- **General**: Rebuild on current base images and packages.

## 2026-09-30: elps v1.73.0

- **time**: **Upgrade note:** `time:sleep`, `time:utc-now` and `time:time-elapsed` are removed, and so are the Go functions `libtime.BuiltinUTCNow` and `libtime.BuiltinElapsed`. The standard library is now deterministic. The host supplies the time (in substrate, `cc:now`). Use `time:time-from` with a host timestamp
- **lisp**: **Upgrade note:** library builtins run in their own package. `help`, `test`, `benchmark` and the test-let forms are now core `lisp` forms. `s:deftype` is removed from the schema library
- **lisp**: New Go toolkit for builtins: `BuiltinFunc`, `LEnv.CallBuiltin`, `LEnv.CallGlobal`, `BindBuiltins`, `ExtendPackage`, `ArgReader`, `Func1` to `Func4`, `MapRange`, `FreeKeywords`, `elpsutil.Template` for Go macros, `LEnv.ErrorfAt` and `NewGenSyms`
- **lisp**: New `macroexpand-all`. Analysis, lint and the LSP share one code walker and scope resolver
- **lint**: New `loop-variable-capture`, `test-outside-test-file` and `removed-builtin` checks. LSP hover shows the variables that a lambda captures
- **lisp**: Template VMs no longer copy per-package slot storage on every fork

Details: [elps v1.73.0 release](https://github.com/luthersystems/elps/releases/tag/v1.73.0).

## 2026-09-29: buildenv v0.1.28

- **General**: Rebuild on current base images and packages.

## 2026-09-28: substrate v2.244.0

- **substrate**: **Upgrade note:** unit tests now run with the same stack limit as peers, so a test that recursed deeper than a peer allows now fails, as the same code would on a peer
- **substrate**: `shirotester unit-tests` runs much faster: each test starts from a prepared copy of the loaded phylum instead of rebuilding it, and parsed sources are reused between tests. Run `shirotester preheat-check` to confirm your phylum can use this fast path
- **substrate**: The `SUBSTRATE_ALLOW_LEGACY_KEYWORD_FORMALS` setting now also applies to unit tests
- **substrate**: New `SUBSTRATE_DISABLE_TEST_TEMPLATE=true` setting forces unit tests back to building a fresh environment for every test

## 2026-09-28: substrate v2.243.2

- **substrate**: Release pipeline hardening; no runtime changes. Upgrading from v2.243.0 is optional

## 2026-09-28: substrate v2.243.1

- **substrate**: Release pipeline change; no runtime changes. Upgrading from v2.243.0 is optional

## 2026-09-28: elps v1.72.0

- **lisp**: Sorted maps accept integer keys. JSON handles an integer key and a string key that collide
- **lisp**: New `error-stack` builtin reads the call stack of a handled error. The `rethrow-context` lint check covers it
- **lisp**: **Upgrade note:** the Go type `LQSymbol` and the constructor `QSymbol` are removed
- **schema**: Constraint arguments are evaluated once, not twice
- **lisp**: The load cache computes the key digest once for repeated identical sources (bounded to 16 MiB)
- **elpspath**: Iterator work over shared documents is charged in steps and checks for cancellation. libjson `GoValue` and debugger step-in walks no longer blow up on heavily shared structures

## 2026-09-27: substrate v2.243.0

- **substrate**: **Upgrade note:** rolling upgrades from v2.241.0 or v2.242.0 are supported; peers can run different versions while you upgrade, because read sets, write sets and responses are unchanged. Two exceptions, neither used by a typical phylum: if you have set the optional `SUBSTRATE_ELPS_MAX_STEPS` limit, upgrade every peer together and size the limit from measurements taken on this version (ELPS step counts can differ from v2.241.0 on some request paths); and see the v2.242.0 note on removed symbols
- **substrate**: A newly installed or updated phylum version is prepared in the background as soon as the install succeeds, so the first transactions on the new version no longer pay its load cost. The latest phylum version is kept ready independently of the cache of older versions, and which version "latest" resolves to never depends on what a peer has cached
- **substrate**: New optional per-transaction limit on the number of distinct ledger keys a transaction touches, off by default. When enabled and exceeded, the transaction fails with JSON-RPC error code `-32003` ("unique key limit exceeded") and its writes are not committed; phylum install/update and context migrations run under a much larger fixed cap. `SUBSTRATE_DISABLE_KEY_LIMIT_OVERRIDE=true` switches the limit off as an emergency override
- **substrate**: The `removed-router-symbol` lint warning names v2.242.0 as the release that removed the router symbols it reports

## 2026-09-27: substrate v2.242.0

- **substrate**: **Upgrade note:** rolling upgrades from v2.241.0 are supported; read sets, write sets and responses are unchanged. Two exceptions, neither used by a typical phylum: if you have set the optional `SUBSTRATE_ELPS_MAX_STEPS` limit, upgrade every peer together (ELPS step counts can differ on some request paths); and if your phylum calls an internal router symbol removed in this release, or `utils:deduplicate-list` / `utils:deduplicate-vector`, update the phylum before upgrading. `shirotester lint` reports removed router symbols with the `removed-router-symbol` check
- **substrate**: Request routing and dispatch now run in Go before any phylum code: each request is validated once, its phylum version resolved, and it runs exactly once in the right VM, with no retry. Batch handling, error responses and request metadata moved from the Lisp router to Go. The `removed-router-symbol` lint warning now also reports the router symbols this removed, including `router:request-schema`
- **substrate**: `SUBSTRATE_ELPS_MAX_STEPS=N` now enforces a per-transaction step budget of `N` steps (in addition to `off` and `measure`). A transaction over budget fails with JSON-RPC error code `-32001` ("Step budget exceeded") and is not committed. Phylum install/update requests are charged their full load, so size `N` above an update of your phylum. Storage builtins charge steps by value size, and set the limit uniformly across every peer
- **substrate**: Bump ELPS to v1.71.0 (via v1.70.0). Shared Lisp test helpers in `*_testhelpers.lisp` files are loaded before each `*_test.lisp` file in the same directory
- **substrate**: Native `utils:deduplicate` and `cc:incr-key` for faster execution (`utils:deduplicate-list` and `utils:deduplicate-vector` were removed; use `utils:deduplicate`), and the chaincode sizes its Go memory limit from the container memory limit
- **substrate**: New connector helpers `mk-event` and `parse-resp`, and connector registration is now preheatable
- **substrate**: Built with Go 1.26.6

## 2026-09-27: elps v1.71.0

- **lisp**: `set!` resolves package-qualified symbols
- **elpstest**: The test runner loads shared `*_testhelpers.lisp` files before each test file
- **mcp**: The MCP server describes its tool parameters

## 2026-09-26: substrate v2.241.0

- **substrate**: ⚠️ **Upgrade note carried from v2.239.0:** `router:phylum-version-loaded` was removed in v2.239.0. A phylum that still reads it must call `(router:loaded-phylum-version)` instead. `shirotester lint` now reports every remaining reference with the new `removed-router-symbol` check, naming the replacement, so run it over your phylum before upgrading
- **substrate**: New `SUBSTRATE_ELPS_MAX_STEPS=measure` setting records how many ELPS evaluation steps each transaction takes, as the `substrate_tx_elps_steps` metric (by method), an `elps_steps` log field and a trace span attribute. It is the first phase of a per-transaction step budget; only `off` (the default) and `measure` are accepted, and a numeric limit is refused at startup rather than silently ignored. A new CI gate checks that every repository phylum counts identical steps on a cold VM and a template VM, a precondition for enforcing a budget consistently across peers
- **substrate**: Native storage and B+tree builtins that walk an unbounded number of records now charge one step per record or tree node, so the step count reflects their real work

## 2026-09-26: substrate v2.240.0

- **substrate**: A request that returns a failure never commits its writes. The new `write-then-failure` lint warning flags an endpoint that writes and can then return a failure
- **substrate**: JSON-RPC batch requests, served by shiroclient's new `CallBatch` and by the local test plugin's `CallBatch` and `QueryBatch`
- **substrate**: Bump ELPS to v1.69.0 (via v1.65.0–v1.68.0) — `when`, `unless`, `while` and `default` are now built-in special operators, so code using them runs faster, and the `string` package adds `has-prefix?`, `has-suffix?`, `contains?`, `trim-prefix` and `trim-suffix`. The formatter now indents a `while` body by two spaces; `shirotester fmt -l` lists files formatted the old way and `shirotester fmt -w` updates them (whitespace only)
- **substrate**: `utils:trim`, `triml`, `trimr` and `utils:string-trailer` are deprecated, with editor warnings naming the `string:` replacement (`string-trailer` does not check that the prefix is present; `string:trim-prefix` does)
- **substrate**: Faster native `blend-*`, `keep-only-field-mask!`, `deep-equal?` and `string-starts-with?` in `utils`, and a hardened compiled-schema cache that skips argument serialization when no schema applies
- **shiroclient**: Opt-in Fabric Gateway client mode, and in-flight requests are drained on SIGTERM/SIGINT instead of being cut off
- **substrate**: Published phylum templates are shared across servers in one process, and forked VMs are prewarmed with values earlier transactions used

## 2026-09-26: buildenv v0.1.27

- **General**: Rebuild on current base images and packages.

## 2026-09-26: elps v1.70.0

- **lisp**: Security: fix denial of service from values with heavy sharing (a small value that expands to a very large tree) in `equal?`, macro expansion, quasiquote, `elpspath` validation and copies, `GoValue` conversion and package admission
- **lisp**: One step budget now spans all top-level evaluations. Standard library builtins whose work grows with input size charge steps per KiB
- **json**: `json:dump-*` output is capped at `MaxAlloc` and stops on cancellation. `json:syntax-error` stays the error under `:string-numbers`
- **lisp**: Fix: `equal?` compares bytes and reader quotes by value
- **schema**: Fix: string booleans and NaN are refused, and `is-truthy` handles maps and bytes
- **lisp**: Faster argument binding for host functions, slice-backed lexical scopes and fewer allocations per call form

## 2026-09-25: substrate v2.239.0

- **substrate**: ⚠️ **Action may be required:** `router:phylum-version-loaded` is removed. Transaction state is no longer kept by rebinding package variables, so use `(router:loaded-phylum-version)` to read the version a transaction loaded. From v2.241.0, `shirotester lint` reports remaining references (`removed-router-symbol`)
- **substrate**: Template publication freezes every package the template holds, so VMs share package tables instead of copying them; a transaction-time write to a frozen package still works and copies only that package for that VM. `SUBSTRATE_DISABLE_FROZEN_PACKAGES=true` turns this off. The new `frozen-package-write` lint hint (info severity) flags such writes
- **substrate**: `SUBSTRATE_ALLOW_LEGACY_KEYWORD_FORMALS=true` temporarily restores the old positional binding of keyword-named formals (`(defun f (:a a) ...)`), which current ELPS refuses. The remedy is `&key`; `elps lint` reports affected definitions. Set it uniformly across a channel's peers
- **substrate**: Opt-in Fabric write batching behind `CHAINCODE_WRITE_BATCH`, new `substrate_preheat_template_cache_total` and `substrate_elps_package_thaw_total` metrics, and block sizes reported in license usage

## 2026-09-25: elps v1.69.0

- **string**: New `has-prefix?`, `has-suffix?`, `contains?`, `trim-prefix` and `trim-suffix` functions
- **lisp**: New `LEnv.ChargeSteps` lets native builtins charge evaluation steps

## 2026-09-25: elps v1.68.0

- **lisp**: `when`, `unless`, `while` and `default` are now special operators, so they cost no macro expansion. A package that defines or imports its own binding of these names keeps using it
- **docs**: The README is an introduction, and the user docs are reorganized

## 2026-09-25: elps v1.67.0

- **elps**: Maintenance release; no change to the language or library. Checked (`elpscheck`) builds no longer retain `Runtime` values, so they do not leak memory

## 2026-09-25: elps v1.66.0

- **json**: JSON loads decode directly to ELPS values, which makes `json:load` faster
- **lisp**: New typed Go helpers `MapGet`, `MapSet`, `GoSliceOf` and `GoMapOf`. The `interface{}` forms of `MapGet` and `MapSet` are deprecated

## 2026-09-24: buildenv v0.1.26

- **build-api**, **build-go**, **build-go-alpine**, **build-godynamic**: golangci-lint 2.13.2

## 2026-09-24: elps v1.65.0

- **lisp**: New `TemplateWithFrozenPackages`: template VMs share frozen package tables and copy a package only on its first write. `TemplateWithThawHook` observes these copies
- **lisp**: Template VMs build each binding on first use. `VMWithPrewarm` builds the values that earlier VMs used. `TemplateWithEagerInstantiation` restores the eager build
- **lisp**: New opt-in `lisp.WithLegacyKeywordFormals` restores the v1.61 positional binding of keyword parameter names. The default error and the `lambda-list` lint diagnostic point to `&key`
- **json**: JSON serializer modes are per-VM runtime settings

## 2026-09-23: substrate v2.238.0

- **substrate**: Bump ELPS to v1.64.0 (via v1.63.0), and `cc:is-valid-json?` caches compiled JSON schemas so repeated validation against the same schema is faster

## 2026-09-23: elps v1.64.0

- **schema**: Validator names come from the runtime symbol counter, so they do not depend on process history
- **elpsvet**: New `elpsbuiltinstate` analyzer reports builtins that write shared receiver, captured or package-level state

## 2026-09-23: elps v1.63.0

- **json**: JSON serializer modes are kept per VM, so concurrent environments do not share serialization state
- **json**: New `json:string-numbers?` reads the default string-numbers mode. `json:dump` encodes sorted maps without intermediate pair lists
- **lisp**: Function calls read the lambda body directly instead of allocating a new list

## 2026-09-22: substrate v2.237.0

- **substrate**: **Known issue:** from this release to v2.245.0, a `thread-first` or `thread-last` step whose head is a macro or special operator, such as `default`, fails. See [Known issue: thread-first and thread-last refuse macro steps](known-issues.md#thread-first-and-thread-last-refuse-macro-steps)
- **substrate**: Bump ELPS to v1.62.3 (via v1.62.0–v1.62.2) — allocation cuts throughout the evaluator: a walker allocation fix, a second round of per-call allocation cuts, and lazily created scope maps, direct map key access and a fast path for keyword arguments. Measured against ELPS v1.61.2 (8 interleaved rounds, benchstat): the shirocore suite is 3.3% faster with 7.2% fewer allocations, preheating is 6.2% faster with 10.2% fewer allocations, and `shirotester` runs are 5.4% faster with 9.4% fewer allocations. Builtin formals are now validated once at registration rather than on every call
- **substrate**: shirocore writes its literal `elpspath` selectors as v2 positional steps, so they parse nothing at call time — `utils:get-field-mask-paths` is 11.8% faster with 8.2% fewer allocations
- **substrate**: Transaction VMs are now built only from validated preheat templates, with isolation and ownership checks enforced, and production template parity and isolation checks run over the repository's phyla on every change, protecting against cross-transaction state leaks
- **substrate**: The debugger resolves ledger reads from each evaluation's own transaction context
- **substrate**: Security — update gRPC to the patched v1.83.2 (GHSA-2v4p-qf9q-27wj). Vulnerability scanning now also covers nested Go modules, such as the chaincode's bin-adapter, which previous scans did not reach

## 2026-09-22: buildenv v0.1.25

- **build-api**, **build-go**, **build-go-alpine**, **build-godynamic**: Security: build git-lfs, buf and go-swagger with golang.org/x/crypto 0.56.0 (CVE-2026-78662, CVE-2026-56855)
- **build-godynamic**, **build-java**: Security: build Docker Compose and the Docker CLI with gRPC-Go 1.83.2 (CVE-2026-84304, CVE-2026-84445)

## 2026-09-22: elps v1.62.3

- **lisp**: Faster evaluation: scope maps are created only when needed, map `Keys` is direct and keywords have a fast path

## 2026-09-22: elps v1.62.2

- **parser**: Fewer allocations for each token
- **lisp**: Fewer allocations on the evaluator's hot paths. A function bound twice reports its most recently bound name

## 2026-09-19: elps v1.62.1

- **lisp**: Builtin formals are validated when the builtin is registered, not on every call

## 2026-09-19: elps v1.62.0

- **lisp**: **Upgrade note:** behavior changes. Integer `pow` raises on overflow. `max` and `min` propagate NaN. Malformed lambda lists, keyword formals and invalid package names are errors at definition time. Lisp code cannot write core `lisp` package bindings. `json:null` encodes as `null`. `format-string` prints a depth marker instead of raising
- **lisp**: Known issue: `thread-first` and `thread-last` refuse a macro or special operator step in v1.62.0 to v1.75.2. See [Known issue: thread-first and thread-last refuse macro steps](known-issues.md#thread-first-and-thread-last-refuse-macro-steps)
- **lisp**: Runtime hardening. A `let*` initializer closure no longer sees later bindings. Native calls stop after a request is cancelled. Host panics are contained. Deep and cyclic values render with `#<depth-limit>` and `#<cycle>` markers. Error text is bounded
- **elps**: New `elps run --timeout` and `--max-steps` flags. Ctrl-C cancels evaluation and flushes output
- **lint**: New `let-recursion`, `lisp-package-seal`, `builtin-shadowing`, `lambda-list`, `duplicate-binding` and `duplicate-keyword` checks
- **formatter**: Long comments and shebang lines stay comments. Oversized tokens, malformed numbers and a UTF-8 BOM are reported. `elps fmt` no longer adds a space inside an identifier. The minifier renames a package-level name only when it can prove it is safe

Details: [elps v1.62.0 release](https://github.com/luthersystems/elps/releases/tag/v1.62.0).

## 2026-09-13: buildenv v0.1.24

- **General**: Rebuild on current base images and packages.

## 2026-09-10: elps v1.61.2

- **lint**: New `iteration-mutation` and `comparator-mutation` checks. Mutation checks treat quote forms and macro templates as data
- **lsp**: Fewer allocations in word lookup. Code actions, rename, document parsing and file reads on save respect the workspace size limit
- **lisp**: Fix: `copy` of a sorted map copies values in key order, and a failed copy fails as a whole

## 2026-09-09: buildenv v0.1.23

- **General**: Rebuild on current base images and packages.

## 2026-09-09: elps v1.61.1

- **lisp**: Template publication does less work and allocates less. Per-VM instantiation does not change

## 2026-09-08: elps v1.61.0

- **lisp**: **Upgrade note:** for Go embedders, `LEnv.Fork`, the shallow `LEnv.Copy`, `Template.Fork` and the old fork options are removed. Create a template with `lisp.NewTemplate` after initialization, then create each VM with `Template.NewVM`
- **lisp**: **Upgrade note:** regexp and time native values from the standard library are opaque. Use the library operations and `libtime.Time` or `libtime.Get` instead of a direct assertion to `*regexp.Regexp` or `time.Time`
- **lisp**: Templates load a program once and create independent VMs. Each VM gets private mutable state, and aliases, cycles and views are preserved
- **lisp**: New `lisplib.LoadRuntimeLibrary` loads the standard library for templates. Each VM gets its own testing registry
- **lisp**: Fewer allocations for maps, sequences, iterators and `string:join`

Details: [elps v1.61.0 release](https://github.com/luthersystems/elps/releases/tag/v1.61.0).

## 2026-09-02: buildenv v0.1.22

- **build-api**, **build-go**, **build-go-alpine**, **build-godynamic**: Security: build git-lfs and Docker Compose with golang.org/x/crypto 0.55.0 (CVE-2026-56854)

## 2026-09-01: substrate v2.236.0

- **substrate**: A context migration can no longer invoke another registered migration — the nested call now raises at the migration's entry point and names both migrations. Previously the rule was only documented, and a nested migration that hit cache silently made the outer fresh step look cached, so a transaction ran more steps than `max_fresh_steps_per_tx` allowed
- **substrate**: New `nested-migration` lint check in `shirotester lint` and the editor extension moves the same failure to authoring time — it flags a migration body that reaches `run-ctx-migrations`, `run-migration-to-completion` or the `ctx-migrations` registry, directly or through a helper in the same file. It is structural, so it runs identically with `--semantic=false` and no workspace; the runtime guard remains the complete check
- **substrate**: Bump ELPS to v1.58.0 — adds the `with-cleanup` special operator: `(with-cleanup (cleanup...) body...)` always runs the cleanup forms, whether the body returned normally or signalled, and returns the last body value without catching the error. `shirotester lint` gains the matching `with-cleanup-forms` check (a cleanup list that is empty or a bare symbol releases nothing), and `load-scope-context` now sees inside `with-cleanup`, which it previously skipped entirely
- **substrate**: Bump ELPS to v1.59.0 — the `shadowing` lint no longer reports a binding whose initialiser narrows the name it shadows, such as `(let* ([ctx (default ctx (sorted-map))])`, and its severity now follows what is hidden: shadowing a builtin, special operator, macro or function is a warning, shadowing another local stays informational
- **substrate**: Bump ELPS to v1.60.0 — `elpspath` gains `parse-path`, which converts a v1 string selector into the positional steps the v2 `?` family takes, so a path that arrives as data (a client request, a persisted envelope) is parsed once rather than on every call: `(apply ? (cons obj (parse-path sel)))`. Open-ended slices gain a positional spelling, `'(range n)` for `[n:]`. The selector parser is a new single-pass scanner, 67–90% faster on selector strings with fewer allocations and the same grammar and error messages; substrate's own copy of the v1 parser is retired in favour of it. The one grammar change is a strict widening: `.["a"]["b"]`, which the old parser rejected, now parses

## 2026-09-01: buildenv v0.1.21

- **General**: Rebuild on current base images and packages.

## 2026-09-01: elps v1.60.0

- **elpspath**: New `parse-path` converts a string path into the positional steps that the v2 `?` functions take: `(apply ? (cons obj (parse-path sel)))`
- **elpspath**: New open-ended range step `'(range n)` for `[n:]`
- **elpspath**: The selector parser is a new single-pass scanner. It is 67 to 90% faster with the same grammar and error messages. `.["a"]["b"]` now parses
- **elpspath**: Fix: path rendering prints a selector that parses again, and open-ended ranges print correctly

## 2026-08-29: elps v1.59.0

- **lint**: The `shadowing` check separates refining a function's own argument from hiding a builtin, which removes false positives

## 2026-08-27: substrate v2.235.0

- **substrate**: ⚠️ **Action may be required for phyla that use the `testing` package outside test files.** Production environments no longer load the `testing` package, so a phylum whose production load graph reaches it **at load scope** now fails to load with `unknown package: testing`. Three shapes trigger it: a top-level `(use-package 'testing)`, a top-level `(test ...)` / `(test-let ...)` registration, and a top-level qualified reference such as `(testing:assert-equal ...)`. The common, safe shape is unaffected — a `defun` whose *body* calls `assert-equal` still loads, because symbols in a function body resolve when it is called. The remedy is to move the offending file into the phylum's test-loaded set (a `*_test.lisp` file), which the test harness loads and production does not
- **substrate**: **The failure is not always loud, which is the part worth checking for.** Inside `handler-bind` or `ignore-errors` the load *succeeds* and silently skips the rest of the recovered body — no error, just missing behavior. `shirotester preheat-check` is the reliable detector: run it against your phylum directory or the deployment ZIP before upgrading
- **substrate**: Operators who need more time can set `SUBSTRATE_ALLOW_PHYLUM_TESTING_PACKAGE=true` on the chaincode container to restore the previous behavior while the phylum is migrated. It must be set uniformly across a channel's peers — with it off the affected phylum fails to load and with it on the phylum runs, so peers that disagree disagree about whether the phylum exists at all. Set it the same way wherever `shirotester preheat-check` runs, or a phylum can pass the check in CI and still fail to load on the peers; the check prints a `NOTE` naming the variable when it runs with the hatch on. See [Chaincode Environment Variables](common-operation-script/substrate/chaincode-environment-variables.md)
- **substrate**: `shirotester preheat-check` and the runtime's own template-refusal messages now name a line the phylum author can actually edit. A blocking context read reached through a wrapper or a macro previously reported only the position inside the library it bottomed out in — naming a file the phylum does not own, while the phylum's own line never appeared — and because the report de-duplicates on that position, two distinct blockers could merge into a single entry. Reports now read `read-position <- reaching-form`, and are unchanged for a read written directly at load scope
- **substrate**: Bump ELPS to v1.57.0 — native values carry typed construction and access contracts, and native payloads are checked against the runtime they belong to, closing a class of cross-transaction leak through environments served by forking a per-phylum template

## 2026-08-27: elps v1.58.0

- **lisp**: New `with-cleanup` special form runs cleanup forms on every exit path, including non-local exits. It does not mask an `internal-panic`
- **lint**: Functions can carry Go-style deprecation annotations, and lint reports calls to them
- **analyze**: SARIF rules have documentation, so alert pages are no longer blank

## 2026-08-26: substrate v2.234.0

- **substrate**: `blend-paths` now guarantees its write-through contract, pinned by tests: values at blended paths alias the source document (a write through the blend result at a blended path is visible in the source patch), the result is independent of the destination, and an empty path list returns the destination by identity. Restores behavior phyla depended on that regressed with the elpspath copy fix in v2.229.0 — the symptom was fields generated on the blend result (ids, timestamps) silently missing from the persisted patch after an update
- **substrate**: Leaning on the blend-paths write-through aliasing is deprecated for new code — write generated fields onto the source patch explicitly; the aliasing contract is retained for existing phyla
- **substrate**: New static vet gate rejects native payloads reaching a preheat template, preventing cross-transaction leaks through template-forked environments

## 2026-08-26: substrate v2.233.0

- **substrate**: Preparing a transaction's environment is dramatically cheaper — a warm VM is now produced by forking a per-phylum template snapshot instead of initializing from scratch, and the embedded core library is sealed once and shared by every fork rather than copied per environment. Together with the ELPS bump below, the allocations a single fork costs drop from roughly 37,000 to under 7,000 (−81%), so pools of preheated environments fill faster and hold less memory per VM
- **substrate**: Bump ELPS to v1.56.0 — array values no longer deep-copy dimensions they built themselves, forking no longer rebuilds per-environment metadata nothing reads, and the vector-building builtins moved onto the copy-free path, cutting two allocations from every constructed vector on the transaction path
- **substrate**: When a phylum cannot be preheated, the report is now trustworthy — `shirotester preheat-check` and the runtime's own template-refusal message name the innermost phylum source position of each blocking read rather than an internal frame, repeated reads of one capability no longer crowd distinct ones out of the list, and a report that had to truncate says so instead of silently dropping reads
- **substrate**: The `elpspath` v1 string-path builtins (`get-path`, `set-path!` and friends) are now marked deprecated in hover documentation and `shirotester doc`, each pointing at its v2 positional-arg equivalent, with a selector-to-step translation table in the package documentation. v1 continues to work — stored data and request payloads still carry v1 path strings — but new phylum code should use the v2 operations, which are several times faster and support dynamic paths naturally

## 2026-08-26: buildenv v0.1.20

- **General**: Rebuild on current base images and packages.

## 2026-08-26: elps v1.57.0

- **lisp**: `GoValue` returns the bytes of a bytes value instead of a bound method
- **lisp**: Native values have a complete clone protocol, typed accessors and runtime affinity

## 2026-08-26: elps v1.56.0

- **lisp**: Fewer allocations when builtins build vectors and arrays, and when template VMs are created

## 2026-08-25: substrate v2.232.0

- **substrate**: Context migrations pack by default again — following operator feedback on v2.230.0, a migration now fits as many fresh steps into each transaction as the storage budgets allow (the behavior before v2.230.0), so operators no longer need to know how many steps fit in order to get efficiently packed transactions. The per-transaction step cap is now the opt-in control: pass `shiroclient init --migration-tuning '{"max_fresh_steps_per_tx": N}'` (for example `1`) when the step rather than the budget should decide transaction chunking, such as tests that observe page boundaries. Cached replays remain free, and frontier resume and the exit-code contract are unchanged
- **substrate**: With packing as the default, size `shiroclient init -l` to the expected number of budget-sized transactions (typically small); a run tuned down with `max_fresh_steps_per_tx` needs `-l` near the total step count divided by that setting

## 2026-08-25: substrate v2.231.0

- **substrate**: Phylum loading is dramatically cheaper — the parse cache now hands every environment the same immutably sealed program instead of deep-copying it, removing ~44 ms, ~37 MiB and ~447,000 allocations from every cache hit, and the embedded core library is parsed once per process instead of once per environment, cutting warm-VM construction time by ~69% and its allocations by ~80%. Together these make pools of preheated environments substantially faster to fill and cheaper to hold
- **substrate**: New `shirotester preheat-check` command proves whether a phylum fully preheats — it loads the phylum (directory or deployment ZIP) against a probing transaction context and names the exact file and line of any load-scope context read that would silently stall background preheating
- **substrate**: New `load-scope-context` lint check (on by default) catches the same pattern statically — a transaction-context read at phylum load scope, such as reading the clock or ledger state at the top level of a file, is flagged at authoring time in `shirotester lint` and the editor extension, with the fix pattern named in the diagnostic
- **substrate**: Bump ELPS to v1.54.0 — adds the per-file load cache the parse-cache improvement above is built on, with sealed programs served safely across environments
- **substrate**: Operators who run a phylum that mutates its own quoted program literals (a pattern the sealed cache now rejects with `modify-literal-error`) can set `SUBSTRATE_ALLOW_PHYLUM_LITERAL_MUTATION=true` on the chaincode container to restore the previous behavior while the phylum is updated; the setting must be uniform across a channel's peers and announces itself in the process log — see [Chaincode Environment Variables](common-operation-script/substrate/chaincode-environment-variables.md) for the full list of settings available on the chaincode container

## 2026-08-25: substrate v2.230.0

- **substrate**: Context migrations now perform one fresh step per transaction by default — the batch size a migration chooses is its unit of work per transaction, making transaction sizing predictable and the batch size observable from the returned context; pack more steps per transaction for a single run with `shiroclient init --migration-tuning '{"max_fresh_steps_per_tx": N}'`, no phylum redeploy needed. Cached replays remain free and do not count against the limit
- **substrate**: Restarting a context migration now resumes in constant time — the engine records each migration's frontier and jumps straight to it, instead of re-reading the cached step history one entry at a time; long-running migrations no longer get slower to resume the further they have progressed, and a completed migration answers immediately on re-run
- **substrate**: `shiroclient init` exit codes now distinguish outcomes: `0` means the migrations completed, `3` means the iteration budget (`-l`) ran out with work remaining — progress is committed, re-run to continue, and the remaining context is logged as paste-ready JSON for `-m` — and `1` means a real failure, including a new detection for migrations making no progress between iterations. Size `-l` to the total step count divided by the steps-per-transaction setting
- **substrate**: New `utils:set-index-prefixes` builtin — the official override point for index key prefixes
- **substrate**: Phylum preheating hardening — each environment initializes from its own copy of the phylum, and abandoned initializations are cancelled instead of running to completion in the background
- **substrate**: Bump ELPS to v1.53.0 — adopts the sealed-AST series for faster program loading and safer reuse of parsed phylum code across environments

## 2026-08-25: elps v1.55.0

- **elps**: Maintenance release; no change to the language or library.

## 2026-08-25: elps v1.54.0

- **lisp**: New `Runtime.LoadCache` hook caches sealed parse results per file, so an embedder parses a repeated source once

## 2026-08-24: elps v1.53.0

- **json**: The JSON encoder allocates less
- **lisp**: `PackageRegistry.AddPackage` has an admission contract for each class of value

## 2026-08-24: elps v1.52.0

- **lisp**: Values are sealed: a program tree cannot change after construction, and values are copied on write
- **lisp**: A write through a sealed value raises a condition that you can catch
- **lisp**: New `copy` builtin. Template environments fork cheaply, and environments share builtin formals
- **lisp**: Fewer allocations when functions are defined and packages are imported

Details: [elps v1.52.0 release](https://github.com/luthersystems/elps/releases/tag/v1.52.0).

## 2026-08-22: buildenv v0.1.19

- **General**: Rebuild on current base images and packages.

## 2026-08-21: substrate v2.229.0

- **substrate**: The per-transaction key and write-byte metrics, previously last-write-wins gauges, are now histograms — `substrate_tx_keys_accessed` and `substrate_tx_bytes_written` give true per-endpoint distributions (p95s, threshold alerting via plain bucket queries) instead of whichever transaction finished last; the old gauges `substrate_tx_keys` / `substrate_tx_write_bytes` still work but are deprecated
- **substrate**: New `substrate_statedb_ops_total{method,op}` and `substrate_statedb_bytes_total{method,op}` counters expose the per-endpoint statedb breakdown — gets, puts, private-data access, range scans, and range pagination — so an endpoint's read/write/private mix is visible over time
- **substrate**: Sampled OpenTelemetry `Handle` spans now carry the full statedb breakdown (`statedb.*` counts and bytes) plus `luther.method`, `luther.req_id`, and `luther.tx.dirty` — a slow trace shows exactly what the transaction touched in state
- **substrate**: Breaking for dashboards pinned to specific `le` values — `substrate_tx_sim_dur` and `shirogateway_tx_dur` trimmed from 25 to 14 buckets (same 50ms low end, tail extends to ~15s), roughly halving the per-endpoint series cost of the two duration histograms
- **substrate**: ELPS phylum profiler spans now export through the server's own tracer rather than the process-global one — concurrent substrate instances (such as in-memory tests) no longer leak spans into each other's trace exporters
- **substrate**: elpspath hardening — `set-path`/`?set` copies no longer share nested containers with the source, and a value that contains itself is refused with a catchable error instead of crashing the chaincode process
- **substrate**: Bump ELPS to v1.50.0 — brings the tracer plumbing and container-aliasing fixes above into the ELPS runtime, with faster transaction evaluation on top
- **substrate**: The pvtdata sentinel private-data collection now defaults to `"private"`, with an explicit opt-out for deployments that relied on the previous default
- **substrate**: Clearer error when chaincode source fails to load — the message now names both failed interpretations (not a zip archive, not loadable lisp) instead of reporting only the zip failure
- **substrate**: Fix `cctime:sleep` to declare the same arguments as its implementation
- **substrate**: The benchmark regression gate is now statistically sound (both arms measured interleaved on the same runner) and a daily scheduled govulncheck run watches for vulnerable dependencies — catching performance and security regressions automatically

## 2026-08-21: elps v1.51.0

- **lisp**: Each environment gets fresh formals, so a function cannot change another environment's argument list
- **elpspath**: `?set` documents and enforces its value contract
- **lisp**: Panics that Lisp code can reach are classified and turned into errors

## 2026-08-20: buildenv v0.1.18

- **build-godynamic**: Security: build Docker Compose with moby/go-archive 0.3.3 (CVE-2026-17106)

## 2026-08-20: buildenv v0.1.17

- **General**: Rebuild on current base images and packages.

## 2026-08-20: buildenv v0.1.16

- **General**: Security: Go 1.26.6, with patched golang.org/x/net, x/mod, x/sys and x/crypto in the bundled Go tools
- **build-go**, **build-godynamic**, **build-java**: Security: build the Docker CLI 29.6.1 from source with Go 1.26.6, so it carries the Go security fixes
- **build-godynamic**: Security: the published OpenVEX document marks the setuptools and msgpack findings in pip's vendored packages as not affecting the image

## 2026-08-20: elps v1.50.0

- **json**: New `:exact-integers` option keeps JSON integers above 2^53 exact on load. `json:dump` refuses a native value that it cannot load back
- **lisp**: Fix: macro expansion, `copy` and sequence views no longer share or write through into their source. Walks of cyclic values are bounded, so they cannot crash the process
- **elpspath**: Fix: `?del!` no longer changes the source of a view, and copies of cyclic values are refused
- **lsp**: The server negotiates `positionEncoding`. Rename no longer corrupts non-ASCII identifiers
- **lint**: An unset severity shows as `warning`. Diagnostic carets line up in terminal cells
- **elpsutil**: Embedder mistakes return errors instead of panics, and loads restore the caller's package. Embedders can inject the profiler's tracer

## 2026-08-14: buildenv v0.1.15

- **build-godynamic**: Security: the published OpenVEX document marks CVE-2026-69248 and CVE-2026-69249 in the Azure CLI's cryptography 48.0.1 as not affecting the image. The Azure CLI does not call the affected X.509 verification API

## 2026-08-10: elps v1.49.0

- **lisp**: Evaluator recursion depth is bounded, in addition to call-stack frames
- **time**: `time:sleep` stops when the evaluation context ends and refuses a sleep longer than the time left
- **parser**: Both halves of a package-qualified symbol must be names. A bad string literal raises `invalid-string`
- **lisp**: Fixes from fuzz testing, including a `pow` that did not terminate, `equal?` on sorted maps, tail-call budgets and step limits
- **formatter**: A comment in column 0 stays in column 0
- **lsp**: Fix: a crash in call hierarchy

## 2026-08-07: buildenv v0.1.14

- **General**: Rebuild on current base images and packages.

## 2026-08-05: substrate v2.228.1

- **substrate**: Restore the npm trusted-publishing auth in the release pipeline so the `@luthersystems/shirotester` npm package publishes again for v2.228.x — no runtime changes over v2.228.0

## 2026-08-05: substrate v2.228.0

- **substrate**: Fix duplicate results from `statedb` union range queries — an unbounded range (`end=""`) in `statedb:range-page-union` / `range-page-bytes-union` was misclassified as disjoint from every other range, silently emitting duplicate keys; unbounded ends now count as overlapping and results are deduplicated
- **substrate**: Context migrations now run under per-transaction budgets (max keys, write bytes, and iterations per transaction, deletes counted) with a resumable pause at the cache frontier — large-dataset migrations no longer risk blowing Fabric transaction limits mid-run
- **substrate**: `statedb:range-page*` builtins are now legal in writing transactions — the page size is enforced client-side over a plain range iterator, since Fabric restricts shim-level pagination to read-only transactions
- **substrate**: New out-of-band migration tuning — pass `--migration-tuning '{"batch_size": 2000}'` to `shiroclient init` and read values in phylum via `utils:migration-tuning`; retune a paused migration between runs without redeploying the phylum or invalidating the migration's idempotency cache
- **substrate**: Unpaginated range queries now stream keys lazily instead of collecting the whole key range into memory up front — constant memory at any range size, closing an out-of-memory class for full-keyspace scans; paginated range builtins now reject a page size <= 0 with a clear error, and a new range-pagination metric exposes page-fetch behavior to operators
- **substrate**: The in-memory emulator now serves ranges from a true cursor (no more full-range materialization per page during tests), with mock/real range parity proven by one shared corpus and the full migration lifecycle exercised end-to-end on the sample network on every change

## 2026-08-05: buildenv v0.1.13

- **build-godynamic**: Security: the published OpenVEX document marks CVE-2026-69247 in the Azure CLI's cryptography 48.0.1 as not affecting the image. The Azure CLI does not decrypt PKCS#7 or S/MIME data

## 2026-08-04: substrate v2.227.0

- **substrate**: Security — bump `google.golang.org/grpc` to v1.83.0 (fixes GHSA-hrxh-6v49-42gf) along with OpenTelemetry transitive dependencies
- **substrate**: Security — refresh build and runtime base images to `buildenv v0.1.12`, picking up a year of Debian/Alpine base-image CVE fixes (expat and grpc HIGHs among others)
- **substrate**: Bump svc to v0.16.0 — completes the migration off the deprecated aws-sdk-go v1 to aws-sdk-go-v2 across S3 document storage, SES mail, and request archiving
- **substrate**: Bump shiroclient-sdk-go to v0.14.1 with the matching grpc security updates
- **substrate**: Known-vulnerability scanning (govulncheck) and Go-module Dependabot now run on every change, catching vulnerable-dependency regressions of the above class automatically

## 2026-08-04: Luther Auth v4.8.1

- **General**: Security: rebuild on buildenv v0.1.12 base images, with fixes for Debian and Alpine CVEs, and update gRPC to v1.83.0 (GHSA-hrxh-6v49-42gf) and golang-jwt v4 to v4.5.2
- **General**: The magic link KMS cookie client uses the AWS SDK for Go v2. It makes the same KMS calls with the same IAM permissions, and existing cookies decrypt as before. The deprecated AWS SDK for Go v1 is no longer a dependency
- **General**: Bump svc to v0.16.0 and upgrade Go dependencies

## 2026-08-04: elps v1.48.2

- **mcp**: Fix: the MCP server no longer races at shutdown
- **elps**: Dependency updates, including `golang.org/x/crypto` v0.52.0 and `golang.org/x/net` v0.55.0

## 2026-07-31: buildenv v0.1.12

- **General**: Rebuild on current base images and packages.

## 2026-07-25: buildenv v0.1.11

- **build-godynamic**: Security: build Docker Compose with gRPC-Go 1.82.1 (GHSA-hrxh-6v49-42gf)

## 2026-07-16: Luther Auth v4.8.0

- **General**: New optional setting `AUTH_JWT_SIGN_KEY_PREVIOUS` (same PEM format as the signing key) rotates the JWT signing key without an outage. The JWKS endpoint serves the public keys of the current and the previous key. New tokens are signed with the current key only
- **General**: Startup fails when `AUTH_JWT_SIGN_KEY_PREVIOUS` does not parse, or when it is set and JWKS is off. Startup logs the key ID of each loaded key, never key material

## 2026-07-12: buildenv v0.1.10

- **General**: Rebuild on current base images and packages.

## 2026-07-02: buildenv v0.1.9

- **General**: Rebuild on current base images and packages.

## 2026-07-01: buildenv v0.1.8

- **General**: Rebuild on current base images and packages.

## 2026-06-30: buildenv v0.1.7

- **build-go**, **build-godynamic**, **build-java**, **build-js**, **build-swaggercodegen**, **build-e2e**: **Upgrade note:** the default user is the non-root user `build`. With `docker run`, pass `-u` to choose a user. A Dockerfile that builds `FROM` one of these images and needs root must set `USER root`
- **build-java**, **build-js**, **build-swaggercodegen**: Upgrade the OS packages at build time to take the latest security fixes
- **build-go**, **build-godynamic**: Docker CLI 29.6.1

## 2026-06-30: buildenv v0.1.6

- **General**: Rebuild on current base images and packages.

## 2026-06-23: substrate v2.226.0

- **substrate**: Phylum preheat/init timeout is now configurable (default unchanged at 6s) — set it with the `--preheat-timeout` chaincode flag, the `shiro.WithPreheatTimeout` server option, or the shiroclient SDK's `mock.WithPreheatTimeout` (sdk-go v0.14.0) for in-memory tests. Prevents spurious "phylum init timeout" errors when many environments initialize in parallel under heavy CPU load; the baseline preheater always keeps the built-in default, so a small value can't stall all traffic
- **substrate**: Add a guide for automated context migrations

## 2026-06-23: buildenv v0.1.5

- **build-api**, **build-go-alpine**: **Upgrade note:** the default user is the non-root user `build`. With `docker run`, pass `-u` to choose a user. A Dockerfile that builds `FROM` one of these images and needs root must set `USER root`, for example to write a root-owned cache mount at `/go/pkg/mod`
- **General**: Every published image carries an SBOM and SLSA provenance attestation for each platform

## 2026-06-23: buildenv v0.1.4

- **General**: Alpine 3.24
- **build-go-alpine**, **build-godynamic**: Security: jq 1.8.2 (CVE-2026-32316, CVE-2026-40164)
- **build-api**, **build-go**, **build-go-alpine**, **build-godynamic**: Security: build the bundled Go tools with patched golang.org/x/sys (CVE-2026-39824) and quic-go (CVE-2026-40898). `gotestsum --version` reports `(devel)`
- **build-go**, **build-godynamic**: Docker CLI 29.6.0. build-godynamic adds Docker Compose 5.2.0
- **build-godynamic**, **build-js**: Azure CLI 2.87.0 and AWS CLI 2.35.11

## 2026-06-23: buildenv v0.1.3

- **General**: Security: Go 1.26.4 (CVE-2026-42499, CVE-2026-39836, CVE-2026-39820, CVE-2026-33814, CVE-2026-33811, CVE-2026-42504)
- **build-api**: Security: upgrade the Debian packages at build time, and build golangci-lint from source with the image's Go
- **General**: git-lfs 3.7.1

## 2026-06-19: buildenv v0.1.2

- **build-e2e**: Add the full font set of the pdfserv image, so local PDF renders match the pdfserv service

## 2026-06-19: buildenv v0.1.1

- **build-e2e**: New image `luthersystems/build-e2e` (Ubuntu). It holds the tools to build and run Luther platform end-to-end tests without Docker-in-Docker: Go, Node.js 20, newman, martin, shirotester, pdfserv, substratehcp and wkhtmltopdf
- **build-e2e**: Add an SSH client, so `go mod download` can fetch private modules

## 2026-05-24: buildenv v0.1.0

- **build-go**, **build-godynamic**, **build-java**, **build-js**: **Upgrade note:** the images no longer hold the embedded `make static` build flow. The entrypoint is `tini --`. Build runtime images with a multi-stage Dockerfile that copies from the builder image
- **General**: AWS CLI 2.34.53

## 2026-05-14: substrate v2.225.2

- **substrate**: Phylum panics raised during background preheat initialization are now recovered and surfaced as errors instead of taking down the chaincode process

## 2026-05-14: substrate v2.225.1

- **substrate**: Bump ELPS to v1.48.1 — defensive nil-guards in error rendering eliminate a class of secondary crashes when formatting unusual error values

## 2026-05-14: substrate v2.225.0

- **substrate**: Recovered phylum panics now include a `Go stack trace (panic origin):` section in the error output, pinpointing the exact line that triggered the panic
- **substrate**: Fix structured logging on the first request to a freshly preheated phylum — error stacks emitted during preheat-interrupt handling now flow through the configured logger instead of stderr
- **substrate**: Bump ELPS to v1.48.0 — adds a singleton-mutation guard and the Go panic-stack capture feeding the above

## 2026-05-14: elps v1.48.1

- **lisp**: Error rendering does not panic on a malformed error value. Well-formed errors render the same. A log line reports each time a guard fires

## 2026-05-13: elps v1.48.0

- **lisp**: Fix: macro expansion no longer corrupts the shared `true` and `false` values for the whole process
- **lisp**: A recovered Go panic includes its stack. Schema validators no longer log `GetFunName BUG:` lines
- **lisp**: New `FunInPackage`, `MacroInPackage` and `SpecialOpInPackage` constructors bind a Go function to a package

## 2026-05-06: substrate v2.224.0

- **substrate**: Fix a phylum preheat data race that could cause an intermittent SIGSEGV under Go 1.26's new map implementation on first request to a newly loaded phylum
- **substrate**: Race-detector builds now run on every change, preventing regressions of the above class of bug

## 2026-05-05: elps v1.47.2

- **elps**: Fix: ELPS builds on Windows again, including `go install github.com/luthersystems/elps@latest`

## 2026-04-24: substrate v2.223.0

- **substrate**: Per-request debug logging now correctly promotes phylum `cc:debugf` calls to Info level when a sampled OpenTelemetry parent span is present on the transaction
- **substrate**: Fix OpenTelemetry trace propagation in in-memory / emulate-CC mode — spans now surface from transactions issued through `make mem-up` and sandbox-style test flows
- **substrate**: Refresh OpenTelemetry tracing documentation — covers the sampled-parent requirement, per-binary OTLP endpoint configuration, and the log-volume tradeoff when using per-request debug logging

## 2026-04-20: substrate v2.222.0

- **substrate**: Upgrade builds and CI to Go 1.26 via `buildenv v0.0.97`
- **substrate**: Fix chaincode Docker build defaults and `functionaltester` staticcheck findings for Go 1.26 release validation

## 2026-04-20: buildenv v0.0.98

- **General**: Security: Go 1.26.2 and Alpine 3.23
- **build-go-alpine**: Security: build golangci-lint from source with the image's Go

## 2026-04-20: buildenv v0.0.97

- **General**: Go 1.26.1, golangci-lint 2.11.4, buf 1.68.2 and go-swagger 0.33.2
- **General**: Security: upgrade the OS packages at build time in every image, including service-base-alpine and nginx-frontend

## 2026-04-15: substrate v2.221.0

- **substrate**: Distribute `shirotester` via npm (`npx @luthersystems/shirotester`) — zero-setup MCP server and CLI access for editors and AI coding tools
- **substrate**: Fix VS Code extension version injection so `shirotester version` reports the release version instead of `substrate-SNAPSHOT`
- **substrate**: SNAPSHOT tags now produce unique marketplace versions, removing VS Code extension publish collisions
- **substrate**: Security — bump lodash to 4.18.1 (prototype pollution and code injection fixes)

## 2026-04-09: substrate v2.220.0

- **substrate**: Bump ELPS to v1.47.1 with LSP metadata enrichment — richer diagnostic related-information, hover ranges, completion details, workspace symbol context
- **substrate**: Normalize file paths for symlink-safe duplicate-definition checks

## 2026-04-09: elps v1.47.1

- **lsp**: Richer symbol metadata and normalized file paths in the language server

## 2026-04-03: substrate v2.219.0

- **substrate**: Bump ELPS to v1.47.0 with macro expansion and analyzer fixes — workspace-defined macros expand at analysis time, MCP diagnostics perform cross-file symbol resolution
- **substrate**: Eliminate false positives for bare `else` in `cond`, quoted-symbol lambda `set`, and files without `in-package` (inherit from workspace `DefaultPackage`)

## 2026-04-03: elps v1.47.0

- **analysis**: Static analysis expands user macros, so symbols that macro templates introduce resolve correctly
- **analysis**: Workspace macros load in the same order as the runtime `load`
- **lint**: Fix: false positives for `cond` else clauses, `set`, `macrolet` and thread forms
- **mcp**: MCP diagnostics resolve symbols across files

## 2026-04-01: substrate v2.218.0

- **substrate**: Bump ELPS to v1.46.2 with quasiquote template reference tracking — cross-file references from quasiquote templates no longer flagged as unused
- **substrate**: Go-to-definition and completion now work for non-exported qualified symbols (`pkg:internal-fn`)

## 2026-04-01: elps v1.46.2

- **lint**: Fix: symbols in quasiquote templates count as references, and qualified symbols resolve against all definitions of a package

## 2026-03-31: elps v1.46.1

- **elps**: Maintenance release; no change to the language or library.

## 2026-03-28: substrate v2.217.0

- **substrate**: Bump ELPS to v1.46.0 with major LSP improvements — cross-file use-package resolution, load-tree package inference for bare files, cross-file unused-function detection
- **substrate**: Hover docs for `unquote`, `unquote-splicing`, `condition`, `&rest`, `&optional`, `&key`, `else`
- **substrate**: Unused variables and functions render with faded text (DiagnosticTag.Unnecessary); undefined symbols inside user-defined macro bodies lowered to warning severity
- **substrate**: Suppress parameter-shadows-builtin/special-op warnings for common parameter names (`expr`, `car`, `map`)

## 2026-03-28: elps v1.46.0

- **analysis**: A bare file gets its package from the `main.lisp` load tree. `use-package` resolves across files
- **lint**: Diagnostics have end positions, so editors go to the correct range. Unused functions are found across files. Shadowing warnings for parameters that shadow builtins are gone
- **lsp**: Hover shows documentation for language keywords

## 2026-03-27: substrate v2.216.0

- **substrate**: Skip `build/`, `_*` directories, and `shirocore.lisp` during workspace scanning — resolves "Workspace file limit reached" warning on large phylums
- **substrate**: Add `--exclude` and `--max-files` flags to `shirotester lsp` for custom workspace scan configuration

## 2026-03-27: elps v1.45.0

- **lint**: New `--include` flag limits analysis to listed directories. Workspace scans skip `build` and directories that start with `_`

## 2026-03-26: substrate v2.215.0

- **substrate**: Link VS Code extension version to substrate release tags (single source of truth for versions)
- **substrate**: Publish SNAPSHOT tags as VS Code marketplace pre-release extensions

## 2026-03-25: substrate v2.214.0

- **substrate**: Release the Substrate VS Code extension — syntax highlighting for ELPS with substrate-specific forms (`defendpoint`, `route-success`, `route-failure`), LSP via `shirotester lsp`, DAP debugger via `shirotester debug`, zero-dependency install with bundled `shirotester` binary
- **substrate**: Add `shirotester fmt` command for formatting ELPS source files
- **substrate**: Bump ELPS to v1.44.0 with preserve-params minifier — LSP now shows human-readable parameter names instead of minified identifiers

## 2026-03-25: elps v1.44.1

- **vscode**: The extension highlights the `#^` shorthand like `lambda`

## 2026-03-25: elps v1.44.0

- **minifier**: New `--preserve-params` flag keeps parameter names
- **vscode**: F5 starts a debug session without a `launch.json`
- **parser**: Quote, function reference and unbound forms take the location of their prefix token, which fixes inlay hint positions

## 2026-03-25: elps v1.43.0

- **vscode**: Platform-specific extension packages include the `elps` binary

## 2026-03-24: substrate v2.213.0

- **substrate**: Add `pvtdata_health_check` endpoint for private data reconciliation monitoring after snapshot restore
- **substrate**: Add `pvtdata_set_health_check_sentinel` endpoint for legacy chain sentinel configuration
- **substrate**: Auto-write default sentinel to `"private"` PDC on phylum init/update
- **substrate**: Add `docs/shirocore-endpoints.md` — comprehensive reference for all shirocore built-in endpoints
- **substrate**: Bump `google.golang.org/grpc` to v1.79.3 (critical CVE fix)

## 2026-03-24: elps v1.42.0

- **vscode**: The VS Code extension, published as `LutherSystems.elps-lang`, adds a language server client, a TextMate grammar and language configuration
- **lsp**: The language server loads the standard library and shows hover docs for special operators and imported symbols. Fix: the nolint code action uses the correct check name

## 2026-03-21: substrate v2.212.0

- **substrate**: Pin elps to v1.41.0 with MCP server improvements
- **substrate**: Add shirotester MCP tools: `eval`, `test`, `doc`, `format`, `lint`, `help`
- **substrate**: Wire `WithEnvFactory` into shirotester MCP for isolated shiro environments
- **substrate**: Fix 24 MCP server issues (path resolution, pagination, severity filtering, structured errors)

## 2026-03-21: substrate v2.211.0

- **substrate**: Bump ELPS to v1.40.0 with full LSP parity and `duplicate-definition` analyzer
- **substrate**: Add `shirotester analyze` command with substrate-aware performance analysis (PERF001-004)
- **substrate**: Embed ELPS MCP server in shirotester (`shirotester mcp`)
- **substrate**: Shirocore migration phases 8-9: remove ELPS wrappers, eliminate LVal overhead
- **substrate**: Bump Go to 1.25 across all CI workflows and build images
- **substrate**: Replace `prepare-shirocore.sh` with Go tool using elps minifier API

## 2026-03-21: elps v1.41.0

- **mcp**: The MCP server adds `format`, `lint`, `doc`, `test` and `eval` tools with structured errors

## 2026-03-21: elps v1.40.0

- **lint**: New `duplicate-definition` check. The LSP reports duplicate definitions across files
- **lsp**: Workspace indexing is more robust: file and document size limits, deterministic resolution and diagnostics that match the document version
- **lint**: `Excludes` applies to workspace scans

## 2026-03-20: buildenv v0.0.96

- **General**: Go 1.25.8 and Alpine 3.22
- **build-go**, **build-godynamic**, **build-java**, **build-js**: Fix `make static` image builds inside the containers. They use `docker build` again, because the containers do not have the buildx plugin

## 2026-03-18: substrate v2.210.0

- **substrate**: Add `shirotester analyze` command with SARIF, Mermaid, and baseline output formats
- **substrate**: Roll out shirotester analyze CI for automated analysis on PRs
- **substrate**: Add DAP debugger support with `shirotester debug` command
- **substrate**: Upgrade ELPS to v1.39.0 with full LSP + DAP integration
- **substrate**: Migrate deprecated ELPS eval calls to context-aware variants
- **substrate**: Add ELPS runtime documentation for 500+ symbols with CI gate

## 2026-03-17: elps v1.39.0

- **mcp**: New `elps mcp` command starts an MCP (Model Context Protocol) server for ELPS tools such as search, symbols and diagnostics

Details: [elps v1.39.0 release](https://github.com/luthersystems/elps/releases/tag/v1.39.0).

## 2026-03-13: elps v1.38.0

- **minifier**: Fix: minification keeps package-qualified, exported and macro-generated symbols correct, and respects package boundaries
- **minifier**: Embedders can register custom definition forms for analysis and minification

## 2026-03-13: elps v1.37.0

- **analyze**: Suppress a single rule in performance analysis. A cycle suppression on any member applies to the cycle

## 2026-03-13: elps v1.36.0

- **minifier**: New `elps minify` command renames identifiers with scope awareness and writes a symbol map
- **analyze**: `elps analyze` takes file excludes

## 2026-03-12: elps v1.35.0

- **analyze**: Performance analysis writes SARIF v2.1.0 and Mermaid output

## 2026-03-10: elps v1.34.0

- **analyze**: Performance analysis detects N+1 patterns, where a call inside a loop multiplies cost

## 2026-03-10: elps v1.33.0

- **analyze**: New `elps analyze` command finds performance problems from the call graph (rules PERF001 to PERF004)

## 2026-03-03: elps v1.32.0

- **elps**: New `elps doc --json` flag writes machine-readable documentation
- **lsp**: New selection range, linked editing, document highlight, inlay hints and watched-file support. Go to definition on a builtin opens a virtual document
- **debugger**: Debugger launch configuration is more robust and can skip builtins when stepping

## 2026-03-01: elps v1.31.0

- **lsp**: References, call hierarchy and rename work across files

## 2026-02-27: elps v1.30.0

- **lsp**: New code actions, folding ranges, semantic tokens, call hierarchy and workspace symbol search
- **debugger**: Change a variable's value while paused

## 2026-02-27: elps v1.29.1

- **lsp**: Fix: hover for some Go builtins, signature help for user functions and a crash in workspace indexing

## 2026-02-27: elps v1.29.0

- **elps**: New tree-sitter grammar for ELPS, with Go bindings
- **lsp**: Fix: hover and completion for package-qualified symbols

## 2026-02-27: elps v1.28.0

- **debugger**: The debug server has a built-in `/help` command

## 2026-02-27: elps v1.27.0

- **lsp**: Fix: hover, completion, diagnostics and duplicate results. Workspace scans include the root directory when the path is `.`

## 2026-02-26: elps v1.26.0

- **lsp**: New `elps lsp` command starts a Language Server Protocol server with diagnostics, hover, definition, references, completion, symbols, signature help and formatting
- **parser**: The parser recovers from errors, so the LSP can analyze incomplete code
- **debugger**: Embedders can add slash commands to the debug console

Details: [elps v1.26.0 release](https://github.com/luthersystems/elps/releases/tag/v1.26.0).

## 2026-02-26: elps v1.25.0

- **lisp**: Evaluation takes a Go `context.Context` and supports a step limit, so a host can cancel or bound a run
- **debugger**: Variables page through large values and filter sorted maps by regex. Step-into works at the expression level

## 2026-02-26: elps v1.24.1

- **debugger**: Fix: bare expressions in the debug REPL evaluate in the paused scope. A new debugging guide is available with `elps doc --debug-guide`

## 2026-02-26: elps v1.24.0

- **debugger**: New interactive debug REPL in the terminal

## 2026-02-26: elps v1.23.1

- **debugger**: The debug console completes names and shows their docstrings

## 2026-02-26: elps v1.23.0

- **debugger**: New line stepping, smart step-into targets, step-into for macro expansions and evaluation of more than one expression
- **debugger**: Embedders can add custom variable scopes
- **debugger**: Fix: the debugger respects the client's `stopOnEntry` setting, and file loads use the correct file name

## 2026-02-25: elps v1.22.0

- **debugger**: Lists, maps, arrays and native values expand in the variables pane. Embedders can format native values
- **debugger**: New hit count breakpoints, log points, watch expressions and function breakpoints. The VS Code extension can attach over TCP
- **debugger**: Fix: step-out from a function in tail position, and a deadlock when evaluating while paused
- **lisp**: Fix: a data race in `Package.Exports`

## 2026-02-24: elps v1.22.1

- **debugger**: New `SetSourceLibrary` method on the debugger engine for embedders

## 2026-02-23: elps v1.21.0

- **debugger**: New `elps debug` command starts a Debug Adapter Protocol (DAP) debugger over TCP or stdio. It works with VS Code, Neovim, Zed, JetBrains, Helix and Emacs
- **debugger**: Line, conditional and exception breakpoints, step into, over and out, variable inspection and evaluation while paused
- **debugger**: The debugger adds no overhead when it is not attached

Details: [elps v1.21.0 release](https://github.com/luthersystems/elps/releases/tag/v1.21.0).

## 2026-02-16: elps v1.20.0

- **elps**: **Upgrade note:** `elps run` and `elps repl` confine `load-file` to the working directory by default. Absolute paths and `..` are refused. Use `--root-dir` to set a different root
- **lisp**: Security: parser depth and macro expansion depth are limited, and allocation limits are enforced, so bad input cannot overflow the stack
- **lisp**: Go panics become errors. **Upgrade note:** the Go function `ErrorAssociate` returns `*LVal`
- **lisp**: Fix: sorted map copy and equality, and a symlink race in source loading

## 2026-02-13: elps v1.19.2

- **lisp**: Macros defined with `defmacro` carry docstrings. A documentation guide is available

## 2026-02-12: substrate v2.209.0

- **substrate**: Upgrade svc to v0.15.0
- **substrate**: Upgrade elps to v1.19.2 with inline macro docstrings
- **substrate**: Add ELPS runtime documentation for 477 symbols across 34 packages

## 2026-02-12: substrate v2.208.0

- **substrate**: Expose OpenTelemetry tracing spans in mock mode (substratehcp plugin)
- **substrate**: Enable per-request debug logging when tracing is active
- **substrate**: Add @trace annotations to router JSON-RPC deserialization functions
- **substrate**: Add elpspath v2 with positional-arg path operations
- **substrate**: Fix def-migration-ctx idempotency and add recursive execution
- **substrate**: Upgrade elps to v1.19.1 with semantic lint integration
- **substrate**: Add ELPS runtime docs for elpspath package and all builtins

## 2026-02-12: elps v1.19.1

- **lisp**: Fix: standard library package loaders restore the previous package

## 2026-02-12: elps v1.19.0

- **lisp**: `format-string` is rewritten as a single-pass scanner. It supports positional parameters and fixes formatting bugs
- **lint**: New `--fail-on` flag sets the severity that gives a non-zero exit code. Fix: false positives for `nolint` with semantic checks

## 2026-02-12: elps v1.18.0

- **lint**: Fix: false positives for `handler-bind` condition types and for local bindings that shadow a function
- **elps**: Embedders can reuse the `lint` and `doc` commands in their own CLI

## 2026-02-12: elps v1.17.2

- **lint**: Fix: `export` before `defun`, and the `(expr ...)` prefix lambda, are recognized

## 2026-02-12: elps v1.17.1

- **elps**: Maintenance release; no change to the language or library.

## 2026-02-11: elps v1.17.0

- **lint**: New semantic checks with cross-file workspace analysis: `undefined-symbol`, `unused-variable`, `unused-function`, `shadowing` and `user-arity`. Use `--workspace=.` to turn them on
- **lint**: New `unused-nolint` check reports stale suppression comments
- **lint**: Embedders pass their package registry, so lint sees Go-provided symbols. Embedders can check for missing documentation
- **parser**: Tokens have end positions, diagnostics have severity and parse errors are structured, as a base for editor support

Details: [elps v1.17.0 release](https://github.com/luthersystems/elps/releases/tag/v1.17.0).

## 2026-02-09: elps v1.16.14

- **elps**: The REPL has persistent history, tab completion, formatted error output and `--json`, `--batch` and `--eval` flags
- **lisp**: Security: file access can be confined to a root directory, `string:repeat` and `make-sequence` bound allocations and the call stack has a default depth limit
- **lisp**: Fix: `export` with a list argument, `insert-index` with a negative index, `handler-bind` cleanup and `use-package` with more than one argument
- **lint**: New `unnecessary-progn` check and `--exclude` flag for `lint` and `fmt`
- **lisp**: Faster symbol resolution and fewer allocations for `nil`, `true` and `false`

## 2026-02-08: elps v1.16.13

- **lisp**: New `rethrow` builtin re-raises an error in `handler-bind` and keeps its stack trace

## 2026-02-08: elps v1.16.12

- **lisp**: All builtins, operators, macros and standard library functions have docstrings. New `defconst` macro. `elps doc -l` lists packages
- **lisp**: Errors render as annotated source snippets with column numbers, and the parser reports mismatched brackets
- **lint**: New `cond-missing-else` and `quote-call` checks. Each diagnostic has a hint and a `nolint` suggestion
- **lisp**: Fix: macro expansion source locations, and user-registered builtins replaced by language copies

## 2026-02-07: elps v1.16.11

- **lint**: New `elps lint` command runs static analysis on ELPS source. Suppress a finding with `; nolint`
- **formatter**: `elps fmt -l` lists files that need formatting and exits non-zero

## 2026-02-07: elps v1.16.10

- **formatter**: New `elps fmt` command formats ELPS source

## 2026-01-21: substrate v2.207.0

- **substrate**: Fix union range pagination duplicate keys
- **substrate**: Fix memory leak in shirotester isolation mode
- **substrate**: Update golang.org/x/crypto to v0.47.0 to fix security vulnerabilities

## 2025-11-18: substrate v2.206.0

- **substrate**: Add union range pagination functions
- **substrate**: Replace elps ymd-between-dates with constant-time Go implementation

## 2025-11-18: buildenv v0.0.95

- **build-go**, **build-godynamic**, **build-java**, **build-js**: `make static` builds images with `docker buildx build`

## 2025-11-18: buildenv v0.0.94

- **build-go**, **build-godynamic**, **build-java**, **build-js**: Docker CLI 27.3.1, which supports Docker API 1.44 and later

## 2025-10-07: buildenv v0.0.93

- **General**: Go 1.25.1, golangci-lint 2.5.0, gotestsum 1.13.0, buf 1.57.2, go-swagger 0.33.0, Azure CLI 2.77.0 and Node.js 20.19.3
- **build-api**: New `PROTO_PATH` and `SWAGGER_VALIDATION_PATH` variables set where the build finds `.proto` and `.swagger.json` files. Swagger validation runs only when swagger files exist

## 2025-07-24: substrate v2.205.15

- **connectorhub**: Add MCP connectors

## 2025-07-14: substrate v2.205.14

- **connectorhub**: Fix connector casing
- **connectorhub**: Add test CLI command

## 2025-07-03: elps v1.16.9

- **elpstest**: The test runner has a setup hook and a close method. Benchmarks do not count setup time
- **lisp**: Fix: a panic in error handling

## 2025-06-24: substrate v2.205.13

- **substrate**: Add general mock settings
- **connectorhub**: Add Luther connectors

## 2025-06-23: substrate v2.205.12

- **connectorhub**: Fix connectorhub protos and add rich connector annotations
- **connectorhub**: Add new and remaining connector annotations, enums, categories, icons, and logos; update connector keys, config, and category order; ensure consistency in naming and file conventions
- **connectorhub**: Fix typos, indentation logic, and comments; update README
- **substrate**: Attempt to fix shirotester unit-test race, memory leak, isolation, and shared mode

## 2025-05-02: buildenv v0.0.92

- **General**: Go 1.24.2

## 2025-05-02: buildenv v0.0.91

- **General**: Go 1.24.1, golangci-lint 2.0.2, gotestsum 1.12.1, buf 1.50.1, Azure CLI 2.70.0, AWS CLI 2.25.5 and Node.js 20.19.1

## 2025-04-29: substrate v2.205.10

- **substrate**: Do not create profiler when no trace
- **connectorhub**: Add unimplemented connectors

## 2025-03-31: substrate v2.205.9

- **substrate**: Add dynamic elps filtering option
- **connectorhub**: Add ability to test connector connection

## 2025-03-21: substrate v2.205.8

- **substrate**: Upgrade `x/net` dependencies
- **substrate**: Add range query pagination
- **migrations**: Add ctx migration support

## 2025-02-26: buildenv v0.0.90

- **General**: Go 1.23.6, Alpine 3.21, golangci-lint 1.63.4, gotestsum 1.12.0, buf 1.48.0, go-swagger 0.31.0, Azure CLI 2.67.0 and AWS CLI 2.22.28
- **build-js**: Node.js 20.18.3

## 2025-02-14: substrate v2.205.7

- **substrate**: Disable write polling by default
- **connectorhub**: Add connector lib

## 2024-11-21: buildenv v0.0.89

- **General**: Go 1.23.3, buf 1.47.2, Azure CLI 2.66.0 and AWS CLI 2.21.3

## 2024-10-31: substrate v2.205.6

- **shiroclient**: Expose commit block number and max sim block number to SDK

## 2024-11-26: Luther Auth v4.7.6

- **General**: Support Auth0
- **General**: Upgrade go dependencies
- **General**: Fix open redirect vulnerability by introducing `AUTH_OAUTH_VALID_FRONTEND_REDIRECT_URLS` and `AUTH_OAUTH_VALID_CALLBACK_URLS` environment variables
- **General**: Support `frontend_redirect_url` parameter in `/v1/auth/oauth_login`

## 2024-10-29: substrate v2.205.5

- **substrate**: fix target peers

## 2024-10-23: substrate v2.205.4

- **substrate**: improve build pipeline

## 2024-10-22: substrate v2.205.3

- **substrate**: upgrade go dependencies
- **shiroclient**: expose target peers on cli

## 2024-09-06: substrate v3.0.0

- **substrate**: Cut from a side branch off v2.205.2, not from the main release line — the shim upgrade and build changes below were also carried into v2.205.3, while the key-limit work is exclusive to this tag and was not carried into later v2 releases
- **substrate**: Upgrade the Hyperledger Fabric Go chaincode shim, cleanly separating the substrate and shiroclient packages and resolving a proto namespace collision
- **substrate**: Key metrics refactored to add a per-transaction key limit with a dedicated key-limit error; the limit is disabled for migrations
- **substrate**: Docker Compose is no longer required for local builds; buildenv and Fabric images bumped

## 2024-08-01: substrate v2.205.2

- **substrate**: Improve block cache logging, and recording of trace requests

## 2024-07-29: buildenv v0.0.88

- **nginx-frontend**: Use the base image's default entrypoint

## 2024-07-27: buildenv v0.0.87

- **nginx-frontend**: Use the latest nginx base image

## 2024-07-26: buildenv v0.0.86

- **nginx-frontend**: Publish the image for amd64 and arm64

## 2024-07-24: substrate v2.205.1

- **shiroclient**: Add missing block cache optimization
- **substrate**: Add initial profile guided optimization (PGO) to substrate

## 2024-07-23: buildenv v0.0.85

- **General**: Go 1.22.5, golangci-lint 1.59.1, buf 1.35.0, Azure CLI 2.62.0 and AWS CLI 2.17.10
- **General**: Remove the `build-goextra` image. Use build-go or build-godynamic

## 2024-07-15: substrate v2.205.0

- **shiroclient, substrate**: Add prometheus metrics to expose substrate version
- **shiroclient, substrate**: Support arm64 architecture

## 2024-06-21: substrate v2.204.4

- **shiroclient**: Fix dependent transaction waiting off-by-one bug when checking peer block height

## 2024-06-10: substrate v2.204.3

- **shiroclient**: Add support for WithoutTargetPeers

## 2024-06-10: substrate v2.204.2

- **substrate**: Fix sideDB statedb:purge fail over when fabric 2.5 channel config not enabled

## 2024-06-04: substrate v2.204.1

- **shiroclient**: Fix license init logic

## 2024-06-04: substrate v2.204.0

- **shiroclient**: break out prometheus timing metrics by endpoint
- **substrate**: add simulation time prometheus metric by endpoint (`substrate_tx_sim_dur`)
- **substrate**: add key count prometheus metrics by endpoint (`substrate_tx_keys`)

## 2024-05-16: substrate v2.203.0

- **shiroclient**: add demo mode for easy `sandbox` setup

## 2024-05-13: substrate v2.202.0

- **shiroclient**: fix panic when block cache disabled

## 2024-04-18: substrate v2.201.0

- **substrate**: lazy load elps packages
- **shiroclient**: fix mem leak in metrics
- **shiroclient**: add block puller
- **shiroclient**: Add license digest cache
- **shirocore**: remove VBC

## 2024-03-29: buildenv v0.0.84

- **General**: Go 1.22.1, golangci-lint 1.57.2, buf 1.30.0, Azure CLI 2.58.0 and AWS CLI 2.15.31

## 2024-03-29: elps v1.16.8

- **lisp**: Struct layouts are optimized to use less memory

## 2024-03-29: elps v1.16.7

- **elps**: Build with Go 1.22

## 2024-03-26: substrate v2.200.0

- **fabric-network-builder**: Add external domain, SANS support
- **shircore**: update protobuf to v1.33.0

## 2024-03-05: substrate v2.199.0

- **shiroclient**: Fix blockcache dep tx waiting
- **shiroclient**: Add shiroclient-gw opt to disable write polling by default
- **shiroclient**: Add WithTargetEndpoints to select peers for endorsement

## 2024-03-03: substrate v2.198.0

- **substrate**: improve `elps` vm pre-heater for faster tx procesing
- **shiroclient**: use peer discovery on commit fallback
- **plugin**: support `CSPRNG` in local tests

## 2024-02-24: buildenv v0.0.83

- **build-godynamic**: Fix the Azure CLI install

## 2024-02-15: substrate v2.197.1

- **substrate**: bump deps
- **shiroclient**: use `otelhttp` http server for gateway

## 2024-02-14: buildenv v0.0.82

- **General**: Go 1.21.7, Alpine 3.19, golangci-lint 1.56.1, buf 1.29.0, Azure CLI 2.57.0 and AWS CLI 2.15.19

## 2024-02-12: substrate v2.197.0

- **substrate**: add ratelimiter
- **shiroclient**: fix span tree
- **substrate**: add profile tracing to `defendpoint`
- **substrate**: improve tracing support

## 2024-02-10: elps v1.16.6

- **profiler**: Trace spans include anonymous functions and better source locations, with shorter span names

## 2024-02-05: substrate v2.196.0

- **shiroclient**: fix race condition on commitment
- **substrate**: make preheat workers configurable, revert preheat cache size change
- **substrate**: add `elps doc` trace filters
- **substrate**: add better context threading
- **substrate**: improve tracing support

## 2024-01-31: elps v1.16.5

- **profiler**: New span labeler sets custom names for trace spans

## 2024-01-09: substrate v2.195.0

- **substrate**: upgrade `elps` to 1.64.4
- **shiroclient**: add max retries option
- **externalcc**: fix `chaincode-as-a-service`

## 2024-01-04: substrate v2.194.0

- **substrate**: Improve tracing support (move from opencensus to otel)
- **substrate**: Bump pre-heater default size
- **substrate**: Internal refactor of library paths
- **substrate**: Update dependencies
- **shiroclient**: Improve chaincache logic

## 2024-01-03: elps v1.16.4

- **profiler**: New skip filter excludes functions from profiles. Fix: a panic in the profiler

## 2023-12-18: elps v1.16.3

- **lisp**: Environments write to the configured stderr. The REPL can be tested from Go
- **elps**: Dependency updates

## 2023-12-11: buildenv v0.0.81

- **build-go**, **build-godynamic**: `make static` builds no longer need VCS information to read the module path

## 2023-12-06: buildenv v0.0.80

- **build-go**, **build-godynamic**: `make static` builds Go binaries without CGO

## 2023-12-04: substrate v2.193.0

- **shiroclient**: Add shiroclient block and transaction (chaincache) cache to reduce waiting times
- **shiroclient**: Improve shiroclient retry logic
- **shiroclient**: Add support for DependentBlock
- **shiroclient**: Improve context canceled handling
- **shiroclient**: Support WithPhylumVersion

## 2023-12-01: buildenv v0.0.79

- **General**: Go 1.21.4, Alpine 3.18, golangci-lint 1.55.2, gotestsum 1.11.0, buf 1.28.1, go-swagger 0.30.5, Azure CLI 2.54.0 and AWS CLI 2.14.5
- **General**: Git accepts mounted repositories that another user owns
- **General**: Remove the Bitbucket private module settings

## 2023-11-15: buildenv v0.0.77

- **General**: Fix the Git URL rewrite rules for private GitHub modules

## 2023-11-13: substrate v2.192.3

- **shiroclient**: optimize wait logic to avoid redundant waits

## 2023-10-31: substrate v2.192.2

- **buildpack**: support HLF2.5 binaries

## 2023-10-27: substrate v2.192.1

- **shiroclient**: reduce default commit timeout to 3s
- **shiroclient**: improve context canceled logging

## 2023-10-25: substrate v2.192.0-fabric2.2

- **substrate**: Fabric 2.2 build of v2.192.0 — adds the Fabric 2.2.13 artifacts for networks still on the 2.2 line

## 2023-10-23: substrate v2.192.0

- **shiroclient**: fix retry backoff

## 2023-09-18: buildenv v0.0.76

- **General**: Extend private GitHub module access for Go builds

## 2023-09-05: substrate v2.191.0

- **shiroclient**: make client connection keep alive (platewarmer) optional (client.plate-warmer = false)
- **substrate**: support purge of private data on HLF2.5
- **externalcc**: add pprof endpoint

## 2023-08-14: substrate v2.190.1

- **shiroclient**: do not error log OK errors
- **shiroclient**: reduce verbosity of INFO messages

## 2023-07-31: buildenv v0.0.75

- **build-js**: Node.js 20.5.0

## 2023-07-26: substrate v2.190.0

- **shiroclient**: improve context canceled error handling
- **shiroclient**: improve error logging

## 2023-07-26: buildenv v0.0.74

- **build-go-alpine**: Add an SSH client, so Go can fetch private modules over SSH

## 2023-07-25: buildenv v0.0.73

- **build-go-alpine**: Support private GitHub modules for Go builds

## 2023-07-19: substrate v2.189.0

- **private library**: add support for skipEncodeTx optimization

## 2023-07-19: buildenv v0.0.72

- **General**: Extend private GitHub module access for Go builds

## 2023-07-18: substrate v2.188.0

- **upgrade**: elps to 1.16.2

## 2023-07-17: elps v1.16.2

- **profiler**: New OpenTelemetry tracing provider
- **elps**: Build with Go 1.20

## 2023-07-13: substrate v2.187.0

- **update**: tar artifact permissions

## 2023-07-13: substrate v2.186.0

- **upgrade**: golang to 1.20.4
- **upgrade**: buildenv to v0.0.67

## 2023-07-13: substrate v2.186.0-fabric2

- **substrate**: Fabric 2.x build of v2.186.0, with the same changes

## 2023-07-11: buildenv v0.0.71

- **General**: Improve support for private GH repos

## 2023-07-10: buildenv v0.0.70

- **General**: Add support for luther github repos

## 2023-06-08: buildenv v0.0.69

- **General**: Support private github repos

## 2023-06-08: buildenv v0.0.68

- **General**: Bump awscli to 2.11.26 and deps
- **General**: Update github host keys

## 2023-05-18: buildenv v0.0.67

- **General**: Use new bitbucket host keys

## 2023-05-05: substrate 185.0-fabric2

- **fabric network builder**: Update dependencies

## 2023-05-05: substrate 184.0-fabric2

- **All services**: Use golang 1.20

## 2023-05-03: buildenv v0.0.66

- **Java**: Use alpine 3.16

## 2023-05-02: buildenv v0.0.65

- **CI**: Fix dockerhub multi-arch publish

## 2023-05-02: buildenv v0.0.64

- **CI**: Fix CI publish

## 2023-05-01: buildenv v0.0.63

- **CI**: Fix CI on github

## 2023-05-01: buildenv v0.0.62

- **General**: Move to github
- **Golang**: Update go to 1.20.3, alpine to 3.17

## 2023-04-28: elps v1.16.1

- **elps**: Build with Go 1.20.3 and update `golang.org/x/text` to v0.3.8

## 2023-04-27: buildenv v0.0.61

- **API**: Upgrade `buf` to 1.17.0

## 2023-03-27: substrate 2.183.0-fabric2

- **shiroclient gateway**: Improve peer selection prioritization
- **shiroclient gateway metrics**: Avoid panic on missing license file

## 2023-03-03: buildenv v0.0.60

- **Godynamic**: Fix awscli versions
- **Golang**: Update go to 1.20.1, golangci-lint to 1.51.2, awscli to 2.11.0

## 2022-12-01: substrate 2.182.0-fabric2

- **shiroclient gateway**: Improve logging and tx retry logic

## 2022-11-02: substrate 2.181.0-fabric2

- **shirotester**: Fix `mxf` snapshot RNG re-use

## 2022-10-20: substrate 2.180.0-fabric2

- **shirocore**: Add `base32` library (encode/decode)

## 2022-10-20: substrate 2.179.0-fabric2

- **shiroclient metrics**: Improve retry for license metrics collection

## 2022-09-02: buildenv v0.0.59

- **Golang**: Upgrade golangci-lint

## 2022-08-20: substrate 2.178.0-fabric2

- **push proxy**: Make pushproxy docker image public on dockerhub

## 2022-08-16: substrate 2.177.0-fabric2

- **substrate**: Support audience (`aud`) array JWTs

## 2022-08-08: substrate 2.176.0-fabric2

- **shiroclient gateway metrics**: Improve license metrics collection

## 2022-08-04: buildenv v0.0.58

- **Golang**: Support `GO_BUILD_EXTRA_FLAGS`

## 2022-07-26: substrate 2.175.0-fabric2

- **shiroclient**: Add genesis block hash as tag on metrics; identifies environment together with license digest (already present as tag), which identifies which customer/client is sending metrics.

## 2022-07-20: substrate 2.174.0-fabric2

- **shiroclient**: Add metrics reporting block height and server status

## 2022-07-08: substrate 2.173.0-fabric2

- **shirocore**: remove performance improvement cache that was added in substrate 2.172.0-fabric2 release due to new bug introduced reading only the first toset when iterating a tomulset

## 2022-06-22: elps v1.16.0

- **elps**: Maintenance release; no change to the language or library.

## 2022-06-21: buildenv v0.0.57

- **Golang**: Use golangci-lint for static checks

## 2022-06-09: substrate 2.172.0-fabric2

- **shirocore**: performance bug fix concerning storage-toset-next-iters & storage-toset-next-iter-fill-page duplicate iteration
- **golang**: bump golang to 1.16.15

## 2022-06-06: buildenv v0.0.56

- **Golang**: Update go to 1.18.3

## 2022-06-06: buildenv v0.0.55

- **godynamic**: fix aws-cli install
- **js**: add better support for `aws help` command

## 2022-06-03: buildenv v0.0.54

- **godynamic**: fix azure-cli install
- **js**: include python for `node-gyp` support

## 2022-05-26: buildenv v0.0.53

- **go-static**: use alpine, remove TINI vars

## 2022-05-26: buildenv v0.0.52

- **internal**: CI/CD release improvements

## 2022-05-25: buildenv v0.0.51

- **internal**: major changes to facilitate migration to github and circle CI
- **multi-architecture**: add multi-arch builds for amd64 and arm64
- **api**: remove `prototool`, add `buf`
- **go**: add `staticcheck` tool
- **go**: add `jq` tool
- **all**: fetch certificates from official `ca-certificates` package
- **all**: fetch time zone data from official `tzdata` packages
- **debian**: do not include suggested packages by default
- **go-extra**: use ubuntu 20.04
- **static go builds**: include build tags for time zone data

## 2022-04-28: buildenv v0.0.50

- **godynamic**: upgrade azcli to 2.35.0

## 2022-04-25: elps v1.15.0

- **elps**: New `elps doc` command and REPL `help` package show docstrings for functions and packages
- **elps**: Build with Go 1.17 and update dependencies

## 2022-04-01: substrate v2.171.0-fabric2 Release

- **substrate**: fix buildpack for external chaincode

## 2022-03-31: substrate v2.170.0-fabric2 Release

- **buildenv**: bump to 0.0.49
- **hyphae**: use public github for libhandlebars
- **shiroclient**: add dependent TX ID logging
- **shiroclient**: bump shiroclient-sdk-go to `ac2085246995`

## 2022-03-23: buildenv v0.0.49

- **alpine**: bump alpine to 3.15
- **golang**: bump golang to 1.16.14

## 2022-03-17: buildenv v0.0.48

- **alpine**: remove old patches to fix security updates which are superfluous

## 2022-03-11: substrate v2.169.0-fabric2 Release

- **shiroclient**: improve retry logic for handling transaction commit timeouts
- **substrate**: fix bug in `decimal-add-money`
- **substrate**: remove `set-now` function from utils
- **libmxf**: release 0.0.4 mxf npm package with decryption bugfix

## 2022-02-25: buildenv v0.0.47

- **godynamic**: add curl

## 2022-01-26: substrate v2.168.0-fabric2 Release

- **shirocore**: add list support in `elpspath`
- **shiroclient**: improve verbose mode (-v)

## 2022-01-10: substrate v2.167.0-fabric2 Release

- **fabric network builder**: Compatibility changes for use in containerized setups
- **mxf**: add public [npm package](https://www.npmjs.com/package/mxf) for decoding mxf encrypted data off-chain
- **substrate**: minor bug fixes

## 2021-12-10: buildenv v0.0.46

- **api**: remove api swagger bindata generation
- **godynamic**: fix azure cli build

## 2021-11-18: substrate v2.166.0-fabric2 Release

- **shirocore**: add `mxf-private-export` function
- **substrate**: push `luthersystems/buildpack` to dockerhub for external chaincode initialization

## 2021-11-12: substrate v2.165.0-fabric 2 Release

- **substrate**: fix chaincode tar build issue introduced in v2.164.0-fabric2

## 2021-11-08: substrate v2.164.0-fabric2 Release

- **hyphae**: add to-int helper to libhandlebars to convert types to int.
- **substrate**: add external chaincode builds (dockerhub: luthersystems/substrate).

## 2021-10-15: substrate v2.163.0-fabric2 Release

- **shirocore**: Allow `cc:creator` in `init` endpoint in mock mode
- **shirocore**: Fix `find-pos` and `find-pos-cmp` bug to correctly return `-1` when the index is not found.

## 2021-09-23: substrate v2.162.0-fabric2 Release

- **substrate**: Add env variable SUBSTRATE_LOG_LEVEL to change log level

## 2021-09-14: buildenv v0.0.45

- **go-alpine**: use static binary dependencies

## 2021-09-13: buildenv v0.0.44

- **service-base-alpine**: update artifacts
- **alpine**: apply security updates
- **go-alpine**: remove `GOPRIVATE` config

## 2021-08-23: buildenv v0.0.43

- **go-alpine**: add go-alpine image

## 2021-07-27: buildenv v0.0.42

- **go**: Change user and owner of built artifacts using the `DOCKER_CHOWN_USER` and `DOCKER_CHOWN_GROUP` environment variables

## 2021-07-21: elps v1.14.1

- **json**: JSON encoding escapes the HTML-unsafe characters `&`, `<` and `>`

## 2021-07-19: substrate v2.160.0-fabric2 Release

- **hyphae**: Add `to-str` helper to libhandlebars
- **hyphae**: Add `GetPipeHTTP` to `s3` package to retrieve stream of bytes.
- **hyphae**: Add cookie retrieval interface for magic links

## 2021-07-01: buildenv v0.0.41

- **godynamic**: Use alpine 3.13 as a stable base.

## 2021-06-23: substrate v2.159.0-fabric2 Release

- **elps**: Upgrade to v1.14.0.
- **fabric network builder**: Add `cert_expires` subcommand to list expiration dates of certificates
- **fabric network builder**: Add mutli-step certificate generation process for improved customizaiton (make generate-template, make generate-assets).
- **buildenv**: Upgrade to v0.0.40.

## 2021-06-16: buildenv v0.0.40

- **api, go, godynamic, goextra**: Cleanup build tags into common configuration.
- **api**: Allow including protos in custom directories.

## 2021-06-09: elps v1.14.0

- **json**: Use custom json encoder for improved performance.
- **json**: Reduce allocations during map serialization.
- **types**: Add ability to write user-defined data types.
- **types**: Update `libschema` to support user-defined data types.
- **macros**: Fix bugs related to macro expansion.

## 2021-06-09: buildenv v0.0.39

- **api. go, godynamic, goextra**: Properly parameterize go versions.
- **api**: Fix typo in make targets and add missing make targets.

## 2021-05-26: buildenv v0.0.38

- **all**: Continue to push images to ECR for backwards compatibility.

## 2021-05-25: buildenv v0.0.37

- **api, go, godynamic, goextra, java, js, swaggercodegen**: Use tini for signal handling in the default image entrypoint.
- **api. go, godynamic, goextra**: Upgrade to go1.16.4.

## 2021-05-14: substrate v2.158.0-fabric2 Release

- **fabric network builder**: Add `fnb-extend` command to generate certs for new orgs.
- **fabric network builder**: Use version 2.2.0 of fabric cryptogen (names private keys `priv_sk` among other changes).
- **fabric network builder**: Use client authentication (mutual TLS).
- **shirocore**: Fix `set-exception-wrapped` to properly wrap exception messages and re-throw them.
- **shiroclient gateway**: Add additional log lines to help debugging.
- **shiroclient gateway**: Retry tx simulation on chaincode 500 error, for increased resilience.
- **shiroclient gateway**: Move shiroclient-sdk-go to [github](https://github.com/luthersystems/shiroclient-sdk-go).

## 2021-03-30: substrate v2.157.0-fabric2 Release

- **shiroclient gateway**: Improve reliability of event service connectivity.
- **shiroclient**: Throw phylum errors during chaincode-to-chaincode (invoke-phylum) failures.

## 2021-03-16: substrate v2.156.0-fabric2 Release

- **shiroclient**: Fix bug in internal minifer for elps symbols.
- **mock substrate**: Improve support for parallel go tests.

## 2021-03-05: substrate v2.155.0-fabric2 Release

- **shiroclient gateway**: Improve metrics logging during tx commit.
- **shirocore**: Fix bug in `tx-pre-hooks` execution, which sets up shirocore env before application code runs.

## 2021-03-04: substrate v2.154.0-fabric2 Release

- **mock substrate**: Fix mock-specific methods.
- **shirocore**: Fix symbol references in `def-migration-up`
- **fabric network builder**: Fix nchoose2 sample networks and Makefiles.

## 2021-03-01: substrate v2.153.0-fabric2 Release

- **elps**: Upgrade to v1.13.1

## 2021-02-25: elps v1.13.1 Release

- **elpstest**: Fix timing for $load benchmark.

## 2021-02-19: substrate v2.152.0-fabric2 Release

- **shirocore**: Fix bug in `ymd` date validations

## 2021-02-19: substrate v2.151.0-fabric2 Release

- **shirocore**: Pre-load (pre-warm) phyla to improve load times

## 2021-02-17: substrate v2.150.0-fabric2 Release

- **mock substrate**: Fix concurrency bug in plugin.

## 2021-02-11: substrate v2.149.0-fabric2 Release

- **mock substrate**: Refactor internal libraries to better support hashicorp plugin.

## 2021-02-09: substrate v2.148.0-fabric2 Release

- **mock substrate**: Add healthcheck to Hashicorp plugin.

## 2021-02-08: substrate v2.147.0-fabric2 Release

- **fabric network builder**: Fix nchoose2 network generation.

## 2021-02-05: substrate v2.146.0-fabric2 Release

- **fabric network builder**: Add support for nchoose2 vanity names.

## 2021-02-08: buildenv v0.0.36 Release

- **all**: Add public docker make targets.

## 2021-02-03: substrate v2.145.0-fabric2 Release

- **shirocore**: Add jaeger support for request tracing.
- **buildenv**: Upgrade to v0.0.34.

## 2021-01-29: buildenv v0.0.35 Release

- **godynamic**: Add azure cli.
- **js**: Add azure cli.
