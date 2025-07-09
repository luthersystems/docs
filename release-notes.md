## 2025-06-24: substrate v2.205.13

- **substrate**: Add general mock settings
- **connectorhub**: Add Luther connectors

## 2025-06-23: substrate v2.205.12

- **connectorhub**: Fix connectorhub protos and add rich connector annotations
- **connectorhub**: Add new and remaining connector annotations, enums, categories, icons, and logos; update connector keys, config, and category order; ensure consistency in naming and file conventions
- **connectorhub**: Fix typos, indentation logic, and comments; update README
- **substrate**: Attempt to fix shirotester unit-test race, memory leak, isolation, and shared mode

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

## 2025-02-14: substrate v2.205.7

- **substrate**: Disable write polling by default
- **connectorhub**: Add connector lib

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

## 2024-08-01: substrate v2.205.2

- **substrate**: Improve block cache logging, and recording of trace requests

## 2024-07-24: substrate v2.205.1

- **shiroclient**: Add missing block cache optimization
- **substrate**: Add initial profile guided optimization (PGO) to substrate

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

## 2024-02-15: substrate v2.197.1

- **substrate**: bump deps
- **shiroclient**: use `otelhttp` http server for gateway

## 2024-02-12: substrate v2.197.0

- **substrate**: add ratelimiter
- **shiroclient**: fix span tree
- **substrate**: add profile tracing to `defendpoint`
- **substrate**: improve tracing support

## 2024-02-05: substrate v2.196.0

- **shiroclient**: fix race condition on commitment
- **substrate**: make preheat workers configurable, revert preheat cache size change
- **substrate**: add `elps doc` trace filters
- **substrate**: add better context threading
- **substrate**: improve tracing support

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

## 2023-12-04: substrate v2.193.0

- **shiroclient**: Add shiroclient block and transaction (chaincache) cache to reduce waiting times
- **shiroclient**: Improve shiroclient retry logic
- **shiroclient**: Add support for DependentBlock
- **shiroclient**: Improve context canceled handling
- **shiroclient**: Support WithPhylumVersion

## 2023-11-13: substrate v2.192.3

- **shiroclient**: optimize wait logic to avoid redundant waits

## 2023-10-31: substrate v2.192.2

- **buildpack**: support HLF2.5 binaries

## 2023-10-27: substrate v2.192.1

- **shiroclient**: reduce default commit timeout to 3s
- **shiroclient**: improve context canceled logging

## 2023-10-23: substrate v2.192.0

- **shiroclient**: fix retry backoff

## 2023-09-05: substrate v2.191.0

- **shiroclient**: make client connection keep alive (platewarmer) optional (client.plate-warmer = false)
- **substrate**: support purge of private data on HLF2.5
- **externalcc**: add pprof endpoint

## 2023-08-14: substrate v2.190.1

- **shiroclient**: do not error log OK errors
- **shiroclient**: reduce verbosity of INFO messages

## 2023-07-26: substrate v2.190.0

- **shiroclient**: improve context canceled error handling
- **shiroclient**: improve error logging

## 2023-07-19: substrate v2.189.0

- **private library**: add support for skipEncodeTx optimization

## 2023-07-18: substrate v2.188.0

- **upgrade**: elps to 1.16.2

## 2023-07-13: substrate v2.187.0

- **update**: tar artifact permissions

## 2023-07-13: substrate v2.186.0

- **upgrade**: golang to 1.20.4
- **upgrade**: buildenv to v0.0.67

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

## <br><br>

## 2023-05-01: buildenv v0.0.62

- **General**: Move to github
- **Golang**: Update go to 1.20.3, alpine to 3.17

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

- **\*shirocore**: add list support in `elpspath`
- **shiroclient**: improve verbose mode (-v)

## 2022-01-10: substrate v2.167.0-fabric2 Release

- **fabric network builder**: Compatibility changes for use in containerized setups
- **mxf**: add public [npm package][1] for decoding mxf encrypted data off-chain
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

- **go**: Change user and owner of built artifacts using ${DOCKER_CHOWN_USER} ${DOCKER_CHOWN_GROUP} environment variables

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
- **shiroclient gateway**: Move shiroclient-sdk-go to [github][2].

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

- **mock substrat**e: Refactor internal libraries to better support hashicorp plugin.

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

[1]: https://www.npmjs.com/package/mxf
[2]: https://github.com/luthersystems/shiroclient-sdk-go
