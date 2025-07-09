---
description: Sandbox project.
---

# Getting Started

## Welcome to the Getting Started section

The following information will help you to start building your application right away. First, let's get your network set up.

## Network Configurator

{% embed url="<https://www.youtube.com/watch?v=GTTK2u8SQRo>" %}

## Environment Setup

### Prerequisite Tools

#### Git LFS

Git Large File Storage (LFS) replaces large files such as audio samples, videos, datasets, and graphics with text pointers inside Git, while storing the file contents on a remote server like GitHub.com or GitHub Enterprise.

You need Git LFS installed to clone this repo fully and for the tests to run. Instructions for installing Git LFS can be found here: [https://git-lfs.github.com/](https://git-lfs.github.com)&#x20;

{% hint style="info" %}
If you're using Darwin and have [brew](https://brew.sh) installed, go to your terminal and enter: `brew install git-lfs`
{% endhint %}

After cloning the repo, you need to to run `git lfs install` to setup lfs on for repo.

#### Greadlink

[Homebrew](https://brew.sh) provide a coreutils package containing greadlink (GNU readlink). This allows you to print the value of a symlink or canonical file name.

You can install it through brew with `brew install coreutils`

#### Pinata

Building the project requires Pinata, which can be obtained from [https://hub.docker.com/r/uber/ssh-agent-forward](https://hub.docker.com/r/uber/ssh-agent-forward)

Follow the four installation steps on that page, and then type `pinata-ssh-forward` to start Pinata. You don't need to worry about `pinata-ssh-mount` as the Makefile scripts do that part automatically.

Finally, you will need to load your private keys into ssh using `ssh-add`

### Git Hooks

Run the `install-git-hooks.sh` script to install git hooks after you initially clone the repository.

```
./scripts/install-git-hooks.sh
```

{% hint style="info" %}
It is best to setup Git LFS before running this script (see above for information on Git LFS).
{% endhint %}

### Formatting and linting

We recommend using [yasi](https://pypi.org/project/yasi/) for formatting lisp files.

You can install it by running: `pip3 install --upgrade yasi`

We use a specific [configuration file](https://app.gitbook.com/s/-MKuBiF8gLy8O634iN9I/application/phylum/.yasirc.json) and run it with the following flags to ensure we format consistently across the team:

`yasi --no-exit --no-backup --no-warning --no-output --indent-comments --uniform --default-indent 2 --dialect clojure <file>`&#x20;

Note that the configuration must be in the current directory for it to be automatically picked up.

We've created **format** make recipes to make it easy to run the format. You can run `make format` from the root or the phylum directory.

Additionally the git hooks will run the format command each time to ensure all the commit code is always formatted, please make sure to install the git hooks per above instructions.

#### Editor setup

You can configure your editor to run the format on every save. Note that you need to use the same config file. `yasi` will look for the config file in the current directory first, and if it doesn't find it, it will look in the home directory. You can create a soft link from your home directory to the real config file. There's a script that can do this for you, just run: `./scripts/install-yasi-config.sh`

- **VSCODE** VSCode doesn't have a builtin way of running any command on save, as of yet. However you can install this extension: [https://marketplace.visualstudio.com/items?itemName=emeraldwalk.RunOnSave](https://marketplace.visualstudio.com/items?itemName=emeraldwalk.RunOnSave) and add the following to your vscode config file:

  ```javascript
   "emeraldwalk.runonsave": {
      "commands": [
         {
         "match": "\\.lisp$",
         "cmd": "yasi --no-exit --no-backup --no-warning --no-output --indent-comments --uniform --default-indent 2 --dialect clojure ${file}"
         }
      ]
   }
  ```

- **Goland/IntelliJ**: You can use file watchers to run the above command on lisp file saves

**NOTE**: \
When you download a new version of the substrate plugin, you'll need to manually update the value of the `SUBSTRATE_PLUGIN_FILE` environment variable as it contains the version number, in the default go test config and all the existing run configurations. We recommend installing Goland 2020.1 as it adds better go modules support and features around setting default environment variable for tests which we can utilise to simplify the setup. Due to the usage of go plugin for running the substrate the build environment has to be match what it was when the substrate plugin was built. We need to replicate all the configuration in the IDE to be able to run the tests through the IDE and get syntax working correctly. \
\
**1.** Configuring `GOROOT` You need to have the exact version of go as specified in `.go-version` The easiest way to set this to required version is by installing that version of go directly, e.g. through brew on Darwin as opposed to using `goenv`. After installing the specified version, navigate to Preferences > Go > GOROOT and ensure the correct version is selected. \
\
**2**. Configuring build tags for setting up syntax highlighting in test files Navigate to Preferences > Go > 'Build Tags and Vendoring' and add `all` to the custom tags input field. We'll utilise this custom tag when setting up test configurations. \
\
**3**. Configuring the Go test template (requires at least Goland 2020.1) This will configure the defaults for test and allow you to create new valid test configs through the UI, for example when you click the run test button next to a certain test function, you'll be able to run that test without additional config. \
\
**NOTE**: Configuring the default go tests allow you to profile the code through the UI as well! There are 2 environment variables which you need to set to custom values before each test, and any go command in general; `GOPATH` and `SUBSTRATE_PLUGIN_FILE`. There's a script that automates this process however there's no way of utilising it automatically in the IDE. Run that script to download the latest substrate plugin and by looking at the exported variables, find the valid values for the `GOPATH` and `SUBSTRATE_PLUGIN_FILE` env vars (as of now the `GOPATH` value is `/tmp/substrateplugingopath`) Navigate to Run > Edit Configurations... > Templates > Go Test.&#x20;

- Set both env vars to the values you recorded in the last step.&#x20;
- Tick the 'Use all custom build tags' checkbox.&#x20;
- Add the following to the 'Go tool arguments' input box: `-parallel 50`. Feel free to experiment with this value and add additional relevant arguments in the future. Now every new test config that you create will automatically contain these 2 environment variables.&#x20;

**Optional**: A default run all configuration can be found in `./.run/go_test.run.xml` Goland will automatically load this configuration for you (requires 2020.1+) You can use it to run the tests. You may also wish to create a run configuration for the different go test tags, this will allow you to run all the tests relevant to a feature.

## Auth Flow

Sandbox is configurable to allow users to authenticate using any number of IDPs that support OAuth2 (see UserAuthentications description in the API docs).

Users specify one or more UserAuthentications which reference existing AuthenticationProviders in the system. The AuthenticationProviders define IDP settings that are used to authenticate and validate the tokens generated by the IDP.

We expect the ID Token JWT generated during the OAuth2.0 flow by the IDP to be included in the request as a cookie (under the "authorization" field). E.g.,

```
export COOKIE="authorization=$ID_TOKEN"
```

where `$ID_TOKEN` is generated by the IDP.

The oracle then cracks open that JWT and inspects the issuer (iss) and subject (sub), as well as validates the "expires at" (eat) and issued at "iat" claims.

The oracle will query the blockchain for the AuthenticationProvider settings for the specified issuer ("iss"). If the JWT validates, then the token is included in a transaction as transient data, and further on-chain validation looks up the corresponding user using the (issuer "iss", subject "sub") pair, and confirms that the user indeed has specified that AuthenticationProvider as part of their UserAuthentication. The AuthenticationProvider settings may also specify an "audience" field which is a constant that is used to compare against the "aud" claim in the token. This mechanism allows the IDP to generate tokens only to be used for a single service.

For a complete description of JWTs and these claims, see \[1].

All requests must specify an integration API Key using the "X-API-Key" header.

### Special Test Endpoints & Fake IDP

There is a special "Fake IDP" that is used to generate `ID_TOKEN`s for testing purposes. This endpoint requires your `API_KEY` to be set to a special Luther key. When testing locally, the `API_KEY` you specify in your environment will have this privileges. Example usage of the fake IDP:

```
curl -X POST -H "X-API-Key: $API_KEY" --data '{"iss":"Luther Systems Test IDP","sub":"martin","aud":"luther"}' -s localhost:8080/test/fakeidp/token  | jq
```

This will output an `ID_TOKEN` with claims "iss", "sub" and "aud", in this case allowing you to set a COOKIE that will authenticate you as the special "martin" user. See descriptions in the above section for these claims.

## Request Archiver

The request archiver feature enables archiving of request information to S3 for test environments. When enabled, archived requests can be retrieved using a test endpoint: `/test/request`. This requires a valid admin API key. To use this endpoint, supply the request as a parameter. For example:

```
curl -s -H "X-API-Key: $(aws_api_key integ)" \
  https://integration.luthersystemsapp.com/test/request?request_id=REQUEST_ID | jq
```

## Git Workflow

All tests in master branch should always pass.

- _It should always be safe to cut a release off master_.
- _Code should always be merged to master through a Pull Request (PR)_.
- _Follow the_ [_7 rules of a git commit_](https://chris.beams.io/posts/git-commit/) _and_ [_git commit message guide_](https://github.com/RomuloOliveira/commit-messages-guide)_._
- _Builds should be reproducible_.

Set your email for this repo, e.g.:

```
git config user.email "firstName.lastName@luthersystems.com"
```

Use [Feature Branch Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow).

## Upgrading Substrate Versions

Edit `SUBSTRATE_VERSION` in `common.mk`.

**NOTE** If possible the Goland configurations in `.run` also should be updated as the environment variables will now be outdated.

```

## References

\[0] [ELPS Language Guide](https://github.com/luthersystems/elps/blob/master/docs/lang.md) \[1] [RFC7519](https://tools.ietf.org/html/rfc7519)

```

                         UI
                         +
                         |
         +---------------v--------------+
         |                              +<----+ Swagger Specification:
         |             API              |       api/swagger/oracle.swagger.json
         +--------------+---------------+
         |                              |
         |        Oracle Service        |
         |     oracleserv/oracle/       |
         +---+--------------+---------+-+
             |              |
     gRPC -> |              |

+------------v------+ |
| PDF service | |
| substrate/pdfserv | |
+-------------------+ |
JSON-RPC |
+------------v-----------+
| shiroclient gateway |
| substrate/shiroclient |
+-------------+----------+
|
| JSON-RPC
+---------------------------v--------------------------+
| Phylum Business Logic |
| phylum/ |
+------------------------------------------------------+
| Substrate Chaincode |
+------------------------------------------------------+
| Hyperledger Fabric Services |
+------------------------------------------------------+

```

```
