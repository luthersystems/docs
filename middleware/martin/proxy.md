---
description: To be able to proxy the requests through a local server you need to be running a local proxy server and make sure the requests are going to that server first.
---

# Martin Proxy

## Running the test directly

The martin tests can be run in a dockerised environment or directly on your machine. In order to be able to easily proxy the request we recommend running the test directly on the machine.

The following are the instructions for installing the dependencies for running the e2e tests directly on a Darwin host:

-   Build the martin tool from [luthersystems/hyphae](https://github.com/luthersystems/hyphae/tree/main/martin) and put it on your `PATH`. See [Martin: End-to-end Testing](README.md). Martin needs no other test runner.

```
./tests/run-postman-collections-docker.sh  ./tests/Docker.postman_environment.json ./tests/document/JIRA-251-get-documents.martin_collection.yaml
```

Or using the `e2e` make target:

```
make e2e FILE=./tests/document/JIRA-251-get-documents.martin_collection.yaml
```

To run on the machine **directly**:

```
./tests/run-postman-collections.sh ./tests/LocalDev.postman_environment.json ./tests/document/JIRA-251-get-documents.martin_collection.yaml
```

Or using the `e2e-local` make target:

```
make e2e-local FILE=./tests/document/JIRA-251-get-document-summaries.martin_collection.yaml
```

---

## Running a local proxy server

There are several different application for running a local proxy server, but a popular and free one is `mitmproxy`.

Setup instructions for mac:

-   `brew install mitmproxy`
-   Run on port 8888 with web interface `mitmweb -p 8888` (for CLI `mitmproxy -p 8888`) \[in a separate shell\]
-   export HTTP\_PROXY=[http://localhost:8888](http://localhost:8888/); export HTTPS\_PROXY=[http://localhost:8888](http://localhost:8888/)

Martin sends its requests through the proxy in `HTTP_PROXY` and `HTTPS_PROXY`. For HTTPS requests, Martin must trust the proxy's certificate. Set `NODE_EXTRA_CA_CERTS` to the mitmproxy CA file, for example `~/.mitmproxy/mitmproxy-ca-cert.pem`.

After starting the proxy server and setting the env vars, you can run the tests directly on your machine. You can then navigate to the web UI if you're using the web interface and will see all the request and responses.
