---
description: Turn on the LutherAuth CSRF token cookie, send it from the frontend, check it in your services, and keep the access token in an HttpOnly cookie.
---

# CSRF Protection and Cookie Mode

A browser sends cookies with every request to their host, also a request that another site starts. If your services accept the LutherAuth access token from a cookie, protect them against cross-site request forgery (CSRF). LutherAuth supports the double-submit pattern:

1. At login, LutherAuth sets a CSRF token cookie that scripts on your page can read.
2. Your frontend reads the cookie and sends its value in the `X-CSRF-Token` header.
3. Your service compares the header with the `nonce` claim of the access token.

A page on another site cannot read your cookies, so it cannot set the header. LutherAuth sets the cookie. It does not check the header. The check is the job of each service.

Use LutherAuth v4.15.0 or later with refresh tokens. In earlier versions, the CSRF token cookie expired after the access token lifetime (30 minutes by default in refresh mode). After that, every checked call failed.

---

## Settings

| Setting | Default | Effect |
|---|---|---|
| `AUTH_OAUTH_PROTECT_CSRF` | `false` | `true` makes each OAuth login set the CSRF token cookie. With `AUTH_ENABLE_REFRESH=true`, each `POST /v1/auth/refresh` sets it again |
| `AUTH_JWT_REFRESH_COOKIE_ACCESS_TOKEN` | `false` | `true` turns on cookie mode: `POST /v1/auth/refresh` puts the access token in an HttpOnly cookie, not in the response body. See [Cookie mode](#cookie-mode) |
| `AUTH_COOKIE_PREFIX` | empty | A prefix for every LutherAuth cookie name. With `ui`, the CSRF token cookie is `ui_csrf_token` |
| `AUTH_SECURE_COOKIES` | `true` | Sends the cookies over HTTPS only. Keep it on outside local development |

---

## Cookies

| Cookie | Set by | Attributes | Lifetime |
|---|---|---|---|
| `<prefix>_csrf_token` (`csrf_token` with no prefix) | Each OAuth login, and each refresh in refresh mode | Not HttpOnly, so your scripts can read it. `SameSite=Strict`, `Path=/`, `Secure` with `AUTH_SECURE_COOKIES`, no `Domain` | Refresh mode: the refresh session (`AUTH_REFRESH_TIMEOUT`, 120h by default). Each refresh sets it again. Legacy login: `AUTH_JWT_TIMEOUT` |
| `<prefix>_authorization` | The legacy cookie login (`/v1/auth/oauth_return`), a magic link login with refresh off, and each refresh in cookie mode | HttpOnly, `SameSite=Strict`, `Path=/`, `Secure` with `AUTH_SECURE_COOKIES` | Cookie mode: `AUTH_JWT_REFRESH_INTERVAL` (30m by default). Legacy login and magic link: `AUTH_JWT_TIMEOUT` |

The value of the CSRF token cookie is equal to the `nonce` claim of every access token of that login. A refreshed access token keeps the `nonce` of its login, so the cookie stays valid for the whole session.

The cookies have no `Domain` attribute. Only pages on the same host as LutherAuth can read the CSRF token cookie. Serve your frontend and LutherAuth from one host, for example behind one CDN.

A successful sign-out (`POST /v1/auth/oauth_delete`) deletes the CSRF token cookie with the other LutherAuth cookies.

### Magic link logins

A magic link login sets no CSRF token cookie. In refresh mode, the first `POST /v1/auth/refresh` after the login sets it. Have the frontend refresh before its first state-changing call. With refresh off, a magic link login sets the access token in the `<prefix>_authorization` cookie, but no CSRF token cookie. Its access token has a `nonce` claim, so a service that checks the header refuses its requests. Use refresh mode for magic link logins before you turn on the check.

### Tokens without a nonce

[Service tokens](service-tokens.md) (client credentials and minted tokens) have no `nonce` claim. The check does not apply to them.

### Callers that send a login token as a bearer token

The check applies to every token with a `nonce` claim, also one sent in the `Authorization: Bearer` header. A script, a test or a backend that sends a user's login token as a bearer token must also send `X-CSRF-Token` with the token's `nonce` claim. A non-browser caller should use a [service token](service-tokens.md) instead.

---

## What the frontend sends

On each state-changing request (`POST`, `PUT`, `PATCH`, `DELETE`), read the CSRF token cookie and send its value in the `X-CSRF-Token` header:

```js
function csrfToken(prefix) {
  const name = (prefix ? prefix + "_" : "") + "csrf_token=";
  const c = document.cookie.split("; ").find((v) => v.startsWith(name));
  return c ? decodeURIComponent(c.slice(name.length)) : "";
}

await fetch("/v1/my-service/orders", {
  method: "POST",
  credentials: "same-origin",
  headers: {
    "Content-Type": "application/json",
    "X-CSRF-Token": csrfToken("ui"),
  },
  body: JSON.stringify(order),
});
```

Read the cookie for each request. Do not keep a copy. Each login and each refresh can set a new value.

---

## What the service checks

For each state-changing request that carries a LutherAuth access token with a `nonce` claim:

1. Check the access token as usual (signature, issuer, audience, expiry).
2. Read the `X-CSRF-Token` header.
3. Compare it with the `nonce` claim in constant time.
4. Refuse the request if the header is missing or different.

A Go service that uses [lutherauth-sdk-go](https://github.com/luthersystems/lutherauth-sdk-go) passes a CSRF getter as the second argument of `claims.NewJWKClaims` (the `nil` in [Verify Tokens in Go](verify-tokens.md#set-the-policy)).

The first argument gets the access token. `claims.NewAuthTokenGetter()` reads only the `Authorization: Bearer` header. To accept the access token from the cookie (the legacy login, a magic link with refresh off, or cookie mode), use `claims.NewCookieTokenGetter`, or a getter that tries both:

```go
bearerToken := claims.NewAuthTokenGetter()
cookieToken := claims.NewCookieTokenGetter("ui_authorization", false) // <prefix>_authorization
authToken := func(ctx context.Context) (string, error) {
    if t, err := bearerToken(ctx); err == nil {
        return t, nil
    }
    return cookieToken(ctx)
}

claimGetter := claims.NewJWKClaims(
    authToken,
    claims.NewRawTokenGetter("X-CSRF-Token", false), // the CSRF getter
    logger,
    jwk.WithIssuerPolicy(policy),
)
```

With a CSRF getter, the SDK compares the header with the `nonce` claim in constant time. A missing or different header gets gRPC `Unauthenticated`. A token without a `nonce` claim is not checked.

The SDK reads the cookie and the header from the incoming gRPC metadata, under the keys `cookie` and `x-csrf-token`. grpc-gateway does not put them there by default: its default matcher drops `X-CSRF-Token` and passes `Cookie` as `grpcgateway-cookie`. Add an incoming header matcher:

```go
mux := runtime.NewServeMux(
    runtime.WithIncomingHeaderMatcher(func(key string) (string, bool) {
        switch k := strings.ToLower(key); k {
        case "cookie", "x-csrf-token":
            return k, true
        }
        return runtime.DefaultHeaderMatcher(key)
    }),
)
```

The SDK checks every call that uses this getter, also a `GET`. Use it for the state-changing methods only, or have the frontend send the header on every request.

Check the header also when the request carries an `Authorization` header. A browser can send both the cookie and a header.

---

## Cookie mode

By default, `POST /v1/auth/refresh` returns the access token in the response body, and the frontend sends it in the `Authorization` header. With `AUTH_JWT_REFRESH_COOKIE_ACCESS_TOKEN=true`, the refresh answers `200` with no body, and sets the access token in the HttpOnly `<prefix>_authorization` cookie. Scripts on the page cannot read the token, so an injected script cannot copy it.

The browser then sends the access token with every request to the host. Turn on CSRF protection with cookie mode, and turn on the check in each service.

Keep cookie mode off while any browser app on the same host uses the legacy login (`AUTH_REFRESH_ALLOW_LEGACY_LOGIN=true`). A refresh writes its short-lived access token over the legacy app's `<prefix>_authorization` cookie. See [Sessions, Sign-Out and Revocation](sessions.md).

---

## Turn it on

Every LutherAuth user login gives an access token with a `nonce` claim, also with CSRF protection off. A service that checks before the cookie and the header exist refuses every browser call. Turn on each part in this order, and check each step in a test environment first.

| Step | Do this |
|---|---|
| 1. LutherAuth | Upgrade to v4.15.0 or later if you use refresh tokens. Set `AUTH_OAUTH_PROTECT_CSRF=true` |
| 2. CDN | Forward `X-CSRF-Token` to LutherAuth and to each service. See [Behind a CDN](behind-a-cdn.md) |
| 3. Frontend | Send the `X-CSRF-Token` header on each state-changing request |
| 4. Services | Turn on the check in each service |
| 5. Cookie mode (optional) | Set `AUTH_JWT_REFRESH_COOKIE_ACCESS_TOKEN=true`, when no app on the host uses the legacy login |

A session that started before step 1 has no CSRF token cookie. In refresh mode, its next refresh sets the cookie. A legacy login session gets the cookie only at its next login, so it fails a checked call until then. Wait `AUTH_JWT_TIMEOUT` after step 1 before step 4, or ask those users to log in again.

A CDN drops a header that it does not forward, with no error. The request then fails at the service as an authentication error. Make sure that step 2 is done before step 4.

To turn it off, go in the opposite order: first the services, then the frontend and LutherAuth.

---

## Check it

1. Log in in a browser.
2. In the browser developer tools, confirm the CSRF token cookie: not HttpOnly, `SameSite=Strict`.
3. Decode the access token and confirm that its `nonce` claim is equal to the cookie value.
4. Send a state-changing request through the CDN with the session cookies and `X-CSRF-Token` set to the cookie value. It must succeed. This proves that the service reads the access token from the cookie and gets the header.
5. Send the same request without `X-CSRF-Token`. The service must refuse it.
6. Send the access token as `Authorization: Bearer`, with no cookies and no `X-CSRF-Token`. The service must refuse it. Add the header, and it must succeed.
7. In refresh mode, wait longer than `AUTH_JWT_REFRESH_INTERVAL`, refresh, and repeat step 4. It must still succeed.

```bash
# Step 4: expect success
curl -s -o /dev/null -w '%{http_code}\n' -X POST \
  -H 'Cookie: ui_authorization=<token>; ui_csrf_token=<value>' \
  -H 'X-CSRF-Token: <value>' \
  https://<host>/v1/my-service/orders

# Step 5: expect a refusal
curl -s -o /dev/null -w '%{http_code}\n' -X POST \
  -H 'Cookie: ui_authorization=<token>; ui_csrf_token=<value>' \
  https://<host>/v1/my-service/orders

# Step 6: expect a refusal, then success with -H 'X-CSRF-Token: <value>'
curl -s -o /dev/null -w '%{http_code}\n' -X POST \
  -H 'Authorization: Bearer <token>' \
  https://<host>/v1/my-service/orders
```

If step 4 fails with an authentication error, the service does not read the cookie or does not get the header. Check the token getter, the header matcher and the CDN before you go on. Otherwise step 5 proves nothing.

Use a test user. Do not paste a real user's token into a shared shell history or a ticket.
