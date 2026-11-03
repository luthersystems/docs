---
description: Martin runs end-to-end API tests. You write tests as Martin YAML or Postman JSON collections, and Martin runs them with its own Go engine.
---

# Martin: End-to-end Testing

Martin runs end-to-end API tests. You write tests as Martin YAML collections (`*.martin_collection.yaml`) or Postman JSON collections (`*.postman_collection.json`). Martin runs them with its own Go engine and an embedded JavaScript sandbox. It does not use Node or Newman.

The source and the full reference are in the Martin README of [luthersystems/hyphae](https://github.com/luthersystems/hyphae/tree/main/martin).

---

## Install

Use the `luthersystems/martin` Docker image. Pin an image tag. The `latest` tag changes when a new version is released. In a project made from the sandbox, set `MARTIN_VERSION` in `common.config.mk`.

To build the binary, run this command from the hyphae repository root:

```
CGO_ENABLED=0 go build -o build/martin ./martin
build/martin --help
```

---

## General workflow

1. Check your collections for features that Martin does not support. `martin vet` does not send requests or run scripts. It exits 1 when it finds an unsupported feature:

```
martin vet --pre tests/init.yaml tests/*.martin_collection.yaml
```

2. Run the collections against an environment:

```
martin run -e tests/LocalDev.postman_environment.json --pre tests/init.yaml -i 1 tests/*.martin_collection.yaml
```

3. To combine collections into one Postman collection file, use `cat`:

```
martin cat --name Basic tests/*.martin_collection.yaml > collection.json
```

`run` validates all files before it sends a request. An unsupported feature or a load error in any file stops the whole run.

### Run options

| Option | Effect |
|---|---|
| `-e FILE` | Environment file with placeholder values |
| `-p`, `--pre FILE` | Collection that runs before each iteration of each run, for example a login step |
| `-i N`, `--iterations N` | With more than one file, each file runs once, then the combined collection runs N times. The default is 0, so the combined run executes no requests |
| `-r`, `--batch-run` | Run only the combined collection |
| `-b`, `--bail` | Stop the run after a failure. The default is true |
| `--parallel N` | Run up to N files at the same time. The default is 1. Use it only for files that do not depend on each other's server-side effects |
| `--reporters cli,junit`, `--reporter-junit-export FILE`, `--report-json FILE` | Write JUnit and JSON reports for all runs |
| `--deny-private-networks` | Refuse connections to loopback, private, link-local and other reserved addresses. Off by default. Do not use it against local test servers |

---

## Test cases

A test case has one or more steps. Put each test case in its own YAML file. A test case can contain placeholders. Martin replaces them with values from the environment file when it runs the test.

---

## Environment

An environment file holds the placeholder values for one environment. It uses the Postman environment JSON format. Give the file to `martin run` with `-e`.

Example:

```
{
    "id": "8b7b1d43-0e23-4c8b-817a-f391b973acf7",
    "name": "Local Dev",
    "values": [
        {
            "key": "SCHEME",
            "value": "http",
            "description": "",
            "enabled": true
        }
    ]
}
```

---

## Format

Fields of a test case:

-   `name`: Name of the test case. This is the name of the folder in the collection.
-   `headers`: Headers that every step sends.
    -   `key`: Header name.
    -   `value`: Header value. Martin replaces placeholders with values from the environment file.
-   `tests`: List of test steps. Each step is one request.
    -   `name`: Name of the step.
    -   `path`: Request path. Martin adds the scheme and server to make the URL.
    -   `method`: HTTP method.
    -   `body`: Request body, sent as written.
    -   `test_script`: Test assertions in JavaScript.

### Test scripts

Test scripts use the Postman script API. These are supported:

-   `pm.test`, `pm.test.skip` and `pm.expect` (Chai 4.4.1)
-   Variables, and response JSON, text and headers
-   lodash 4 (`require('lodash')`), UUID, `atob`, `btoa` and timers

These are not supported. A script that uses one fails, also when the script catches the error:

-   `pm.sendRequest`
-   Changes to the request
-   Cookies in scripts
-   Async `pm.test(done)`
-   `Intl` and locale methods

---
