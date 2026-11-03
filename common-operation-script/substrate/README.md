---
description: Core platform runtime
---

# Substrate

Substrate is the the layer between application modules and platform modules (serves as a compiler/interpreter for elps, enables business logic updates, includes field validation elps functions, GDPR library, ...). Substrate deploys as a Fabric chaincode, and a single Fabric network may have multiple substrates running. Substrate includes a plugin (substrateplugin) that emulates Fabric networks in-memory, to ease local testing.

Substrate is chaincode that runs on the HLF Go runtime and provides an execution environment for business logic written in ELPS [1](https://github.com/luthersystems/elps). This business logic is known as the phylum. The substrate chaincode is deployed as a standard tarball file [2](https://hyperledger-fabric.readthedocs.io/en/release-1.4/chaincode4noah.html). Substrate uses the standard HLF Go shim to interact with fabric.

```
+------------------+
                                |  phylum (elps)   | <-- on-chain app biz logic
+---------------+               +------------------+ ^
|  shiroclient  | <-JSON-RPC--> | shiro (elps & Go)| |
+---------------+               +------------------+ |.tar.gz deployment (platform)
| fabric-go-sdk | <-fabric tx-> | substrate (Go)   | |
+---------------+               +------------------+ v
                                |  fabric go shim  |
                                +------------------+
```

Substrate contains a layer called "shiro" which injects builtins and handlers into an ELPS runtime to facilitate processing of HLF transactions.

shiro provides a router mechanism to register methods and handlers that are called when processing a transaction payload. The standard HLF Invoke handler expects the transaction payload to be in a JSON-RPC format. Shiro will extract the method name and call the registered phylum handler passing in the deserialized ELPS objects to the registered handler. The handler will return a message (or error) which is then wrapped as a JSON-RPC response. shiroclient is a library and microservice (gateway) that constructs transactions that are received by the substrate CDS. These messages are in JSON-RPC format, so as to perform the routing described above. There is a shiroclient go SDK, along with a shiroclient gateway (and Go gateway client SDK) that serves the shiroclient API over HTTP (using JSON-RPC).

Shiroclient provides a mechanism to emulate the blockchain entirely in-memory. This is useful for running local e2e go tests, and does not require running a fabric network to test chaincode e2e.

---

## Phylum & Substrate Updates

Substrate is deployed and upgraded using the standard HLF upgrade flow.

Shiro registers an "update" endpoint that receives phylum in a .zip format. Note that the phylum includes multiple .lisp files that are bundled into this .zip. This is the mechanism that allows shiroclient to install business logic rules into the substrate, and is known as an "over-the-air" update. This light-weight mechanism allows pushing business logic rules as a standard transaction. The phylum .zip releases are all stored in the state database.

Shiro maintains all previous versions of the phylum, which can be enabled and disabled. Shiroclient specifies the version of the installed phylum to run, where the version must be enabled. This allows multiple versions of the chaincode to operate concurrently.

---

## Shiro Builtins

Shiro provides a number of utility functions and libraries to ease writing business logic. Key builtins are documented below:

### Router Package

The `router` package provides core routing functions. You include the `router` package as an ELPS package. E.g.,

```
(use-package 'router)
```

**defendpoint**

This macro registers endpoints which shiroclient can send messages to. Endpoints define an endpoint name and a list of arguments.

There is a special endpoint named `init` which is called both on a substrate upgrade and on an over-the-air (phylum) update. This is where you register migration and initialization logic.

```
(defendpoint "init" ()
             (route-success ()))
```

**route-success , route-failure**

There are two helper functions `route-success` and `route-failure` which are used to construct success and failure messages for the shiroclient. These functions take a single argument which is returned to shiroclient either as a successful response, or as an error. These functions merely construct the properly formatted response, and do not early abort from the function. The result of evaluating the registered handler function is returned to shiroclient, and that result should be a message constructed by `route-success` or `route-failures`.

By convention we only call these helpers within a `defendpoint` function.

**register-endpoint**

`(defun register-endpoint (endpoint arg-names handle-fun))` takes an endpoint name, list of argument names, and a handler function. `defendpoint` is a macro which calls `register-endpoint` to register a JSON-RPC handler with method name `endpoint` and arguments `arg-names`, and callback `handler-fun`.

### Persistent Storage

All phylum variables have a lifetime limited to the lifetime of the transaction execution. To persist data across transactions, you must use functions exported by the `statedb` or `sidedb` packages. As in HLF, this data is only persisted subject to the standard transaction endorsement and commitment flow.

*IMPORTANT*: all substrate storage functions **do** see the immediate results of their writes (e.g., `statedb:put`). This is in contrast to vanilla HLF which does not.

### StateDB Package

The `statedb` package provides helpers to read and write data to the HLF state database.

**get, get-bytes, put, put-bytes, del**

`(statedb:get-bytes k)` takes a string key `k` and returns the stored bytes for that key from the HLF state database. `()` is returned if there is no value stored for that key.

`(statedb:get k)` takes a string key `k` and calls `statedb:get-bytes`, but then deserializes the bytes into an ELPS object by calling the `statedb:deserialize` function.

`(statedb:put-bytes k v)` takes a string key `k` and bytes `v` and stores `v` under `k` in the HLF state database.

`(statedb:put k v)` takes a string key `k` and ELPS object `v` , serializes the object by calling the `statedb:serialize` function and then calls `statedb:put-bytes`.

`(statedb:del k)` takes a string key `k` and deletes any value in the `statedb` for this key.

`(statedb:serialize v)` is the serialization function for the `statedb` package. It converts an elps object into a bytes (presently as JSON bytes).

`(statedb:deserialize b)` is the deserialize function for the `statedb` package. It converts bytes to an elps object (presently from JSON bytes).

As an example, here is how the phylum registers a single endpoint `set` that takes an object `obj` which has a propert `key` and `val`. This endpoint then stores val in the statedb under key `key`, and returns a success message with the data stored under a key `data`:

```
(use-package 'router)
(defendpoint "set" (obj)
             (let* ([key (get obj "key")]
                    [val (get obj "val")])
               (statedb:put key val)
               (route-success (sorted-map "data" (statedb:get key)))))
```

**range, range-bytes**

`(statedb:range-bytes fn z start end)` performs a range query against the state database, starting from key `start` (inclusive) and ending at key `end` (exclusive). `fn` is a reduce function with signature `(acc curr-key curr-val)`, and `z` is the initial value of `acc`. `acc` is the accumulator parameter in the reduce, `curr-key` is the current key being ranged over, and `curr-val` is the value (bytes) for that key.

`range` works the same as `range-bytes`, but calls `deserialize` on the `curr-val` bytes.

### SideDB Package

The `sidedb` package provides functions for persisting data to HLF a common "private data collection" (pdc) [3](https://hyperledger-fabric.readthedocs.io/en/release-1.4/private-data/private-data.html) with name `private`. The network must be configured with this collection enabled.

**get, get-bytes, put, put-bytes, del**

These functions have the same signature and usage as the `statedb`, however this data is persisted to the pdc with name `private`.

### Private Package

The `private` package provides functions for persisting and manipulating private data that cannot be stored directly on the blockchain.

**k-anonymity hashes**

`(defun put-hashed (table nchar key val)` puts (key, val) in the given table with buckets labeled by the given number `nchar` of hex characters of key hash. if val is nil, any association for the given key is removed. an empty bucket will still contain a salt and take up space. This data is persisted in the `sidedb` and is used to avoid persisting hashes of private data in the state database. This function is helpful for storing data with a private key in the private database, where a direct call to `sidedb:put` with that key would insecurely store the hash of the key on the state database.

`(defun get-hashed (table nchar key)` retrieves the value associated with the given key in the given table with buckets labelled by the given number of hex characters of key hash.

**GDPR (storing removable private data in the statedb)**

The GDPR library uses a library called `mxf`, or message transform, to take messages and apply certain transformations of specific fields, to generate an "encoded" message.

A list of transforms are applied to a context object sequentially, to generate an encoded message. Transforms may define an encryption algorithm ("none" or "AES-256"), and a compression algorithm ("none" or "zlib"). AES-256 uses AES-GCM with a unique IV per encryption application (via the CSPRNG).

Transforms are rooted at a path `context_path` (defined in elpspath) that is on the context object. A transform specifies paths `private_paths` in elpspath notation that are passed to the compression and encryption algorithms, where a new encoded message is generated that removes these referenced private paths from the context object. The compressed and encrypted fields are included in a separate section of the encoded message that is distinct from the original payload.

When applying AES-256, `mxf` uses certain paths `profile_paths` on the context object that uniquely identify a data subject and their encryption key. These paths are expressed in elpspath notation, and are used to construct a Data Subject Profile (DSP). The DSP is an object that uniquely identifies the data subject and is stored in the `sidedb`. All data subjects have a unique ID called the DSID. The DSP is used by `mxf` to lookup a a DSID, which in turn is used to look up a Data Subject Record (DSR). The DSR is an object that includes a DSID, DSP, and a DSK (data subject key), and is also stored in the `sidedb`. The DSK is used in all AES-256 confirmations for a data subject (along with a unique IV generated for each operation). If the DSR does not exist, then a new DSR is created, along with a new random key.

Example transformations that operate on a context object that contains a "Requests" array, where each request has a unique data subject uniquely identified by their name (for illustrative purposes only, do not use this example in your application!):

```lisp
    (vector
      (sorted-map
        "context_path" ".Requests[0]"
        "header" (sorted-map
                   "profile_paths" (vector ".Name")
                   "private_paths" (vector ".Name" ".Birthday" )
                   "compressor" "zlib"
                   "encryptor" "AES-256"))
      (sorted-map
        "context_path" ".Requests[1]"
        "header" (sorted-map
                   "profile_paths" (vector ".Name")
                   "private_paths" (vector ".Name" ".Birthday")
                   "compressor" "zlib"
                   "encryptor" "AES-256")))
```

An example context object for which these transformations are applicable:

```lisp
  (sorted-map "Requests"
              (vector
                (sorted-map "RequestID" "e24e8858-9de3-11e8-98d0-529269fb1459"
                            "Name" "Ben Franklin"
                            "Birthday" "17/Jan/1706")
                (sorted-map "RequestID" "f5e26dbc-9de3-11e8-98d0-529269fb1459"
                            "Name" "Tom Jefferson"
                            "Birthday" "13/Apr/1743")))
```

The result of using `mxf` to encode the context object using the above transforms:

```lisp
  (sorted-map
    "mxf" "v1"
    "message" (sorted-map "Requests"
                          (vector
                            (sorted-map "RequestID" "e24e8858-9de3-11e8-98d0-529269fb1459"
                                        "Name" ()
                                        "Birthday" ())
                            (sorted-map "RequestID" "f5e26dbc-9de3-11e8-98d0-529269fb1459"
                                        "Name" ()
                                        "Birthday" ())))
    "transforms" (vector (sorted-map
                           "context_path" ".Requests[0]"
                           "header" (sorted-map
                                      "profile_paths" (vector ".Name")
                                      "private_paths" (vector ".Name" ".Birthday")
                                      "compressor" "zlib"
                                      "encryptor" "AES-256")
                           "body" (sorted-map
                                    "dsid" "4944427072"
                                    "encrypted_base64" "MDEyMzQ1Njc4OUFCoB8ia4p1sTDCpz5ZODC/cK9lreO9SbA7nZq0Q9EQDs57AN2yzXKHZrw7J07IpakE22BN4Qpf3q+kqQ=="))
                         (sorted-map
                           "context_path" ".Requests[1]"
                           "header" (sorted-map
                                      "profile_paths" (vector ".Name")
                                      "private_paths" (vector ".Name" ".Birthday")
                                      "compressor" "zlib"
                                      "encryptor" "AES-256")
                           "body" (sorted-map
                                    "dsid" "2355237171"
                                    "encrypted_base64" "QUJDREVGMDEyMzQ1aD+zhzCYKsq3XAv3u9ZF4anUemvA3SS7Zrj9L1g/DOu/nlR9BHXIeUKa2z90xr4Wf7sqWVqBGWUExuU="))))
```

`mxf` will decode this example encoded message into the original example context object.

`(defun mxf-encode (msg transforms)` mxf-encode applies transformations to a message, generating DSR when necessary.

`(defun mxf-decode (enc)` mxf-decode uses the private DB to decode a message that was previously encoded using `mxf-encode`.

`(defun get-mxf (key)` retrieves an encoded message from the state database and decodes it.

`(defun put-mxf (key msg transforms)` encodes and places the encoded message into the state database. It adds bookkeeping to track where DSD is placed, to efficiently support data export.

`(defun mxf-purge-dsid (dsid)` removes all data associated with a DSID by destroying the associated DSR from the sidedb.

`(defun mxf-purge-profile (profile)` Removes all data associated with a data subject profile (DSP).

`(defun mxf-profile-keys (profile)` Returns the statedb keys for the given profile (DSP). This function is used to lookup all the data associated with a data subject.

**The GDPR library exposes several endpoints that are callable from shiroclient.**

`(defendpont private_decode enc)`: Decrypt (`mxf-decode`) a message that was previously encrypted by the smart contract (e.g., via `private_encode`). Called by the shiroclient-sdk-go `private` library.

`(defendpont private_encode)`: Encrypt (`mxf-encode`) a message using a transform. This is useful for GDPR compliance. Only transient data should be passed to this endpoint via a single field `mxf`. Transient data is not placed on the blockchain. This TX may be committed in the case where we are generating new DSRs. Called by the shiroclient-sdk-go `private` library.

`(defendpoint private_get_dsid profile)`: Returns a DSID given a profile. This TX must not be commited since the profile may contain private data.

`(defendpoint private_purge dsid)`: Cryptoshreds all data subject records corresponding to a DSID.

`(defendpoint private_export dsid)`: Returns all the private data for a given DSID. This TX must not be committed since the data is sensitive.

`(defendpoint private_update)`: Allows updating fields in a single record maintained by `put-mxf`. The transient field `private_update` is used to look up a `key` `path` and `value`, where `key` contains an mxf-encoded object, `path` is an `elpspath` and `value` is the updated value.

### CC Package

The chaincode `cc` package provides the basic building blocks for interacting with HLF and performing basic smart contract operations.

`(defun force-no-commit-tx ()` forces a transaction to not be committed by including information in the transaction response that signals to `shiroclient` to skip commitment.

*IMPORTANT*: This function cannot be "undone"--once this function is called the transaction will not be committed. `(defun substrate-version()` Returns the version string of substrate.

**Time**

`(defun add-date (date-or-timestamp num-years num-months num-days)` Adds the specified years, months, or days to a date or timestamp.

`(defun add-days (date-or-timestamp num-days)` Adds the specified days to a date or timestamp.

`(defun add-months (date-or-timestamp num-months)` Adds the specified months to a date or timestamp.

`(defun add-seconds (date-or-timestamp num-seconds)` Adds the specified seconds to a date or timestamp.

`(defun add-years (date-or-timestamp num-year)` Adds the specified years to a date or timestamp.

`(defun now ()` Return an RFC3339 [5](https://tools.ietf.org/html/rfc3339) timestamp for the current time in UTC. The time is extracted from transient data provided by shiroclient.

`(defun date-now ())` Current time in `YYYY-MM-DD` format.

`(defun parse-date (date)` Parse a date string in `YYYY-MM-DD` format into a date object.

`(defun parse-timestamp (ts)` Parse a timestamp string in RFC3339 format into a timestamp object.

`(defun timestamp (ts)` Convert a timestamp object into a string (RFC3339).

`(defun timestamp-unix (ts)` Convert a timestamp into unix epoch time and output as a hex string.

`(defun ymd-between-dates (date-1 date-2)` Returns the difference between 2 dates provided for each date component.

```
shiro> (ymd-between-dates "2020-01-01" "2020-10-10")
(vector 0 9 9)
```

**Tokens & JWTs**

`(defun auth-claims (token &key no-verify)` Parses a JWT token and returns a sorted map of claims. Presently only `:no-verify true` is supported, and token authentication must occur off-chain.

**Random number generator**

`(defun csprng-init (seed-bytes)` Initialize a (transaction scope) HKDF with the given random seed bytes. These random bytes are normally passed as transient data. Uses HMAC-SHA512 (RFC 5869) [4](https://tools.ietf.org/html/rfc5869).

`(defun csprng-generate (num-bytes)` Generate `num-bytes` of pseudo random bytes using the initialized `csprng`.

*Note*: the CSPRNG can be exhausted if too many `num-bytes` are requested and not enough `seed-bytes`. In this case, the function will throw an error.

**Transaction Data**

`(defun transient-get (key)` Retrieve data for a specific `key`, from transient data passed within a JSON object (typically via the shiroclinet SDK). Transient data is data made available within a chaincode transaction, but is not persisted to the blockchain data structures. [3](https://hyperledger-fabric.readthedocs.io/en/release-1.4/private-data/private-data.html) Keys beginning with `$` are reserved for internal substrate use.

`(defun tx-id ()` Return a string of the HLF transaction ID.

`(defun set-tx-metadata (key val)` Set metadata with string key key and string value val on the transaction context.

`(defun get-tx-metadata (key val)` Get metadata with string key key from the transaction context.

Transaction metadata is stored in the state database under the transaction ID (see Virtual Blockchain, VBC) for more details.

**Logging**

`(defun errorf (fields-map format-string &rest format-args)` Log the message `(format-string format-string format-args...)` at `level=error`. The fields in `fields-map` go on the line as structured fields. `fields-map` is a `sorted-map` or `()`. It is always the first argument, so pass `()` when there are no fields.

`(defun warnf (fields-map format-string &rest format-args)` The same at `level=warn`.

`(defun infof (fields-map format-string &rest format-args)` The same at `level=info`.

`(defun debugf (fields-map format-string &rest format-args)` The same at `level=debug`.

`(defun log-fields (level fields-map &rest msg)` Log `msg` at `level`, with the fields in `fields-map` (a `sorted-map` or `()`). `level` is the string or symbol `debug`, `info`, `warn` or `error`, in any case. An empty `level` means `info`. Use it when the code chooses the level at run time. `msg` is not a format string. Pass one string: two strings are joined with no space between them.

`(defun set-log-field (key val)` Add the field `key` (a string or symbol) to every later log line of the transaction. The value is logged as a string, and `()` is logged as `""`.

`(defun should-log ()` Return `true` when the peer sets `SUBSTRATE_STATEDB_DEBUG=true`. See [How to log from a phylum](#how-to-log-from-a-phylum).

`(defun log-metrics ()` Log the transaction's storage metrics, such as the number of keys read and written, at `level=info`. The message is `storage-metrics`. Substrate writes this line itself after a storage operation fails. The function is not exported, so a phylum does not need to call it.

### base64 Package

`(defun encode (data)` Return a base64 encoded string of `data`, where `data` is type byte or string.

`(defun decode (data)` Base64 decode string data and return decoded bytes.

### hex Package

`(defun encode (data)` Return a hex encoded string of `data`, where data is type byte or string.

`(defun decode (data)` Hex decode string `data` and return decoded bytes.

### crypto Package

`(defun sha512-digest (data)` Return the `sha512` digest bytes of string or bytes `data`.

`(defun sha256-digest (data)` Return the `sha256` digest bytes of string or bytes `data`.

### elpspath Package

Ellipse path provides a DSL for querying ELPS objects, in the spirit of the tool `jq`.

Please see the the separate elpspath documentation for more details.

`(defun get-path (obj path)` Query elpspath path on sorted-map `obj` and return the resulting value.

`(defun set-path! (obj path val)` Query elpspath `path` on sorted-map `obj` and set the value at that path to `val`.

### handlebars Package

This package provides handlebars-style templating, with some additional helper functions.

Please see the separate handlebars documentation for more details.

`(defun version ()` Return a version string of handlebars.

`(defun render (tpl ctx)` Parse and evaluate handlebars on string template `tpl` with sorted-map context `ctx` and return the resulting string.

`(defun must-parse (tpl)` Parse handlebars string template `tpl` and throw a '`handlebars-parse` error if the template is invalid.

`(defun libname ()` Return the string name of the underlying handlebars library.

### App Control Properties

By default shiro includes functions and endpoints for setting application configuration. This is useful for setting application constants, versus hard coding them within the code. These helpers are in the `appctrl` package.

`(use-package 'appctrl)`

`(defun get-prop (key)` Retrieves a value for a property name.

`(defun set-prop (key val)` Sets a value for a key.

By default the values are all stored in a common key in the statedb, so care must be taken to avoid private data and MVCC conflicts.

If the key is prefixed with the name `distinct:` then a separate statedb key is used for the property, to avoid MVCC conflicts across property updates.

The endpoint `set_app_control_property` and `get_app_control_property` are automatically registered, and call `set-prop` and `get-prop` respectively.

## How to log from a phylum

You cannot step through a phylum on a peer. Log lines are the main record of what a transaction did. These rules keep the lines useful, and they keep a log call from changing what a transaction does.

**Pick a level.** Use `errorf` for a failure that an operator must look at. Use `warnf` for an unexpected case that the phylum handled. Use `infof` for a business event, and `debugf` for detail that you need only while you investigate. `CHAINCODE_LOG_LEVEL` sets the lowest level that the chaincode writes (see [Chaincode environment variables](chaincode-environment-variables.md)). So you can leave `debugf` calls in the code, and an operator turns them on when needed.

**Put the values you search by in fields.** The first argument is a `sorted-map` of fields with string or symbol keys, or `()`. A log tool can search and group lines by a field, for example every line with `account_id=acct-1`. It cannot reliably read a value back out of free text. Keep the message a short, fixed phrase. Do not log a whole list or object: the line gets long, and nobody can search it. Log a count or an ID.

**The message is a format string.** Each `{}` in `format-string` takes the next value from `format-args`, as `format-string` does. Placeholders make a message easier to read. Put a value in a field as well when you want to search by it:

```
(cc:debugf (sorted-map "attempt" attempt) "retry {} of {}" attempt max-attempts)
```

**A wrong log call raises an error.** These calls raise one:

- A first argument that is not a `sorted-map` or `()` (`second argument is not a map`).
- A format that is not a string (`first argument is not a string`).
- A field key that is not a string or symbol (`field key with invalid type`).
- An unknown level in `log-fields` (`invalid log level`).

If no handler catches the error, the transaction fails. A log call is code like any other, so test it.

**Add a field to every line with `set-log-field`.** A transaction is often about one business object. Call `cc:set-log-field` once, at the start, with its ID. Every later line of the transaction then carries the field. So you can find all the lines of one request, and you do not repeat the ID in each call.

```
(defendpoint "withdraw" (acct-id amount)
  ;; Every later log line of this transaction carries account_id.
  (cc:set-log-field "account_id" acct-id)
  (let* ([balance (statedb:get acct-id)])
    (cond
      ((nil? balance)
       (cc:warnf () "account not found")
       (route-failure "account not found"))
      ((< balance amount)
       (cc:infof (sorted-map "balance" balance "amount" amount)
                 "insufficient funds")
       (route-failure "insufficient funds"))
      (:else
       (statedb:put acct-id (- balance amount))
       (cc:infof (sorted-map "amount" amount) "withdrawal done")
       (route-success (sorted-map "balance" (- balance amount)))))))
```

A call with `acct-id` `"acct-1"` and `amount` `40` writes a line such as `level=info msg="withdrawal done" account_id=acct-1 amount=40`.

**Log only in per-transaction code.** Call the log functions from an endpoint body, or from a function that an endpoint calls. Do not call them at the top level of a file. A log call reads the transaction context. The peer loads the phylum ahead of time, before any transaction exists. A log call at the top level stops that load until the first real transaction arrives, and the rest of the phylum then loads while that transaction waits. The `load-scope-context` check of `shirotester lint` reports such a call.

**Guard expensive debug output with `should-log`.** Lisp evaluates the arguments of a log call even when the level is off. So a `debugf` call that builds a large value does that work in every transaction. Put such a call inside `cc:should-log`:

```
(when (cc:should-log)
  (cc:debugf (sorted-map "state" (json:dump-string state)) "full state"))
```

`should-log` reads the peer's `SUBSTRATE_STATEDB_DEBUG` setting, not the log level. The two are separate switches. To see the line above, an operator sets `SUBSTRATE_STATEDB_DEBUG=true` and `CHAINCODE_LOG_LEVEL=debug`. `SUBSTRATE_STATEDB_DEBUG` also turns on a debug line for each storage operation, so use it only while you investigate. A large dump like this one belongs only behind the guard, never in a line that every transaction writes.

Peers can set `SUBSTRATE_STATEDB_DEBUG` differently. So use `should-log` only to choose what to log. If it changes a write or a response, peers return different results and the transaction cannot get its endorsements. For a phylum with flows, set `SUBSTRATE_STATEDB_DEBUG` the same on every peer of the channel. A flow version's admission check loads the phylum under the peer's own value.

[1](https://github.com/luthersystems/elps) [Ellipse (ELPS)](https://github.com/luthersystems/elps) [2](https://hyperledger-fabric.readthedocs.io/en/release-1.4/chaincode4noah.html) [Hyperledger Fabric 1.4 Chaincode](https://hyperledger-fabric.readthedocs.io/en/release-1.4/chaincode4noah.html) [3](https://hyperledger-fabric.readthedocs.io/en/release-1.4/private-data/private-data.html) [Hyperledger Fabric 1.4 Private Data](https://hyperledger-fabric.readthedocs.io/en/release-1.4/private-data/private-data.html) [4](https://tools.ietf.org/html/rfc5869) [HMAC-based Extract-and-Expand Key Derivation Function (HKDF)](https://tools.ietf.org/html/rfc5869) [5](https://tools.ietf.org/html/rfc3339) [Date and Time on the Internet: Timestamps](https://tools.ietf.org/html/rfc3339)

---
