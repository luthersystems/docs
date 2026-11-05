---
description: Settings an operator can apply to the substrate chaincode container.
---

# Chaincode Environment Variables

Substrate runs as a Fabric external chaincode ("chaincode as a service"). Its
behaviour is configured with environment variables set on the chaincode
container — the same container that runs the `luthersystems/substrate` image.

There are two families, and they are read by different parts of the process:

- **`CHAINCODE_*`** — the container entrypoint's own settings. Every one of
  these has an equivalent command-line flag, and each may also be supplied
  through a config file (see [Config file](#config-file)).
- **`SUBSTRATE_*` and `ELPS_*`** — settings read directly by the chaincode
  process and the ELPS runtime inside it. These have no flag equivalent.

## Setting them

Set them like any other container environment variable. With a Compose-managed
network:

```yaml
services:
  peer0-chaincode:
    image: luthersystems/substrate:$CHAINCODE_VERSION
    command: ["$CCID"]
    environment:
      CHAINCODE_LOG_LEVEL: info
      CHAINCODE_OTLP_TRACER_ENDPOINT: http://trace_host:4317
```

Under an orchestrator, use whatever that platform provides for container
environment (a Kubernetes `env:` block, an ECS task definition, and so on).

> **Set compatibility settings uniformly across every peer of a channel.**
> The settings marked *compatibility hatch* below change how a phylum
> executes. Peers configured differently can compute different results for the
> same transaction, which surfaces as an endorsement mismatch rather than as a
> slow or failed peer. Roll them out to every peer at once.

## Entrypoint settings (`CHAINCODE_*`)

| Variable | Default | What it does |
| --- | --- | --- |
| `CHAINCODE_LISTEN_ADDR` | `:8080` | Address the chaincode service listens on for the peer's connection. |
| `CHAINCODE_LOG_LEVEL` | `info` | Log verbosity. Accepts `trace`, `debug`, `info`, `warn`, `error`, `fatal`, `panic`. |
| `CHAINCODE_PROM_LISTEN_ADDR` | `:9600` | Address the Prometheus metrics endpoint listens on. The same address serves the Go pprof profiles under `/debug/pprof/`, with no authentication, so keep it inside the cluster. |
| `CHAINCODE_OTLP_TRACER_ENDPOINT` | unset | gRPC OTLP tracing endpoint, for example `http://trace_host:4317`. Tracing is off when unset. |
| `CHAINCODE_NO_ELPS_FILTER` | `false` | Trace *every* ELPS function instead of only documented ones. Substantially increases trace volume; intended for diagnosis, not steady state. |
| `CHAINCODE_PREHEAT_CACHE_SIZE` | `0` (built-in default) | How many preheated environments to keep ready. |
| `CHAINCODE_PREHEAT_NUM_WORKERS` | `0` (built-in default) | Size of the worker pool that fills the preheat cache. |
| `CHAINCODE_PREHEAT_TIMEOUT` | `0` (built-in default) | Time budget for preheating/initialising a phylum, for example `6s`. |
| `CHAINCODE_PREHEAT_NO_FORK` | `false` | Rollback lever: build every environment from scratch instead of forking a per-phylum template. Slower by a wide margin; set only if the fast path is implicated in an incident. |
| `CHAINCODE_RATE_LIMIT_QUEUE_SIZE` | `0` (built-in default) | Depth of the request rate-limiter queue. |
| `CHAINCODE_CONFIG` | `/opt/chaincode.yaml` | Path to the config file. |

A `0` or empty default means *the setting is unset and the built-in default
applies* — it does not mean the value is literally zero.

### Config file

Any `CHAINCODE_*` setting can instead be written to a YAML config file, read
from `/opt/chaincode.yaml` by default. Drop the `CHAINCODE_` prefix and use
the flag spelling:

```yaml
log-level: info
preheat-timeout: 6s
otlp-tracer-endpoint: http://trace_host:4317
```

The environment variable wins over the config file when both set the same key.

## Runtime settings (`SUBSTRATE_*`, `ELPS_*`)

These are read by the chaincode process itself rather than by the entrypoint.

**Every one of them accepts only the exact string `true` to enable it.**
`TRUE`, `True`, `1`, `yes` and a value with stray whitespace are all ignored,
and the setting stays off. This is deliberate: a typo fails safe rather than
silently changing how transactions execute.

| Variable | What it does |
| --- | --- |
| `SUBSTRATE_ALLOW_PHYLUM_TESTING_PACKAGE` | *Compatibility hatch.* Restores the `testing` package to production environments. As of v2.235.0 a phylum whose production load graph reaches that package **at load scope** fails to load with `unknown package: testing`; this keeps such a phylum running while it is migrated. The remedy is to move the offending file into the phylum's test-loaded set, not to leave this set. What it costs: test-only forms (`test`, `assert-*`) become reachable from production phylum code, and that has no mitigation. Also set it the same way wherever `shirotester preheat-check` runs — otherwise a phylum can pass the check and still fail to load on the peers; the check prints a `NOTE` when it runs with this set. Announces itself once in the process log. |
| `SUBSTRATE_ALLOW_PHYLUM_LITERAL_MUTATION` | *Compatibility hatch.* Restores the pre-v2.231.0 phylum parse-cache behaviour for a phylum that mutates its own quoted program literals — a pattern the sealed cache otherwise rejects with `modify-literal-error`. Intended to keep a channel running while the phylum is corrected, not as a permanent setting. Announces itself once in the process log when set. |
| `SUBSTRATE_ALLOW_TIMESTAMP_OVERRIDE` | Lets a client override the transaction timestamp by supplying a `timestamp_override` transient field. Off by default and rarely used; leave it off unless a specific integration requires it. |
| `SUBSTRATE_STATEDB_DEBUG` | Enables state-database debug logging. Phylum code can test for it through the `should-log` builtin. Diagnostic only — it is verbose. |
| `SUBSTRATE_LOG_LEVEL` | Log level for the packaged binary entrypoint, accepting the same values as `CHAINCODE_LOG_LEVEL`. Defaults to `info`. Prefer `CHAINCODE_LOG_LEVEL` on a standard external-chaincode deployment. |
| `SUBSTRATE_OTLP_ENDPOINT` | OTLP endpoint used by the substrate host binary. Prefer `CHAINCODE_OTLP_TRACER_ENDPOINT` on a standard external-chaincode deployment. |

## Debugger settings (`ELPS_DAP_*`)

These start a Debug Adapter Protocol server inside the chaincode process so an
editor can attach to running ELPS code.

> **Do not set these in production.** The debugger can halt execution and it
> listens on a local port. They exist for development and for controlled
> reproduction of a defect.

| Variable | What it does |
| --- | --- |
| `ELPS_DAP_PORT` | Port for the DAP server, on `localhost`. Unset disables the debugger entirely. Ignored with a log line if the value is not a number. |
| `ELPS_DAP_WAIT` | `true` waits for a debugger to attach before proceeding. |
| `ELPS_DAP_STOP_ON_ENTRY` | `true` breaks on the first form evaluated. |

## Verifying a setting took effect

The compatibility hatches log once, at startup, when they are enabled — the
absence of that line means the setting did not take. That is the quickest way
to catch a misspelled value, since an unrecognised value is ignored rather
than rejected.
