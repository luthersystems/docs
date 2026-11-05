---
description: Upgrade a LutherAuth deployment from v4.7 or later to the latest release, move service callers off the fake IdP, and pin the issuer in the services that check tokens.
---

# Upgrade LutherAuth

This guide upgrades a LutherAuth deployment from v4.7 or later to the latest release, **v4.13.0**. You can upgrade in one step. Since v4.9.0, LutherAuth has the client credentials grant and the `mint-token` command for [service tokens](service-tokens.md), which replace the fake IdP.

<div class="docs-banner">
<p><strong>Do not deploy v4.12.0.</strong> With refresh tokens on and a Redis user that is limited to the <code>f_*</code> keys (the <a href="sessions.md#redis-user-permissions">recommended permissions</a>), every refresh on v4.12.0 fails with <code>500</code>. v4.13.0 fixes it. See <a href="../../known-issues.md">Known Issues</a>.</p>
</div>

Do the work in this order:

1. [Find your current version](#find-your-current-version).
2. [Read the changes since your version](#changes-since-your-version), and make the settings changes that apply to you.
3. [Upgrade LutherAuth](#upgrade-lutherauth).
4. [Stop using the fake IdP](#stop-using-the-fake-idp), if a service caller uses it.
5. [Upgrade the services that check tokens](#upgrade-the-services-that-check-tokens) to lutherauth-sdk-go v0.0.12, and pin the issuer.
6. [Check the upgrade](#check-the-upgrade), first in a test environment, then in production.

Step 3 and step 5 do not depend on each other. Either can go first. If a caller still uses the fake IdP when you do step 5, add the `aud` of its tokens to the policy, or the service refuses them.

---

## Find your current version

The version is the tag of the `luthersystems/auth` image that your LutherAuth deployment runs:

```bash
kubectl get deploy -n <namespace> <lutherauth deployment> \
  -o jsonpath='{.spec.template.spec.containers[*].image}'
```

The output is, for example, `luthersystems/auth:v4.8.3`. If you deploy with Helm or Ansible, the tag is also in your values or inventory.

---

## Changes since your version

Read every row after your current version. **Action** says what to do before you upgrade.

| Version | Change and action |
|---|---|
| v4.8.0 | New `AUTH_JWT_SIGN_KEY_PREVIOUS`: the JWKS serves a previous signing key during a key rotation, so tokens signed with the old key keep working (no action). |
| v4.8.1 | Dependency and security updates (no action). |
| v4.8.2 | With an OAuth backend on, LutherAuth stops at startup when `AUTH_OAUTH_VALID_FRONTEND_REDIRECT_URLS` is empty. Before, an empty list turned the redirect check off. **Action:** Set `AUTH_OAUTH_VALID_FRONTEND_REDIRECT_URLS` to the URLs of your frontends. |
| v4.8.2 | The OAuth code flow to the IdP uses PKCE (S256). Auth0, Amazon Cognito and Azure AD B2C accept it. **Action:** If your IdP refuses PKCE, set `AUTH_OAUTH_DISABLE_PKCE=true`. |
| v4.8.2 | The service shuts down cleanly on `SIGINT` and `SIGTERM` (no action). |
| v4.8.3 | Security: the image distrusts the compromised eMudhra (emSign) certificates. See [Security Notice: eMudhra (emSign) CA Distrust](../../security-notice-emsign.md) (no action). |
| v4.9.0 | Magic link emails are rate limited for each client IP and each email address. A request over a limit gets `429 Too Many Requests`. **Action:** If you use magic links behind a load balancer or a CDN, set `AUTH_MAGIC_LINK_TRUSTED_PROXY_HOPS` (see below). |
| v4.9.0 | New client credentials grant and `mint-token` command for service tokens. Off until you register a client (no action). To use them, see [Service Tokens](service-tokens.md). |
| v4.10.0 | Refresh tokens are signed with their own key, and the Redis refresh store keeps only digests of tokens. Refresh tokens from before still work. **Action:** If refresh tokens are on (`AUTH_ENABLE_REFRESH=true`), switch all pods in one rollout. An older pod cannot check a new refresh token. |
| v4.10.0 | The Redis refresh store can authenticate to AWS ElastiCache with IAM, so no Redis password is stored (no action). See [Sessions](sessions.md#redis-user-permissions) for the Redis user permissions. |
| v4.11.0 | New `AUTH_REFRESH_ALLOW_LEGACY_LOGIN` keeps the legacy login beside refresh tokens. An access token made by a refresh lasts `AUTH_JWT_REFRESH_INTERVAL` (30 minutes by default) (no action). |
| v4.12.0 | A minted token lasts at most 90 days by default. Before, the limit was one year. **Action:** If a `mint_only` client has a `ttl` above 90 days, or you run `mint-token --ttl` above 90 days, set `AUTH_CLIENT_CREDENTIALS_MINT_MAX_TTL` or lower the `ttl` before you upgrade. A client `ttl` above the cap stops LutherAuth at startup, and `mint-token` refuses a longer `--ttl`. A shorter token, renewed on a schedule, is safer. |
| v4.12.0 | Every response, except the JWKS, sends `Cache-Control: no-store`. A bad login, callback or sign-out request gets `400` instead of `500`. New `revoke-user` command (no action). See [Behind a CDN](behind-a-cdn.md) and [Revoke a user](sessions.md#revoke-a-user). |
| v4.12.0 | Known issue: with refresh tokens on and a Redis user limited to `f_*` keys, every refresh fails with `500`. **Action:** Skip v4.12.0. Go to v4.13.0. |
| v4.13.0 | Sign-out can also end the IdP session (`AUTH_OAUTH_IDP_LOGOUT_URL`), with an optional `id_token_hint`. Off by default (no action). To use it, see [End the IdP session too](sessions.md#end-the-idp-session-too). |

### Magic link rate limits

The limits are on by default. Change them only if your users need more links.

| Setting (`AUTH_` + upper snake case) | Default | Meaning |
|---|---|---|
| `magic-link-rate-limit-ip-burst` | `10` | Links that one client IP can request at once |
| `magic-link-rate-limit-ip-every` | `30s` | One more link for each IP after this interval |
| `magic-link-rate-limit-email-burst` | `3` | Links that one address can receive at once |
| `magic-link-rate-limit-email-every` | `5m` | One more link for each address after this interval |
| `magic-link-trusted-proxy-hops` | `0` | Proxies in front of LutherAuth that append to `X-Forwarded-For` |

Set `AUTH_MAGIC_LINK_TRUSTED_PROXY_HOPS` to the number of proxies in front of LutherAuth that append to `X-Forwarded-For`:

| In front of LutherAuth | Value |
|---|---|
| Nothing (clients connect directly) | `0` |
| One load balancer, for example an AWS ALB | `1` |
| A CDN and then a load balancer, for example CloudFront and an ALB | `2` |

At `0`, LutherAuth ignores `X-Forwarded-For`, because a client can forge it. If the connection then comes from a private address, LutherAuth skips the per-IP limit, keeps the per-address limit, and logs a warning that names this setting. A value that is too high lets a client choose its own IP for the limit.

---

## Before you upgrade

1. Make sure that `AUTH_JWT_SIGN_KEY` is set to a persistent key. Without it, each pod makes a random key at startup, every pod restart signs out every user, and `mint-token` refuses to run.
2. Make the settings changes in the table above that apply to your current version.
3. Deploy in a quiet hour. In a rolling deploy from a version before v4.8.2, a login that starts on a new pod and ends on an old pod fails once, and the user logs in again. Only logins in progress during the deploy are affected.

---

## Upgrade LutherAuth

Change the image tag to `luthersystems/auth:v4.13.0` and roll the pods. The image is multi-architecture (`linux/amd64` and `linux/arm64`).

To roll back, set the previous tag. Access tokens and service tokens keep working after a rollback, because they are signed with the same key. With refresh tokens on, a rollback to a version before v4.10.0 signs out the users who logged in after the upgrade. The token endpoint and `mint-token` are not in versions before v4.9.0. Do not roll back from v4.13.0 to v4.12.0: refresh fails again (see [Known Issues](../../known-issues.md)). A rollback to v4.12.0 or earlier also ignores the `revoke-user` records that v4.13.0 wrote, so revoked users can refresh again. Run `revoke-user` again after you upgrade back.

---

## Stop using the fake IdP

The fake IdP (`AUTH_JWT_ENABLE_FAKE_IDP`, path `/test/fakeidp/token`) is for local tests only. It signs any claims that a caller sends, with no caller check and any lifetime, so a caller that can reach it can make a token for any user. It is off by default. Move each caller that uses it to a [service token](service-tokens.md), then turn it off.

1. Find the callers. Search your code, scripts and job definitions for `fakeidp`. If the fake IdP is on, look for requests to `/test/fakeidp/token` in your load balancer or ingress logs.
2. For each caller, register a client with the same `sub`, `aud` and groups that the caller sent to the fake IdP. The receiving services then accept the new token with no change.
3. Move the caller to the method that fits it (see the table below).
4. Set `AUTH_JWT_ENABLE_FAKE_IDP=false` (or remove it) and roll the pods. If you run a separate LutherAuth deployment (for example a second Helm release) only to make tokens with the fake IdP, remove that deployment and its ingress route. `mint-token` runs in your main LutherAuth pod, so you do not need a second deployment.
5. Confirm that the fake IdP is gone: a `POST` to `https://<your auth host>/test/fakeidp/token` must not return a token.
6. Optional: [limit network access to LutherAuth](network-access.md), so that only the pods that must call it can reach it.

| The caller | Use |
|---|---|
| fetches a token before each run, or can do so | The client credentials grant |
| used the fake IdP once for one long-lived token | `mint-token` |

For a caller of the token endpoint, the request changes like this:

| Fake IdP | Client credentials grant |
|---|---|
| `POST /test/fakeidp/token?timeout=8760h` | `POST /v1/auth/token` |
| JSON body with the claims | Form body `grant_type=client_credentials` |
| No caller authentication | Client ID and secret (HTTP Basic) |
| `timeout` sets any lifetime | `timeout` is cut down to the client's `ttl` |
| Response `{"token": "..."}` | Response has `token` and `access_token` |

The caller keeps reading `token` from the response. It must now fetch a new token before `expires_in` runs out. If a caller cannot do that yet, raise the client's `ttl` and `client-credentials-max-ttl` for it, and plan to lower them again.

---

## Upgrade the services that check tokens

Upgrade each Go service that checks LutherAuth tokens to [lutherauth-sdk-go v0.0.12](https://github.com/luthersystems/lutherauth-sdk-go/releases/tag/v0.0.12), and replace its key options with an issuer policy:

```bash
go get github.com/luthersystems/lutherauth-sdk-go@v0.0.12
```

No existing SDK API is removed or changed. Add the `aud` of every caller that still uses the fake IdP, or do step 4 first. [Verify Tokens in Go](verify-tokens.md) tells you how to find your values and set the policy. Add the `aud` of each service token client to the policy's audiences, or the service refuses that client's tokens.

---

## Check the upgrade

Run these checks in a test environment, then in production.

| Check | Expected result |
|---|---|
| The image tag of the LutherAuth pods | `v4.13.0` |
| With refresh tokens on: log in, wait past `AUTH_JWT_REFRESH_INTERVAL`, then an API call | Works. `POST /v1/auth/refresh` returns `200`, not `500` |
| `https://<your auth host>/v1/auth/.well-known/jwks.json` | Returns the JWKS |
| Browser login, then an API call | Works |
| Magic link login, if you use it | Works. The LutherAuth log has no warning about `magic-link-trusted-proxy-hops` |
| A service token from the token endpoint or `mint-token`, if you use one | The receiving service accepts it |
| A `POST` to `/test/fakeidp/token` | No token |
| The checks in [Verify Tokens in Go](verify-tokens.md#check-it) | As that page says |

For help with an upgrade, contact Luther Systems through your usual support channel.
