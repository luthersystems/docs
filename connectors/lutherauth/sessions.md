---
description: How a LutherAuth login lasts, how sign-out ends it at LutherAuth and at the IdP, and how to end every session of a user.
---

# Sessions, Sign-Out and Revocation

A LutherAuth login gives the browser two kinds of token:

| Token | Where it lives | Lifetime | Checked by |
|---|---|---|---|
| Refresh token | HttpOnly cookie on `/v1/auth`, with `AUTH_ENABLE_REFRESH=true` | `AUTH_REFRESH_TIMEOUT` | LutherAuth, on each refresh, against its Redis store |
| Access token | Returned by `POST /v1/auth/refresh`, or an `authorization` cookie for the legacy login | `AUTH_JWT_REFRESH_INTERVAL` (30m by default), or `AUTH_JWT_TIMEOUT` for the legacy login | Each service, offline, against the JWKS |

Each refresh rotates the refresh token. A refresh token that is used a second time (a copied cookie, for example) revokes its whole family, and the user must log in again.

Because services check access tokens offline, an access token cannot be revoked. Keep `AUTH_JWT_REFRESH_INTERVAL` short.

---

## Redis user permissions

With several LutherAuth pods, the refresh store must be Redis (`AUTH_JWT_REFRESH_REDIS_*`), so that every pod sees each rotation and revocation. Give the Redis user only what the store uses. This is the ElastiCache `access_string`, or the Redis `ACL SETUSER` rule:

```
on ~f_* -@all +get +set +eval +evalsha +ping
```

| Part | Why |
|---|---|
| `~f_*` | Every key of the store starts with `f_` |
| `+get +set +eval +evalsha +ping` | The store runs only GET, SET and PING, and Lua scripts that run only GET and SET |
| No `@write` or `@scripting` | These categories include FLUSHALL and SCRIPT FLUSH. They take no key, so `~f_*` does not limit them |

If you set a nonzero `AUTH_JWT_REFRESH_REDIS_DATABASE_ID`, also add `+select`.

Use v4.13.0 or later with this rule. On v4.12.0, every refresh fails with `500` under it. See [Known Issues](../../known-issues.md).

### ElastiCache IAM auth

On AWS ElastiCache (Valkey, or Redis OSS 7 and later), LutherAuth can sign in with IAM, so no Redis password is stored. Make an ElastiCache user with IAM authentication and the rule above. Its user ID must equal its user name. Turn off the default user. On Valkey, put only the LutherAuth user in the cache's user group. On Redis OSS, the group must also hold a user named `default`, so add a `default` user with the access string `off`.

| Setting | Value |
|---|---|
| `AUTH_JWT_REFRESH_REDIS_IAM_CACHE_NAME` | The replication group ID. Setting it turns on IAM auth |
| `AUTH_JWT_REFRESH_REDIS_USER` | The ElastiCache user ID |
| `AUTH_JWT_REFRESH_REDIS_USE_TLS` | `true`. ElastiCache refuses IAM auth without TLS |
| `AUTH_JWT_REFRESH_REDIS_PASSWORD` | Empty. LutherAuth refuses to start with both a password and IAM auth |

Give the LutherAuth pod's AWS role (IRSA or EKS Pod Identity) only `elasticache:Connect`, on that replication group and that user:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RefreshStoreConnect",
      "Effect": "Allow",
      "Action": "elasticache:Connect",
      "Resource": [
        "arn:aws:elasticache:<region>:<account>:replicationgroup:<replication group ID>",
        "arn:aws:elasticache:<region>:<account>:user:<user ID>"
      ]
    }
  ]
}
```

Allow connections to the cache only from the nodes or pods that run LutherAuth (a security group rule on port 6379).

---

## Sign out

`POST /v1/auth/oauth_delete` signs the user out. It:

- deletes the LutherAuth cookies,
- revokes the refresh token family on the server, so a copied refresh cookie also stops working, even one that was already rotated out.

It takes an optional `redirect_url`. The host of the URL must match `AUTH_OAUTH_ENDPOINT_DELETE_COOKIE_VALID_REDIRECT_REGEXP`. A GET is refused with `405`. A bad `redirect_url` is refused with `400` (v4.12.0 and later).

---

## End the IdP session too

Available in LutherAuth v4.13.0 and later.

By default, sign-out does not end the IdP's own login session. Most IdPs keep one. Then the next login in the same browser signs in with no password, as the user who signed out. On a shared computer, the next person gets the account of the person before them. Turn on IdP logout for any deployment where people share computers.

| Setting | Value |
|---|---|
| `AUTH_OAUTH_IDP_LOGOUT_URL` | The IdP's logout URL. For an OIDC IdP, this is `end_session_endpoint` in `/.well-known/openid-configuration`. For Auth0, `https://<tenant domain>/v2/logout`. It must use https |
| `AUTH_OAUTH_IDP_LOGOUT_RETURN_PARAM` | The query parameter that carries `redirect_url` to the IdP. Empty means `post_logout_redirect_uri` (OIDC). For Auth0 `/v2/logout`, set `returnTo` |
| `AUTH_OAUTH_IDP_LOGOUT_ID_TOKEN_HINT` | `true` sends the user's ID token as `id_token_hint`. Many IdPs need it before they send the user back to `redirect_url`. Without it, they refuse, or they ask the user to confirm the logout. Ask your IdP team if it is required |
| `AUTH_OAUTH_IDP_LOGOUT_ID_TOKEN_COOKIE_PATH` | Default `/v1/auth`. With the hint on, LutherAuth keeps the ID token in an HttpOnly cookie on this path from login to sign-out. Set it to the path prefix of the sign-out endpoint as the browser sees it |

On the IdP, register each `redirect_url` as an allowed post-logout URL (Auth0: Allowed Logout URLs). Otherwise the IdP does not send the user back.

### How sign-out answers

| Request | Answer |
|---|---|
| A page load with `redirect_url` (a form post, `Sec-Fetch-Mode: navigate`, or no `Sec-Fetch-Mode`) | `303` to the IdP logout URL, with `client_id`, the return URL and, with the hint on, `id_token_hint`. The IdP ends its session and sends the browser to `redirect_url` |
| A `fetch` or XHR, or a request without `redirect_url` | `200` with `{"idp_logout_url": "..."}`. A `fetch` cannot follow a redirect to another site, so the app sets `window.location` to this URL |

`idp_logout_url` never carries the ID token, because any script on the page can read the response body. If your IdP needs `id_token_hint`, sign out with a form post that has `redirect_url`:

```html
<form method="post" action="/v1/auth/oauth_delete?redirect_url=https%3A%2F%2Fapp.example.com%2F">
  <button type="submit">Sign out</button>
</form>
```

A client that sends no `Sec-Fetch-Mode` (Safari before 16.4, a server, or a proxy that drops the header) gets the `303`, even from `fetch`. A server that calls sign-out for a browser must pass the redirect on to the browser.

An app that signs out with `fetch` and ignores the response body leaves the IdP session alive. Change the app to go to `idp_logout_url`.

With the hint on:

- An ID token larger than 3800 bytes does not fit in a cookie. That login signs out without the hint, and LutherAuth logs a warning.
- The cookie adds the size of the ID token to each request on its path. Check the request header limit of your ingress if your ID tokens are large.

### Check it

1. Log in, then sign out.
2. Log in again in the same browser.
3. The IdP must ask for the password again.

---

## Revoke a user

Available in LutherAuth v4.12.0 and later.

A refresh never asks the IdP again. A user that you disable at the IdP stays signed in until the refresh timeout. To end every session of a user at once:

1. Disable the user at the IdP.
2. Run `revoke-user` in the LutherAuth pod, with the `sub` claim of the user's LutherAuth token:

```bash
kubectl exec -n <namespace> deploy/<lutherauth deployment> -- /opt/app revoke-user --sub '<sub>'
```

- Every refresh token of the user issued up to one minute after the command is refused at its next use. The user must log in again. The minute covers a refresh that is in progress and a small clock difference between replicas.
- An access token already issued stays valid until it expires.
- The `sub` must match exactly, and it depends on the login: the IdP's `sub` for OAuth, the email address for a magic link. Revoke each `sub` that the person has.
- It needs `AUTH_ENABLE_REFRESH=true` and the Redis refresh store. It refuses to run without them.

---

## What can be revoked

| Token | How it ends |
|---|---|
| Refresh token | Sign-out (its family), reuse of a rotated token (its family), `revoke-user` (all of a user's) |
| Access token | It expires. It cannot be revoked |
| Client credentials or minted token | It expires. Remove the client to stop new tokens. From v4.12.0, a minted token lasts at most 90 days (`AUTH_CLIENT_CREDENTIALS_MINT_MAX_TTL`) |
| Every token | Rotate `AUTH_JWT_SIGN_KEY` without a grace window |
