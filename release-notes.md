---
description: Versioned releases of platform artifacts and their changes.
---

# Release Notes

## 2022-06-09: substrate 2.173.0-fabric2

* **shirocore**: remove performance improvement cache that was added in substrate 2.172.0-fabric2 release due to new bug introduced reading only the first toset when iterating a tomulset

## 2022-06-09: substrate 2.172.0-fabric2

* **shirocore**: performance bug fix concerning storage-toset-next-iters & storage-toset-next-iter-fill-page duplicate iteration
* **golang**: bump golang to 1.16.15

## 2022-06-06: buildenv v0.0.55

* **godynamic**: fix aws-cli install
* **js**: add better support for `aws help` command
## 2022-06-03: buildenv v0.0.54

* **godynamic**: fix azure-cli install
* **js**: include python for `node-gyp` support

## 2022-05-26: buildenv v0.0.53

* **go-static**: use alpine, remove TINI vars

## 2022-05-26: buildenv v0.0.52

* **internal**: CI/CD release improvements

## 2022-05-25: buildenv v0.0.51

* **internal**: major changes to facilitate migration to github and circle CI
* **multi-architecture**: add multi-arch builds for amd64 and arm64
* **api**: remove `prototool`, add `buf`
* **go**: add `staticcheck` tool
* **go**: add `jq` tool
* **all**: fetch certificates from official `ca-certificates` package
* **all**: fetch time zone data from official `tzdata` packages
* **debian**: do not include suggested packages by default
* **go-extra**: use ubuntu 20.04
* **static go builds**: include build tags for time zone data

## 2022-04-28: buildenv v0.0.50
*IMPORTANT*: All builds after this release include the `v` prefix in the tag,
whereas before they were omitted (`0.0.50` vs `v0.0.50`).
* **godynamic**: upgrade azcli to 2.35.0

## 2022-04-01: substrate v2.171.0-fabric2 Release

* **substrate**: fix buildpack for external chaincode

## 2022-03-31: substrate v2.170.0-fabric2 Release

* **buildenv**: bump to 0.0.49
* **hyphae**: use public github for libhandlebars
* **shiroclient**: add dependent TX ID logging
* **shiroclient**: bump shiroclient-sdk-go to `ac2085246995`

## 2022-03-23: buildenv v0.0.49

* **alpine**: bump alpine to 3.15
* **golang**: bump golang to 1.16.14

## 2022-03-17: buildenv v0.0.48

* **alpine**: remove old patches to fix security updates which are superfluous

## 2022-03-11: substrate v2.169.0-fabric2 Release

* **shiroclient:** improve retry logic for handling transaction commit timeouts
* **substrate:** fix bug in `decimal-add-money`
* **substrate:** remove `set-now` function from utils
* **libmxf:** release 0.0.4 mxf npm package with decryption bugfix

## 2022-02-25: buildenv v0.0.47

* **godynamic**: add curl

## 2022-01-26: substrate v2.168.0-fabric2 Release

* **shirocore:** add list support in `elpspath`
* **shiroclient:** improve verbose mode (-v)

## 2022-01-10: substrate v2.167.0-fabric2 Release

* **fabric network builder**: Compatibility changes for use in containerized setups
* **mxf**: add public [npm package](https://www.npmjs.com/package/mxf) for decoding mxf encrypted data off-chain
* **substrate**: minor bug fixes

## 2021-12-10: buildenv v0.0.46

* **api**: remove api swagger bindata generation
* **godynamic**: fix azure cli build

## 2021-11-18: substrate v2.166.0-fabric2 Release

* **shirocore:** add `mxf-private-export` function
* **substrate**: push `luthersystems/buildpack` to dockerhub for external chaincode initialization&#x20;

## 2021-11-12: substrate v2.165.0-fabric 2 Release

* **substrate**: fix chaincode tar build issue introduced in v2.164.0-fabric2

## 2021-11-08: substrate v2.164.0-fabric2 Release

* **hyphae**: add `to-int` helper to `libhandlebars` to convert types to int.
* **substrate**: add external chaincode builds (dockerhub: luthersystems/substrate).

## 2021-10-15: substrate v2.163.0-fabric2 Release

* **shirocore:** Allow `cc:creator` in `init` endpoint in mock mode
* **shirocore:** Fix `find-pos` and `find-pos-cmp` bug to correctly return `-1` when the index is not found.

## 2021-09-23: substrate v2.162.0-fabric2 Release

* **substrate**: Add env variable SUBSTRATE\_LOG\_LEVEL to change log level

## 2021-09-14: buildenv v0.0.45

* **go-alpine**: use static binary dependencies

## 2021-09-13: buildenv v0.0.44

* **service-base-alpine**: update artifacts
* **alpine**: apply security updates
* **go-alpine**: remove `GOPRIVATE` config

## 2021-08-23: buildenv v0.0.43

* **go-alpine**: add go-alpine image

## 2021-07-27: buildenv v0.0.42

* **go:** Change user and owner of built artifacts using ${DOCKER\_CHOWN\_USER} ${DOCKER\_CHOWN\_GROUP} environment variables

## 2021-07-19: substrate v2.160.0-fabric2 Release

* **hyphae:** Add `to-str` helper to libhandlebars
* **hyphae:** Add `GetPipeHTTP` to `s3` package to retrieve stream of bytes.
* **hyphae:** Add cookie retrieval interface for magic links&#x20;

## 2021-07-01: buildenv v0.0.41

* **godynamic:** Use alpine 3.13 as a stable base.&#x20;

## 2021-06-23: substrate v2.159.0-fabric2 Release

* **elps**: Upgrade to v1.14.0.
* **fabric network builder**: Add `cert_expires` subcommand to list expiration dates of certificates
* **fabric network builder**: Add mutli-step certificate generation process for improved customizaiton (make generate-template, make generate-assets).
* **buildenv:** Upgrade to v0.0.40.

## 2021-06-16: buildenv v0.0.40

* **api, go, godynamic, goextra:** Cleanup build tags into common configuration.&#x20;
* **api:** Allow including protos in custom directories.&#x20;

## 2021-06-09: elps v1.14.0

* **json:** Use custom json encoder for improved performance.
* **json:** Reduce allocations during map serialization.&#x20;
* **types:** Add ability to write user-defined data types.
* **types:** Update `libschema` to support user-defined data types.
* **macros:** Fix bugs related to macro expansion.

## 2021-06-09: buildenv v0.0.39

* **api. go, godynamic, goextra:** Properly parameterize go versions.
* **api:** Fix typo in make targets and add missing make targets.&#x20;

## 2021-05-26: buildenv v0.0.38

* **all:** Continue to push images to ECR for backwards compatibility.&#x20;

## 2021-05-25: buildenv v0.0.37

* **api**, **go, godynamic, goextra, java, js, swaggercodegen:** Use `tini` for signal handling in the default image entrypoint.
* **api. go, godynamic, goextra:** Upgrade to go1.16.4.

## 2021-05-14: substrate v2.158.0-fabric2 Release

* **fabric network builde**r: Add `fnb-extend` command to generate certs for new orgs.
* **fabric network builder:** Use version 2.2.0 of fabric cryptogen (names private keys `priv_sk` among other changes).
* **fabric network builder:** Use client authentication (mutual TLS).
* **shirocore**: Fix `set-exception-wrapped` to properly wrap exception messages and re-throw them.
* **shiroclient gateway:** Add additional log lines to help debugging.
* **shiroclient gateway**: Retry tx simulation on chaincode 500 error, for increased resilience.&#x20;
* **shiroclient gateway:** Move shiroclient-sdk-go to [github](https://github.com/luthersystems/shiroclient-sdk-go).&#x20;

## 2021-03-30: substrate v2.157.0-fabric2 Release

* **shiroclient gateway:** Improve reliability of event service connectivity.
* **shirocore:** Throw phylum errors during chaincode-to-chaincode (invoke-phylum) failures.&#x20;

## 2021-03-16: substrate v2.156.0-fabric2 Release

* **shirocore**: Fix bug in internal minifer for elps symbols.&#x20;
* **mock substrate:** Improve support for parallel go tests.&#x20;

## 2021-03-05: substrate v2.155.0-fabric2 Release

* **shiroclient gateway:** Improve metrics logging during tx commit.
* **shirocore:** Fix bug in `tx-pre-hooks` execution, which sets up shirocore env before application code runs.&#x20;

## 2021-03-04: substrate v2.154.0-fabric2 Release

* **mock substrate:** Fix mock-specific methods.
* **shirocore:** Fix symbol references in `def-migration-up`
* **fabric network builder:** Fix nchoose2 sample networks and Makefiles.

## 2021-03-01: substrate v2.153.0-fabric2 Release

* **elps:** Upgrade to v1.13.1&#x20;

## 2021-02-25: elps v1.13.1 Release

* **elpstest**: Fix timing for `$load` benchmark.

## 2021-02-19: substrate v2.152.0-fabric2 Release

* **shirocore:** Fix bug in `ymd` date validations

## 2021-02-19: substrate v2.151.0-fabric2 Release

* **shirocore:** Pre-load (pre-warm) phyla to improve load times

## 2021-02-17: substrate v2.150.0-fabric2 Release

* **mock substrate:** Fix concurrency bug in plugin.

## 2021-02-11: substrate v2.149.0-fabric2 Release

* **mock substrate**: Refactor internal libraries to better support hashicorp plugin.

## 2021-02-09: substrate v2.148.0-fabric2 Release

* **mock substrate:** Add healthcheck to Hashicorp plugin.

## 2021-02-08: substrate v2.147.0-fabric2 Release

* **fabric network builder:** Fix nchoose2 network generation.&#x20;

## 2021-02-05: substrate v2.146.0-fabric2 Release

* **fabric network builder:** Add support for nchoose2 vanity names.

## 2021-02-08: buildenv v0.0.36 Release

* **all:** Add public docker make targets.

## 2021-02-03: substrate v2.145.0-fabric2 Release

* **shirocore:** Add jaeger support for request tracing.
* **buildenv:** Upgrade to v0.0.34.

## 2021-01-29: buildenv v0.0.35 Release

* **godynamic:**  Add azure cli.
* **js:** Add azure cli.
