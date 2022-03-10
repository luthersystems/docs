# Copy of Testing Guidelines

## Overview

We recommend when creating your definition of done, you declare that every piece of work must contain appropriate tests, mostly notably any bug fixes must contain a regression test. What's considered an appropriate test depends on the trade-offs between different test types.

The testing pyramid should be easily visible in your project, each testing layer involving a different set of technologies and workflows, hence the trade-offs between the various tests becomes even more important to consider.

The testing guideline below describes some of these trade-offs in detail:

There are 3 main ways to write tests in your project:

1\) ELPS \[unit] tests, which live in: `phylum/*_test.lisp`. This is an appropriate place to unit test ELPS logic.

2\) Go \[integration] tests, many of which live in: `oracleserv/X/oracle/X_test.go`. These tests are closer to integration tests, and test e2e connectivity of the chaincode (phylum) layer. This is an appropriate place for edge-case testing, and complex logic testing. These tests can run a mock blockchain ("in-memory" mode).

3\) E2E tests using the `martin` tool, which are stored under the `tests/` dir with filenames like `X.martin_collection.yaml`. These tests exercise end-to-end functionality of the oracle REST/JSON APIs using the `postman` tool. This kind of test is most appropriate in demonstrating a happy path for a story, and not edge-case or unit testing. These tests also form documentation used by the frontend team to see how a new feature works. New tests should live under a directory describing the general entity APIs that are tested, e.g, a test that exercises the documents API should live under `tests/documents`. The JIRA ticket number should be included in the test file name.

## Running tests

This section contains instructions for how to run each type of test.

### Unit \[phylum] tests

To run unit tests, you need to first ensure you're in the `phylum` directory. You can then run `make test` to run all the unit tests defined in `*_test.lisp` files.

To run all the tests in one or more test files, run:

```
$(make echo:SHIRO_TEST) *_test.lisp [...]
```

To run specific tests with a regex, use `--run` which has 'go test -run' semantics \[1]. E.g.,

```
phylum❯ $(make echo:SHIRO_TEST) --run "/regulating"
=== RUN   TestFile_scaffold
=== RUN   TestFile_scaffold/$load
--- PASS: TestFile_scaffold (1.75s)
    --- PASS: TestFile_scaffold/$load (1.75s)
=== RUN   TestFile_assertions
=== RUN   TestFile_assertions/$load
--- PASS: TestFile_assertions (0.34s)
    --- PASS: TestFile_assertions/$load (0.34s)
=== RUN   TestFile_document
=== RUN   TestFile_document/$load
--- PASS: TestFile_document (0.37s)
    --- PASS: TestFile_document/$load (0.36s)
=== RUN   TestFile_mortgage
=== RUN   TestFile_mortgage/$load
--- PASS: TestFile_mortgage (0.32s)
    --- PASS: TestFile_mortgage/$load (0.32s)
=== RUN   TestFile_permission_utils
=== RUN   TestFile_permission_utils/$load
=== RUN   TestFile_permission_utils/perm-required-over-regulating-org?
--- PASS: TestFile_permission_utils (0.70s)
    --- PASS: TestFile_permission_utils/$load (0.35s)
    --- PASS: TestFile_permission_utils/perm-required-over-regulating-org? (0.35s)
=== RUN   TestFile_utils
=== RUN   TestFile_utils/$load
--- PASS: TestFile_utils (0.34s)
    --- PASS: TestFile_utils/$load (0.34s)
```

### Integration \[go] test

Integration tests can be run via the Makefile using make targets

Specific test cases can be isolated using the helper script using `-run` and `-tags` (`-tags all` includes all tests) flags, for example:

```
./scripts/containerize.sh . go test -timeout 999m -parallel 100 -v -run=JIRA1039 -tags case ./...
```

#### Running Go tests directly on a Darwin host

This is only possible on a Darwin host and only if you have first installed the exact same version of Go as was used to build the plugin.

**IMPORTANT**: If you run tests via CLI, to easily handle multiple versions of go, please use the `goenv` tool. E.g.,

```
brew install goenv --HEAD
```

Then add following to your shell profile (e.g., \~/.zshrc):

```
export GOENV_DISABLE_GOPATH=1
eval "$(goenv init -)"
```

`goenv` (and `go`) should now use the version of go specified in `PROJECT_ROOT/.go-version` which should match the native plugin.

The script `./scripts/go-substrate-wrapper.sh` can used to prefix a command that will run with the appropriate environment to load the substrate plugin. For example:

`./scripts/go-substrate-wrapper.sh go test ./...`

NOTE: To be able to run the Go test directly with `go test`, you need to have `GOPATH` and `SUBSTRATE_PLUGIN_FILE` env vars set to appropriate values, see `./scripts/go-substrate-wrapper.sh` for more details.

#### Running Go tests from your favorite editor

If your favorite programming editor supports launching go tests, and if your programming editor properly forwards environment variables, it should be possible to launch your favorite programming editor via the substrate wrapper script and have it launch go tests directly:

`./scripts/go-substrate-wrapper.sh nvim`

To run `./scripts/go-substrate-wrapper.sh`, your current working directory must be the repository root.

For Goland specific instructions see the Goland IDE setup section in the root README.

### End-to-end \[martin] tests

For e2e testing, you can launch the oracles and run fabric in several modes, described below. Make sure to set an env var `API_KEY` in the same shell you use to bring up the network and to have run `pinata-ssh-forward`.

Here are the steps for running the martin tests;

1. `cd` into the root directory of the project.
2. `pinata-ssh-forward`
3.  `export API_KEY=abc123`

    &#x20;The value can be set to anything, it just need to be set before starting

    &#x20;the oracle and should also be set when running the e2e tests.
4. `make mem-up` or `make up` for full version. (See below for explanation of the difference)
5. `make e2e FILE=./tests/document/JIRA-251-get-documents.martin_collection.yaml` replacing FILE with the file you'd like to run.

#### Debugging E2E tests

You can add additional console.logs in your tests to better see what's being returned however it's typically very useful to proxy all the requests to the oracle through a local proxy and watch the response and requests directly.

You can find instructions for how this can be setup here: [Setting up a proxy for martin tests](https://app.gitbook.com/s/-MKuBiF8gLy8O634iN9I/application/setting-up-proxy.md)

Oracles in the environment serve the broker and client oracle off of different urls which necessitates&#x20;

#### Various methods for starting martin tests

There are a few different ways to run the martin tests, the `make e2e` and `make e2e-local` targets are shortcuts for 2 common ways of running these tests.

These make targets take an optional FILE argument, which if not provided will mean the targets will run all the tests.

The `e2e` target will run the tests in a docker environment, meaning less setup is necessary to be able to run them; `e2e-local` will run the tests directly on your machine, which means certain binaries must be installed. [Setting up a proxy for martin tests](https://app.gitbook.com/s/-MKuBiF8gLy8O634iN9I/application/setting-up-proxy.md) contains instructions for setting up these binaries (and explanation of why you might want to do that.)

Alternatively, you can run the martin tests more directly. For example the following

```
./tests/run-postman-collections-docker.sh  ./tests/Docker.postman_environment.json
```

will run all of the `martin` tests under the `tests/` directory using the local docker configuration. To run a specific test you can pass the file as a 2nd argument:

```
./tests/run-postman-collections-docker.sh  ./tests/Docker.postman_environment.json ./tests/document/JIRA-251-get-documents.martin_collection.yaml
```

#### make mem-up vs make up

The oracle can be run locally in memory mode or replicate a full network.

`make mem-up` will run the oracle in in-memory mode which emulates fabric directly within the oracle process, this is a light-weight and fast way of running tests and does not require launching the entire fabric network.

`make up` will run a local network which launches a full fabric network locally. This is a heavier method, but more accurate/realistic way of testing.

After running either, you can execute `docker ps` to list which services are running. You can also use `docker logs $CONTAINER_NAME` to dump the logs for that container. E.g.,

```
docker logs oracle
```

Remember that when running the oracle locally, the REST/JSON API is accessible from your localhost on port 8080. You can issue CURL commands to spot test locally, so long as you have set your `API_KEY` and `COOKIE` env variables. For example,

```
time curl -X GET -H "X-API-Key: $API_KEY"  --cookie "$COOKIE" -s http://localhost:8080/v1/luther/system_metrics | jq ''
```

## Testing Guidelines

This section contains testing guidelines that we recommend you follow in your repo.

### Unit \[phylum] tests

* Critical functions should be unit tested, especially if they're stateless and are easier to setup state for
* Functions that take in large states, such as a case having passed certain verifications and being at a certain stage, are typically not unit tested due to difficulty of building up such state (Integration tests are ideal for these), however there are exceptions when the functionality is critical, e.g. calculations.
* Break up large functions into **composition** of smaller functions. This will allow smaller function to be unit tested when needed and increase readability and maintainability.
* Migrations are primarily tested via unit tests.

### Integration \[go] test

* Use t.Run wherever possible to breakup the tests. This will allow others to run segments of a tests rapidly when debugging a broken test.
* Use/create helper functions for setting up state: This will help with readability and maintainability. For example consider that we may change the requirements for common operations, and we don't want to have to update a lot of tests that repeat the same operation.
* If the helper function is generic enough, it should be placed in oracle\_test.go
* Give every test a descriptive name. Remember, a test's value is in helping find the relevant unit/line when it fails. By giving them a descriptive name, we can hint at what the purpose of the test is. Avoid names like AC\* and etc.
* Add ticket numbers for a test as a comment above the test, not in its name. For very long/old tests, placing the ticket number in the test name gets very confusing and doesn't help much. A descriptive name is much preferred, if a developer would like to find the ticket number they can look at the comment or use git blame

### End-to-end \[martin] tests

* These are more of smoke tests
* Cover essential/critical paths
* Try to replicate realistic configurations
