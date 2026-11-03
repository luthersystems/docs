---
description: The eMudhra (emSign) CA compromise (CVE-2026-111943), what Luther changed, and the versions to use.
---

# Security Notice: eMudhra (emSign) CA Distrust

Published 2026-10-22. Updated 2026-10-23: new Docker chaincode images
([fabric-ccenv and fabric-baseos](#docker-chaincode-fabric-ccenv-and-fabric-baseos)),
how to set them on the peer (mars v0.143.0), a [check section](#how-to-check-the-fix), the latest versions, and the [image digests](#image-digests). Tracker:
[luthersystems/buildenv#163](https://github.com/luthersystems/buildenv/issues/163).

**Action:** upgrade every Luther image, tool and Go library to the version in
the tables below, and build your own Go code with Go 1.26.10 or later. The
[Release Notes](release-notes.md) list each release.

## Summary

| Item | Detail |
|---|---|
| **Issue** | The private keys of eight intermediate certificate authorities (CAs) of eMudhra (emSign), a public CA, leaked |
| **Scope** | Industry-wide. It affects every operating system, browser, language runtime and container image that trusts the public CAs. It is not a Luther security incident |
| **Identifiers** | CVE-2026-111943, [GO-2026-6809](https://pkg.go.dev/vuln/GO-2026-6809), [golang/go#82345](https://github.com/golang/go/issues/82345), [Mozilla bug 2083449](https://bugzilla.mozilla.org/show_bug.cgi?id=2083449) |
| **Risk** | A holder of a leaked key can issue a certificate for any host name or any code signer. A client that trusts the chain accepts it |
| **Luther fix** | Luther images remove or block 25 certificates in every trust store. Luther Go programs are built with Go 1.26.10, which refuses the leaked intermediates |
| **Your action** | Upgrade to the versions on this page. Set the Helm chart image versions in [Helm charts: AWS CLI and Docker](#helm-charts-aws-cli-and-docker). On a peer that runs Docker chaincode, set the [chaincode images](#docker-chaincode-fabric-ccenv-and-fabric-baseos) |

## Industry context

eMudhra is a public CA. Operating systems, browsers and language runtimes
trusted its emSign root CAs. When the intermediate keys leaked, the browser
and operating system vendors removed the emSign roots (Mozilla NSS 3.131.1
and later) and the Go team added a block list to Go 1.26.10.

Every organization that runs software with its own copy of the public CA
list must update that copy. This includes container images, Java runtimes,
Python packages and Node.js. The issue is not in Luther code, and no Luther
system was breached. Luther changed its images and builds so that they do
not depend on the update schedule of each upstream vendor.

## What the threat is

A CA certificate lets its key holder sign certificates that clients trust.
With a leaked intermediate key, an attacker can issue a valid certificate for
any domain. Then the attacker can intercept TLS traffic, for example to an AWS
API, a Git host or a package registry. The leaked keys include one code-signing
CA (EM OV CS CA), so signed code is also at risk.

Removing the emSign root CAs from a trust store is not sufficient. Sectigo
(Comodo) "AAA Certificate Services" cross-signed the same intermediates with
the same keys. A system that still trusts AAA Certificate Services accepts the
leaked intermediates through that root. Mozilla removed website trust from
AAA Certificate Services in April 2025, so Ubuntu 24.04 and Python certifi
2025.4.26 and later no longer hold it. Many bundles still do, for example
Debian 12 and 13 (and so the official Debian-based images), Ubuntu 20.04, and
JDK cacerts files.

Each runtime also has its own trust store. Java, Python certifi, Node.js and
Chrome (NSS) do not read the operating system bundle by default. A fix that
changes only `/etc/ssl/certs` leaves those runtimes exposed.

## What Luther changed

The fix has two parts, because Go programs and the other runtimes verify
certificates in different ways.

| Part | What it does | Where |
|---|---|---|
| Go 1.26.10 | Go's `crypto/x509` refuses any chain that holds one of the 8 leaked public keys, whatever CA store the program uses. It checks the key, not the certificate, so it also refuses every cross-signed copy | Every Luther Go service, tool and library release on this page |
| Image trust stores | Each image removes the emSign roots and AAA Certificate Services from every trust store. It blocks every listed certificate in the OS bundle, Java (`blocked.certs`), Python certifi, Node.js and Chrome/NSS. The image build fails if any listed certificate still verifies, on amd64 and arm64 | Every Luther image on this page |

The images block 25 certificates:

| Group | Count | Certificates |
|---|---|---|
| emSign roots | 6 | emSign Root CA - G1, emSign Root CA - C1, emSign ECC Root CA - G3, emSign ECC Root CA - C3, emSign Root TLS CA - G3, emSign Root CS CA - G3 |
| eMudhra intermediates | 18 | EM DV TLS CA, EM OV TLS CA, EM EV TLS CA and EM OV CS CA (G3B and G3C), each in its emSign-issued and its AAA cross-signed copy (16), and the two emSign G3 roots as cross-signed by emSign ECC Root CA - G3 (2) |
| Cross-signing root | 1 | AAA Certificate Services (Sectigo/Comodo) |

The [certificate list](https://github.com/luthersystems/buildenv/blob/main/images/harden/policy/ca-distrust.list)
gives the SHA-256 fingerprint and crt.sh link of each certificate.

Current Sectigo certificates chain to the USERTrust roots. Those roots stay
trusted, so blocking AAA Certificate Services does not break current Sectigo
sites.

### How this compares with the Go fix

The image policy has the same aim as the Go team's fix, and it covers more:

| | Go 1.26.10 | Luther images |
|---|---|---|
| Blocks the 8 leaked intermediate keys | Yes, by public key | Yes, each of the 16 certificates that carry them |
| Removes the 6 emSign roots | No | Yes, as Mozilla NSS 3.131.1 does |
| Removes AAA Certificate Services | No | Yes |
| Applies to | Go programs only | Every trust store in the image: OS bundle, Java, Python, Node.js and Chrome |

Most runtimes cannot block a certificate by its public key, so the images
block each certificate that carries a leaked key. They also remove the
roots that issued or cross-signed the intermediates, so a certificate the
list does not name cannot chain through them.

## What to do

1. Read the [Release Notes](release-notes.md) for each version you
   upgrade across. Follow each **Upgrade note** before you upgrade.
2. Upgrade each Luther image to the version in [Containers](#containers).
3. Upgrade each Luther Go library to the version in
   [Go libraries](#go-libraries).
4. Build your own Go code with Go 1.26.10 or later. A newer library version
   alone does not give the Go fix, because the Go version that builds the
   program decides it.
5. Set the image versions of the Helm charts. See
   [Helm charts: AWS CLI and Docker](#helm-charts-aws-cli-and-docker).
   If a peer runs Docker chaincode, set its chaincode images. See
   [Docker chaincode](#docker-chaincode-fabric-ccenv-and-fabric-baseos).
6. Plan to move off the deprecated items, and stop using the retired items.
   See [Deprecated and retired](#deprecated-and-retired).
7. If you build your own images, remove the 25 certificates from each trust
   store in them.
8. Check the fix. See [How to check the fix](#how-to-check-the-fix).

## How to check the fix

Do these checks after you upgrade. Check 1 shows that the right images run.
Check 2 proves that an image does not trust the 25 certificates. Check 3
covers Docker chaincode, and check 4 covers your own Go programs.

### 1. Check the images that run

This command lists each Luther image that runs in your Kubernetes cluster,
init containers included, with its digest:

```sh
kubectl get pods -A -o jsonpath='{range .items[*]}{range .status.initContainerStatuses[*]}{.image}{"\t"}{.imageID}{"\n"}{end}{range .status.containerStatuses[*]}{.image}{"\t"}{.imageID}{"\n"}{end}{end}' | sort -u | grep -E 'luthersystems|hyperledger'
```

Compare each image with [Containers](#containers). Each one must be at the
listed version or later. For `luthersystems/awscli`, `luthersystems/dind` and
`luthersystems/fabric-tools`, v0.1.45 and later are hardened. mars v0.141.0
and later deploy v0.1.46 of them by default. At the listed version, the digest (the `sha256:`
part of the second column) must be the one in
[Image digests](#image-digests). The digest proves that the image is the one
that Luther published, even if someone moved the tag.

If a pod runs the upstream `hyperledger/fabric-tools` image (for example for
the `peer` CLI), use `luthersystems/fabric-tools` in its place. The upstream
image still trusts the emSign roots. The Fabric peer and orderer images need
no change, because they have no system CA store.

### 2. Check the trust stores of an image

Luther CI runs this check on each image before it publishes it. The check
script is public:
[images/harden/check/image.sh](https://github.com/luthersystems/buildenv/blob/v0.1.48/images/harden/check/image.sh).
It reads the files of the image and does not run the image. It checks every
trust store in it: the OS bundle, Java, Python certifi (the AWS CLI has its
own) and Chrome NSS. It fails if one of the 25 certificates is in a trust
store, or if one of them still verifies. The 25 certificates and their
SHA-256 fingerprints are in
[ca-distrust.list](https://github.com/luthersystems/buildenv/blob/v0.1.48/images/harden/policy/ca-distrust.list).

Run it on a Linux host with Docker, bash 4 or later and openssl. macOS has
bash 3.2, which is too old. For an image with Chrome (such as pdfserv), the
host also needs `certutil` (package `libnss3-tools`). For an image with a Java
keystore (such as build-java), the host also needs `keytool` (a JDK).

```sh
# Get the check script and its certificate list from the published kit image.
cid=$(docker create luthersystems/build-harden:v0.1.48 /nonexistent)
docker cp "$cid:/harden" ./harden && docker rm "$cid"

# Check each image that you run. Put your own image list here.
for img in \
  luthersystems/auth:v4.8.3 \
  luthersystems/pdfserv:v1.2.0 \
  luthersystems/fabric-baseos:2.2-v0.1.48
do
  bash ./harden/check/image.sh "$img"
  case $? in
    0) ;;
    1) echo "NOT FIXED: $img" ;;
    *) echo "CHECK ERROR: $img (read the image.sh message above)" ;;
  esac
done
```

For a good image, the last line is
`OK: <image> holds the build-harden policy`. For a bad image, the check
prints `FAIL:` lines and stops with exit code 1. Exit code 2 means that the
check could not run, for example because a host tool is missing or the image
name is wrong. It says nothing about the image. You can also check an image
that you build yourself, or an image of another vendor.

On an image with Chrome, the check also prints three `WARN:` lines. They are
expected: Chrome and its NSS library have a built-in copy of the old root
list. The image overrides it, because its NSS database marks each of the 25
certificates as distrusted, and the check confirms this before it prints
`OK`.

To see a failure, check an image from before the fix. For example,
`luthersystems/substrate:v2.247.0` and `hyperledger/fabric-baseos:2.2` print
`FAIL:` lines.

### 3. Check Docker chaincode

If a peer runs Docker chaincode (not chaincode as a service), set its
chaincode images first (see
[Docker chaincode](#docker-chaincode-fabric-ccenv-and-fabric-baseos)). Then
run check 2 on the chaincode image that the peer built, on the Docker host
that the peer uses:

```sh
docker images --format '{{.Repository}}:{{.Tag}}' | grep '^dev-'
bash ./harden/check/image.sh <a dev- image from the list>
```

If the peer's Docker daemon runs in a sidecar container (the mars
fabric-peer chart names it `docker-chaincodes`), that container may not have
bash 4 or openssl. Copy the image out and check it on a Linux host:

```sh
kubectl exec <peer pod> -c docker-chaincodes -- docker save <the dev- image> > chaincode.tar
docker load -i chaincode.tar
bash ./harden/check/image.sh <the dev- image>
```

The check must print `OK`. A chaincode image that the peer built with the
upstream Fabric 2.2 or 2.4 images prints `FAIL:` lines. If it does, remove
the old `dev-<peer ID>-` containers and images, then restart the peer, so the
peer builds the chaincode again with the new images. Remove the containers
first: Docker does not remove an image that a container still uses.

### 4. Check your own Go programs

Go 1.26.10 and later block the 25 certificates themselves (see
[How this compares with the Go fix](#how-this-compares-with-the-go-fix)). To
check a program that you built, use `go version -m`:

```sh
go version -m ./your-program | grep -E 'go1\.|luthersystems/svc'
```

The first line must show `go1.26.10` or later. If the program uses
github.com/luthersystems/svc, its `dep` line must show v0.19.1 or later.

## Containers

**Hardened** means that the image blocks the 25 certificates and that its Go
programs (if any) use Go 1.26.10. **Hardened, deprecated** means that the
image is safe to run, but you should plan to move off it. **Deprecated, no change
needed** means that the image has no CA store, so there is nothing to block. Some source
repositories are private; ask us for access.

**Use this version** names the latest release on 2026-10-23. A later release of
the same image is hardened too. To pin an image by content, use the digest in
[Image digests](#image-digests).

### Core platform

| Image | Used for | Source | Use this version | Status |
|---|---|---|---|---|
| [`luthersystems/substrate`](https://hub.docker.com/r/luthersystems/substrate) | Substrate chaincode. Runs your phylum on Hyperledger Fabric | [substrate](https://github.com/luthersystems/substrate) | v2.249.0 | Hardened |
| [`luthersystems/shiroclient`](https://hub.docker.com/r/luthersystems/shiroclient) | Shiroclient gateway. Sends JSON-RPC requests to Fabric | [substrate](https://github.com/luthersystems/substrate) | v2.249.0 | Hardened |
| [`luthersystems/auth`](https://hub.docker.com/r/luthersystems/auth) | Luther Auth, the authentication service | [lutherauth](https://github.com/luthersystems/lutherauth) | v4.8.3 | Hardened |
| [`luthersystems/oracle`](https://hub.docker.com/r/luthersystems/oracle) | Example application image of Luther Enterprise (built from the sandbox repository) | [sandbox](https://github.com/luthersystems/sandbox) | v0.0.2 | Hardened |

### Application services

| Image | Used for | Source | Use this version | Status |
|---|---|---|---|---|
| [`luthersystems/connectorhub`](https://hub.docker.com/r/luthersystems/connectorhub) | Connector Hub. Connects your workflows to external systems | [connectorhub](https://github.com/luthersystems/connectorhub) | v0.0.28 | Hardened. Every connector runs on supergateway 3.4.3-2 |
| [`luthersystems/supergateway-debian`](https://hub.docker.com/r/luthersystems/supergateway-debian), [`luthersystems/supergateway-npx-git`](https://hub.docker.com/r/luthersystems/supergateway-npx-git), [`luthersystems/supergateway-uvx-git`](https://hub.docker.com/r/luthersystems/supergateway-uvx-git) | Part of Connector Hub, and the image of the mars supergateway and mcp-inspector charts (v0.142.0 and later). Runs MCP connector servers | [connectorhub](https://github.com/luthersystems/connectorhub) | 3.4.3-2 | Hardened |
| [`luthersystems/pdfserv`](https://hub.docker.com/r/luthersystems/pdfserv) | PDF rendering service (headless Chrome) | [hyphae](https://github.com/luthersystems/hyphae) | v1.2.0 | Hardened |
| [`luthersystems/service-base-alpine`](https://hub.docker.com/r/luthersystems/service-base-alpine) | Runtime base image of the Luther services | [buildenv](https://github.com/luthersystems/buildenv) | v0.1.48 | Hardened |
| [`luthersystems/nginx-frontend`](https://hub.docker.com/r/luthersystems/nginx-frontend) | Base image that serves static web front ends | [buildenv](https://github.com/luthersystems/buildenv) | v0.1.48 | Hardened |

### Infrastructure and operations

| Image | Used for | Source | Use this version | Status |
|---|---|---|---|---|
| [`luthersystems/mars`](https://hub.docker.com/r/luthersystems/mars) | Infrastructure tool (Terraform, Ansible, Helm charts). Deploys the platform | [mars](https://github.com/luthersystems/mars) | v0.143.0 (see [Helm charts](#helm-charts-aws-cli-and-docker)) | Hardened |
| [`luthersystems/awscli`](https://hub.docker.com/r/luthersystems/awscli) | AWS CLI 2.35.11 in the init containers of the [mars](https://github.com/luthersystems/mars) Helm charts. See [Helm charts](#helm-charts-aws-cli-and-docker) | [buildenv](https://github.com/luthersystems/buildenv) | v0.1.48 | Hardened |
| [`luthersystems/fabric-tools`](https://hub.docker.com/r/luthersystems/fabric-tools) | Hyperledger Fabric command-line tools | [buildenv](https://github.com/luthersystems/buildenv) | v0.1.48 | Hardened |
| [`luthersystems/fabric-ccenv`](https://hub.docker.com/r/luthersystems/fabric-ccenv) | Builds Go chaincode on a peer that runs Docker chaincode. Fabric 2.2, 2.4 and 2.5. See [Docker chaincode](#docker-chaincode-fabric-ccenv-and-fabric-baseos) | [buildenv](https://github.com/luthersystems/buildenv) | `2.2-v0.1.48`, `2.4-v0.1.48`, `2.5-v0.1.48` | **Hardened, deprecated** |
| [`luthersystems/fabric-baseos`](https://hub.docker.com/r/luthersystems/fabric-baseos) | Runs Go chaincode on a peer that runs Docker chaincode. Fabric 2.2 and 2.4. Fabric 2.5 needs no copy. See [Docker chaincode](#docker-chaincode-fabric-ccenv-and-fabric-baseos) | [buildenv](https://github.com/luthersystems/buildenv) | `2.2-v0.1.48`, `2.4-v0.1.48` | **Hardened, deprecated** |
| [`luthersystems/fabric-network-builder`](https://hub.docker.com/r/luthersystems/fabric-network-builder) | Generates the crypto material and configuration of a Fabric network | [fabric-network-builder](https://github.com/luthersystems/fabric-network-builder) | v0.0.10 | Hardened |
| [`luthersystems/fabric-snapshot-archiver`](https://hub.docker.com/r/luthersystems/fabric-snapshot-archiver) | Sidecar that archives peer ledger snapshots | [fabric-snapshot-archiver](https://github.com/luthersystems/fabric-snapshot-archiver) | v0.0.8 | Hardened |
| [`luthersystems/dind`](https://hub.docker.com/r/luthersystems/dind) | Docker daemon (Docker 28.5.2) beside the Fabric peer, for Docker chaincode. Deprecated in favor of external chaincode (chaincode as a service, CCaaS) | [buildenv](https://github.com/luthersystems/buildenv) | v0.1.48 | **Hardened, deprecated** |
| [`luthersystems/buildpack`](https://hub.docker.com/r/luthersystems/buildpack) | Builder for Fabric external chaincode. It has no CA store and no TLS client. Deprecated in favor of external chaincode (chaincode as a service, CCaaS) | [buildpack](https://github.com/luthersystems/buildpack) | No new version | **Deprecated, no change needed** |
| [`luthersystems/pushprox`](https://hub.docker.com/r/luthersystems/pushprox) | Prometheus proxy for chaincode metrics (mars Prometheus chart). Deprecated in favor of external chaincode, which Prometheus scrapes directly | [pushproxng](https://github.com/luthersystems/pushproxng) | v0.1.0 | **Hardened, deprecated** |

### CI/CD and build

| Image | Used for | Source | Use this version | Status |
|---|---|---|---|---|
| [`luthersystems/build-go`](https://hub.docker.com/r/luthersystems/build-go), [`luthersystems/build-go-alpine`](https://hub.docker.com/r/luthersystems/build-go-alpine), [`luthersystems/build-api`](https://hub.docker.com/r/luthersystems/build-api), [`luthersystems/build-godynamic`](https://hub.docker.com/r/luthersystems/build-godynamic) | Go build, test and lint images | [buildenv](https://github.com/luthersystems/buildenv) | v0.1.48 | Hardened |
| [`luthersystems/build-java`](https://hub.docker.com/r/luthersystems/build-java) | Java build image | [buildenv](https://github.com/luthersystems/buildenv) | v0.1.48 | Hardened |
| [`luthersystems/build-js`](https://hub.docker.com/r/luthersystems/build-js), [`luthersystems/build-e2e`](https://hub.docker.com/r/luthersystems/build-e2e) | Node.js build and browser test images. Node.js uses the hardened system store (`NODE_OPTIONS=--use-openssl-ca`). In build-js before v0.1.47, scanners report GHSA-6q48-6c7w-9gw2 for azure-cli's old certifi; the image already removes the bad roots from it | [buildenv](https://github.com/luthersystems/buildenv) | v0.1.48 | Hardened |
| [`luthersystems/build-swaggercodegen`](https://hub.docker.com/r/luthersystems/build-swaggercodegen) | API client code generation | [buildenv](https://github.com/luthersystems/buildenv) | v0.1.48 | Hardened |
| [`luthersystems/shirotester`](https://hub.docker.com/r/luthersystems/shirotester) | Phylum unit test, lint and debug runner | [substrate](https://github.com/luthersystems/substrate) | v2.249.0 | Hardened |
| [`luthersystems/martin`](https://hub.docker.com/r/luthersystems/martin) | End-to-end API test runner | [hyphae](https://github.com/luthersystems/hyphae) | v1.2.0 | Hardened |

### InsideOut

These images are part of InsideOut, Luther's cloud infrastructure agent. You
need them only if you run InsideOut yourself. The InsideOut Go module is in
[Go libraries](#go-libraries).

| Image | Used for | Source | Use this version | Status |
|---|---|---|---|---|
| [`luthersystems/insideout-mcp`](https://hub.docker.com/r/luthersystems/insideout-mcp) | InsideOut MCP server | [insideout-mcp](https://github.com/luthersystems/insideout-mcp) | v0.50.4 | Hardened |

### Agent builder

No customer runs this image today. It is listed so the list is complete.

| Image | Used for | Source | Use this version | Status |
|---|---|---|---|---|
| [`luthersystems/connector-mcp-discovery`](https://hub.docker.com/r/luthersystems/connector-mcp-discovery) | Connector discovery MCP server of the agent builder | [agent-builder](https://github.com/luthersystems/agent-builder) | 0.1.1 | Hardened |

### Image digests

Each digest is the multi-platform index of the tag, read from Docker Hub on
2026-10-23. Pull by digest (`luthersystems/substrate@sha256:...`) to be sure
that you run the image this page lists, even if a tag moves. `docker buildx
imagetools inspect <image>:<tag>` shows the digest of a tag.

| Image and tag | Digest |
|---|---|
| `luthersystems/substrate:v2.249.0` | `sha256:d0084565c25374bcebc5e30344fe36948732613df2a4462a0f1f2b5aa7879f66` |
| `luthersystems/shiroclient:v2.249.0` | `sha256:009ed591d452b9e7ecbca9c2e6c6bccca4aeba25c21ec2fb2721af27e270280b` |
| `luthersystems/auth:v4.8.3` | `sha256:8eca0ee67fb51165bfe24f6bea5d310e4eb2b51c32f2d46b08c45fed10d5c8a4` |
| `luthersystems/oracle:v0.0.2` | `sha256:89a67670bdbc4bbd0fb8d3be82a26787c4367b41470c8f136355e4aa2f899410` |
| `luthersystems/connectorhub:v0.0.28` | `sha256:9106135e22676dd13b100652c5bf61297299ee3d3b8a4436d537098c13f275d0` |
| `luthersystems/supergateway-debian:3.4.3-2` | `sha256:5ec1578a25a39dee1dcde5751e6ecf02647f6ff31ac32ede2f24011ce6cb0b71` |
| `luthersystems/supergateway-npx-git:3.4.3-2` | `sha256:062fa778d198390de11351365342e49fd33d2cdd3e17092adf1a69d3ff4db552` |
| `luthersystems/supergateway-uvx-git:3.4.3-2` | `sha256:03df25766c9b2419e8c343bf10a05e2c4040a48255332ea9758eefa141f0cfb3` |
| `luthersystems/pdfserv:v1.2.0` | `sha256:8f78e8c57b8ee7aaf7551f66f03aad6c5caae8c466e66221f9488b7111d7779d` |
| `luthersystems/service-base-alpine:v0.1.48` | `sha256:b25764c300417c8f111ea7886bfa43be2c2859aaf91f792c2c04a9dad9dde70d` |
| `luthersystems/nginx-frontend:v0.1.48` | `sha256:885a968810cbf428aa454463cab56be3f944cabbd7a90d56b495cb69793caffe` |
| `luthersystems/mars:v0.143.0` | `sha256:b397eacbb9316fedc1a94e872efd0600cde3fdf01bd7fb27890b2ee00fb87f4c` |
| `luthersystems/awscli:v0.1.48` | `sha256:7d20746f0cdddc36b4af49baf5e59dc835fd1ad199fa619b993051e2164ffd5e` |
| `luthersystems/fabric-tools:v0.1.48` | `sha256:cfbaf8823a42d1e54856e1ce535ed013285b90361aa2539c471e37925c157068` |
| `luthersystems/fabric-network-builder:v0.0.10` | `sha256:9518082b25e123e8100a782b4813267234ab119e526e064b03f312302315afdb` |
| `luthersystems/fabric-snapshot-archiver:v0.0.8` | `sha256:4413b5a81367e3249a25cfe0188ecff4fe9cecb0f7ee07b1b8c35e1ea3376396` |
| `luthersystems/dind:v0.1.48` | `sha256:c5f4ff026d51a2967bf9308e820da3042ac8c38ddc5c0defe682541a7a046ea6` |
| `luthersystems/pushprox:v0.1.0` | `sha256:9ade96885352cb4bcb7df6e55065aae0ffd84ea4258d1c470b4bc2ba6ef4ca76` |
| `luthersystems/build-go:v0.1.48` | `sha256:a5d767aa618fa994efc355ba4ba7365bb5b034310e427e7ae51c325ff5b7b177` |
| `luthersystems/build-go-alpine:v0.1.48` | `sha256:72bba104ee5a2f014cf83bd807a3d100ee9a18fe08ad61135f447660847fdc0d` |
| `luthersystems/build-api:v0.1.48` | `sha256:fc2defb4e31a37c6199a1d82703f70014ac6d766e1021f1e6a23d8c9b39b5cf5` |
| `luthersystems/build-godynamic:v0.1.48` | `sha256:e76a44825352fecbe8dd1080f8edf987f7f154b8b6d94888a20aa0e7aa15ca27` |
| `luthersystems/build-java:v0.1.48` | `sha256:b20c0a1c0bebff08158dcdc2bca8ccd9b1b5c3ba7bac0fdcc9d0e8c19ad68c7f` |
| `luthersystems/build-js:v0.1.48` | `sha256:175cc64dd5b5df1147a4ced081b4a587cd91ac2455e8d4c78eb6aa989733aa6f` |
| `luthersystems/build-e2e:v0.1.48` | `sha256:57a778b9d28cfb737f8addf0c3295aa863ab029b19306ce675b06a1a0f0028ef` |
| `luthersystems/build-swaggercodegen:v0.1.48` | `sha256:f98963057afc198b142571c003015448208151a7a836f2afa91429cc87f9cafa` |
| `luthersystems/shirotester:v2.249.0` | `sha256:e9a54ae8c97542681a4e80342a84dc92a1eb7eeefd0d6a676cc51838f382dba9` |
| `luthersystems/martin:v1.2.0` | `sha256:76ded13fa845de2930bbb5c9f8553fa440e6ac205fa5229129f83bbb96dbadee` |
| `luthersystems/insideout-mcp:v0.50.4` | `sha256:6fcf3205705f5531924850d3005e42f0eaa574a7be39c843b7eaa2dee37ad050` |
| `luthersystems/connector-mcp-discovery:0.1.1` | `sha256:b75548d3af15c978c6171e06711422fe340fdf16af0f2d1a37f05d8a1df0dfd0` |
| `luthersystems/fabric-ccenv:2.2-v0.1.48` | `sha256:6ad91f7f7af16e993b16e7780654737cd1442f7fc49cad89aaada941c3756f48` |
| `luthersystems/fabric-ccenv:2.4-v0.1.48` | `sha256:c55e3f9a605c80733cd9566f59d616429a4ccfa1bb46eff6af58f72f38f49855` |
| `luthersystems/fabric-ccenv:2.5-v0.1.48` | `sha256:b78ebc4f8928bf2a3bd4d37d2acc5c00d5ba23750a3c14da69341a161463ee43` |
| `luthersystems/fabric-baseos:2.2-v0.1.48` | `sha256:b6aec267b3e0471e169b745c6ec645ef41ec364d25f721f7cfd9fc96fb88f77d` |
| `luthersystems/fabric-baseos:2.4-v0.1.48` | `sha256:b6f12be35f71d3f6afbd528bd2db0d252edd63146201ca861ec897e02ab110af` |

## Go libraries

Build with Go 1.26.10 or later. Each version below is built and tested with
Go 1.26.10.

### Platform libraries

| Module | Used for | Use this version |
|---|---|---|
| Go toolchain | Builds your programs. It decides the Go fix | 1.26.10 or later |
| [github.com/luthersystems/svc](https://github.com/luthersystems/svc) | Service framework for oracles (REST/gRPC gateway, storage, logging) | v0.19.1 |
| [github.com/luthersystems/shiroclient-sdk-go](https://github.com/luthersystems/shiroclient-sdk-go) | Go client of the shiroclient gateway | v0.18.0 |
| [github.com/luthersystems/lutherauth-sdk-go](https://github.com/luthersystems/lutherauth-sdk-go) | Go client of Luther Auth | v0.0.10 |
| [github.com/luthersystems/elps](https://github.com/luthersystems/elps) | ELPS interpreter (the phylum language) | v1.88.0 |
| [github.com/luthersystems/libmxf](https://github.com/luthersystems/libmxf) | MXF codec loaders for offline decoders | v0.1.1 (do not use v0.1.0: `go get` gets a broken decoder file) |
| [github.com/luthersystems/hyphae](https://github.com/luthersystems/hyphae) | Source module of pdfserv and martin | v1.2.0 |
| [github.com/luthersystems/blockinspector](https://github.com/luthersystems/blockinspector) | Command-line tool that inspects Fabric block files (`go install`) | v0.1.0 |

### InsideOut libraries

| Module | Used for | Use this version |
|---|---|---|
| [github.com/luthersystems/insideout-terraform-presets](https://github.com/luthersystems/insideout-terraform-presets) | InsideOut Terraform presets and composer | v0.12.0 |

## Helm charts: AWS CLI and Docker

The [mars](https://github.com/luthersystems/mars) Fabric and shiroclient Helm
charts run the AWS CLI in init containers. You may not see these containers
in your own manifests, but they connect to AWS over TLS, so their trust store
matters. They copy the MSP, TLS and chaincode files from S3 before the main
container starts.

| Chart (mars role) | Init containers that run the AWS CLI |
|---|---|
| fabric-peer (`k8s_fabric_peer`) | `chaincode-archive-bootstrap`, `config-fetch` |
| fabric-orderer (`k8s_fabric_orderer`) | `config-fetch` |
| fabric-ca (`k8s_fabric_ca`) | `config-fetch` |
| fabric-cli (`k8s_fabric_cli`) | `chaincode-archive-bootstrap`, `config-fetch` |
| shiroclient (`helm_charts`) | `config-fetch` |
| shiroclient-cli (`shiroclient_cli`) | `config-fetch` |

All of these use [`luthersystems/awscli`](https://hub.docker.com/r/luthersystems/awscli): the upstream `amazon/aws-cli` image (AWS
CLI 2.35.11) with the 25 certificates blocked. The AWS CLI bundles its own
Python certifi store, and that store is hardened too.

**Upgrade to mars v0.143.0.** From mars v0.141.0, the Fabric and
shiroclient charts use these hardened images by default:
`luthersystems/awscli` v0.1.46 in every chart listed above (the shiroclient
chart included), `luthersystems/dind` v0.1.46, `luthersystems/fabric-tools`
v0.1.46 in the fabric-cli chart and `luthersystems/fabric-snapshot-archiver`
v0.0.8. Earlier mars releases default to images that remove the emSign roots
only. mars v0.142.0 hardens the MCP charts (see
[MCP charts](#mcp-charts-supergateway-and-mcp-inspector)). The images that a
peer uses to build and run Docker chaincode are hardened only from mars
v0.143.0 (see [Set the images with mars](#set-the-images-with-mars)).

If you must stay on mars v0.140.0 for now, set these values in your Ansible
inventory:

```yaml
# luthersystems/awscli in the Fabric and shiroclient-cli init containers
luther_buildenv_images_version: v0.1.48
# luthersystems/dind beside the peer (Docker chaincode only)
k8s_fabric_peer_dind_version: v0.1.48
# luthersystems/fabric-snapshot-archiver (when the archiver is on)
k8s_fabric_peer_snapshot_archiver_version: v0.0.8
```

The shiroclient chart in v0.140.0 does not read
`luther_buildenv_images_version`. Set its own value in the shiroclient Helm
values:

```yaml
awsCLIVersion: v0.1.48
```

The fabric-cli chart in v0.140.0 runs the upstream `hyperledger/fabric-tools`
image and has no setting to change it. Upgrade to v0.141.0 or later to fix it.

### MCP charts (supergateway and mcp-inspector)

In mars v0.141.0 and earlier, the supergateway and mcp-inspector charts
default to the third-party `supercorp/supergateway:uvx` image. Luther does not
build it, and it is not hardened. From mars v0.142.0, both charts default to
[`luthersystems/supergateway-uvx-git`](https://hub.docker.com/r/luthersystems/supergateway-uvx-git)
3.4.3-2, which blocks the 25 certificates.

If you must stay on an earlier mars release, set both values in the Helm
values of each chart:

```yaml
image:
  repository: luthersystems/supergateway-uvx-git
  tag: 3.4.3-2
```

Set the repository and the tag together. A tag of the old image (such as
`uvx`) does not exist in the new repository.

## Docker chaincode: fabric-ccenv and fabric-baseos

Older Fabric networks that do not use chaincode as a service (CCaaS) run
Docker chaincode. On such a peer, Fabric builds the Go chaincode in a
`hyperledger/fabric-ccenv` container and runs it in a
`hyperledger/fabric-baseos` container. A peer that uses chaincode as a service
does not use these images, so it needs no change here. Most of the upstream images still trust
the listed certificates. Fabric no longer releases 2.2 or 2.4, so no upstream
fix will come for them. Luther publishes hardened copies: the upstream image
with the 25 certificates blocked, and nothing else changed (the same Go, the
same packages and the same `chaincode` user).

These images are for Go chaincode only. Luther does not publish hardened
copies of `hyperledger/fabric-nodeenv` or `hyperledger/fabric-javaenv`. If a
peer runs Node.js or Java Docker chaincode, move it to chaincode as a service,
or ask us for help.

| Upstream image | Of the 25 certificates, trusts | Use this image |
|---|---|---|
| `hyperledger/fabric-ccenv:2.2.15` (Go 1.21.6) | 15, including all 8 leaked intermediates | `luthersystems/fabric-ccenv:2.2-v0.1.48` |
| `hyperledger/fabric-ccenv:2.4.9` (Go 1.18.10) | 15 | `luthersystems/fabric-ccenv:2.4-v0.1.48` |
| `hyperledger/fabric-ccenv:2.5.16` (Go 1.26.4) | 6 (the emSign roots) | `luthersystems/fabric-ccenv:2.5-v0.1.48` |
| `hyperledger/fabric-baseos:2.2.15` | 15 | `luthersystems/fabric-baseos:2.2-v0.1.48` |
| `hyperledger/fabric-baseos:2.4.9` | 15 | `luthersystems/fabric-baseos:2.4-v0.1.48` |
| `hyperledger/fabric-baseos:2.5.16` | 0 (it has no CA bundle) | No change needed |

The 2.2 and 2.4 images are for amd64 only, as upstream. The 2.5 image is for
amd64 and arm64.

The tag is the Fabric minor version and the buildenv release. There is no
`latest` tag and no bare `2.2` tag, so the image that a peer runs changes only
when you change the tag. Use the tag for your Fabric minor version.

The Go in these images is older than Go 1.26.10, so the chaincode that they
build does not get the Go block list. The blocked certificates in the image
trust store are what protect it. To get the Go fix as well, move to external
chaincode (CCaaS) with a chaincode built with Go 1.26.10 or later.

### Set the images on the peer

Set the build image and the Go runtime image in the peer's `core.yaml`. This
example is for Fabric 2.2:

```yaml
chaincode:
  builder: luthersystems/fabric-ccenv:2.2-v0.1.48
  golang:
    runtime: luthersystems/fabric-baseos:2.2-v0.1.48
```

Or set the same values as environment variables of the peer. An environment
variable overrides `core.yaml`:

```bash
CORE_CHAINCODE_BUILDER=luthersystems/fabric-ccenv:2.2-v0.1.48
CORE_CHAINCODE_GOLANG_RUNTIME=luthersystems/fabric-baseos:2.2-v0.1.48
```

On Fabric 2.5, set only `chaincode.builder` (`luthersystems/fabric-ccenv:2.5-v0.1.48`).
Keep the upstream runtime image, which has no CA bundle.

The peer builds a chaincode image only when it does not have one. After you
change these values, remove the old chaincode containers and images from the
peer's Docker daemon (their names start with `dev-<peer ID>-`), then restart
the peer. Otherwise the peer keeps running the chaincode that it built with the
old images.

### Set the images with mars

Upgrade to [mars v0.143.0](https://github.com/luthersystems/mars/releases/tag/v0.143.0)
or later. mars v0.142.0 and earlier cannot set these images: the fabric-peer
chart sets the builder to the upstream `hyperledger/fabric-ccenv` image, and its
core.yaml names the upstream `hyperledger/fabric-baseos` as the runtime image.
The chart has no value to change either image, so it builds and runs Docker
chaincode with the emSign roots. mars v0.143.0 sets both by default
([luthersystems/mars#320](https://github.com/luthersystems/mars/pull/320)).
If you cannot upgrade mars yet, move the peer to chaincode as a service, or
ask us for help.

The chart picks the image from the Fabric minor of the peer
(`k8s_fabric_peer_version`):

| Peer Fabric version | `CORE_CHAINCODE_BUILDER` | `CORE_CHAINCODE_GOLANG_RUNTIME` |
|---|---|---|
| 2.2 | `luthersystems/fabric-ccenv:2.2-v0.1.48` | `luthersystems/fabric-baseos:2.2-v0.1.48` |
| 2.4 | `luthersystems/fabric-ccenv:2.4-v0.1.48` | `luthersystems/fabric-baseos:2.4-v0.1.48` |
| 2.5 | `luthersystems/fabric-ccenv:2.5-v0.1.48` | Not set (the upstream image has no CA bundle) |
| Other | `hyperledger/fabric-ccenv:<version>`, as before | Not set |

To change the images, set these values in your Ansible inventory:

```yaml
# buildenv release of the default images (a pinned tag; there is no latest)
k8s_fabric_peer_chaincode_images_version: v0.1.48
# Full image references. They replace the defaults when they are not empty
k8s_fabric_peer_chaincode_builder_image: ""
k8s_fabric_peer_chaincode_golang_runtime_image: ""
```

For Fabric 2.2, 2.4 and 2.5, the chart no longer uses a `buildImage.repository`
override for the builder. If you pull the images from a private mirror, set
the two full image references to the mirror. To keep the upstream Hyperledger
images, set `k8s_fabric_peer_chaincode_images_version` to `""`.

After the upgrade, remove the old `dev-<peer ID>-` chaincode containers and
images as above.
The chart keeps the Docker storage of the peer on a persistent volume, so the
new peer pod still has the chaincode images that it built with the old images,
and it runs them.

If you use your own Helm charts, set the two variables in the peer container,
as shown above.

## Deprecated and retired

### Infrastructure and operations

| Item | Status | What to use |
|---|---|---|
| Docker chaincode: [`luthersystems/dind`](https://hub.docker.com/r/luthersystems/dind) beside the peer (`k8s_fabric_peer_chaincode_docker`) | **Hardened, deprecated**. Use v0.1.48 | Chaincode as a service (CCaaS) |
| Docker chaincode images: [`luthersystems/fabric-ccenv`](https://hub.docker.com/r/luthersystems/fabric-ccenv) and [`luthersystems/fabric-baseos`](https://hub.docker.com/r/luthersystems/fabric-baseos) | **Hardened, deprecated**. Use v0.1.48 (see [Docker chaincode](#docker-chaincode-fabric-ccenv-and-fabric-baseos)) | Chaincode as a service (CCaaS) |
| [`luthersystems/buildpack`](https://hub.docker.com/r/luthersystems/buildpack), the builder for Fabric external chaincode | **Deprecated.** It has no CA store and no TLS client, so it needs no change | Chaincode as a service (CCaaS) |
| [`luthersystems/pushprox`](https://hub.docker.com/r/luthersystems/pushprox) | **Hardened, deprecated**. The hardened image is v0.1.0. It belongs to the same older chaincode setup as buildpack | Plan to move off it |

### Connector Hub

| Item | Status | What to use |
|---|---|---|
| [`luthersystems/supergateway-uvx-debian`](https://hub.docker.com/r/luthersystems/supergateway-uvx-debian) | **Retired.** Its only tag is from before the fix | [`luthersystems/supergateway-uvx-git`](https://hub.docker.com/r/luthersystems/supergateway-uvx-git) 3.4.3-2 |
| [`luthersystems/connectorhub-local`](https://hub.docker.com/r/luthersystems/connectorhub-local) | **Retired.** No longer published | [`luthersystems/connectorhub`](https://hub.docker.com/r/luthersystems/connectorhub) v0.0.28 |

### CI/CD and build

| Item | Status | What to use |
|---|---|---|
| [`luthersystems/build-python`](https://hub.docker.com/r/luthersystems/build-python) | **Retired.** No new tags. One Luther build still uses it until that build moves off | A Python base image of your choice, with the 25 certificates removed |
| [`luthersystems/build-goextra`](https://hub.docker.com/r/luthersystems/build-goextra) | **Retired** (last push 2024) | [`luthersystems/build-go`](https://hub.docker.com/r/luthersystems/build-go) v0.1.48 |

### Earlier fix releases

These releases came before the full fix.

| Item | Status | What to use |
|---|---|---|
| buildenv v0.1.41 to v0.1.44 images | **Do not use.** They remove emSign roots only. They do not block the eMudhra intermediates | v0.1.48 |
| [`luthersystems/mars`](https://hub.docker.com/r/luthersystems/mars) v0.138.0 to v0.139.0 | **Do not use.** They remove the emSign roots only | v0.143.0 |
| [`luthersystems/mars`](https://hub.docker.com/r/luthersystems/mars) v0.140.0 | **Upgrade.** The image is hardened, but its Helm chart defaults name older images, and its fabric-peer chart builds and runs Docker chaincode in the upstream images | v0.143.0 |
| [`luthersystems/mars`](https://hub.docker.com/r/luthersystems/mars) v0.141.0 | **Upgrade.** Its supergateway and mcp-inspector charts default to the third-party `supercorp/supergateway:uvx` image, and its fabric-peer chart builds and runs Docker chaincode in the upstream images | v0.143.0 |
| [`luthersystems/mars`](https://hub.docker.com/r/luthersystems/mars) v0.142.0 | **Upgrade if a peer runs Docker chaincode.** Its fabric-peer chart builds and runs chaincode in the upstream `hyperledger/fabric-ccenv` and `hyperledger/fabric-baseos` images. A peer that uses chaincode as a service needs no change | v0.143.0 |
| supergateway 3.4.3-1 | **Do not use.** It removes the emSign roots only | 3.4.3-2 |
| [`luthersystems/connectorhub`](https://hub.docker.com/r/luthersystems/connectorhub) v0.0.27 | **Upgrade.** The image is hardened, but its connector defaults name supergateway 3.4.3-1 | v0.0.28 |

## No change needed

| Item | Why |
|---|---|
| `hyperledger/fabric-peer` and `hyperledger/fabric-orderer` 2.5.5 and later | They ship no system CA store. Fabric trusts only the CAs in its channel and MSP configuration |
| `hyperledger/fabric-baseos` 2.5 | It ships no CA bundle |
| Third-party images that Connector Hub can run (for example `supercorp/supergateway`, `mcp/*`, AWS Labs images, `node`) | Luther does not build them. Their vendors own their trust stores. Check them with your vendor |

## Questions

Email dev@luthersystems.com, or ask in your shared Slack channel with Luther.
