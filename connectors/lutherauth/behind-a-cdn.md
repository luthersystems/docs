---
description: Configure a CDN or reverse proxy in front of LutherAuth so that it never caches login responses.
---

# Behind a CDN

Put LutherAuth behind a route that **never caches** `/v1/auth/*`.

`oauth_login` sets one-time cookies for each login: the OAuth state, the nonce and the PKCE verifier. A CDN that caches this response sends the same `Set-Cookie` headers to every user in the cache window. Then:

- All those users share one state, nonce and PKCE verifier. The protection against login CSRF and code injection stops working.
- With refresh tokens on, the first login in the window creates the refresh token family. Each later login looks like a token reuse, revokes the family and fails with `500 Authentication failure`.

A CDN can also cache an error. One failed login then fails for every user until the cache entry expires. CloudFront caches error responses for 10 seconds by default.

---

## CDN settings

LutherAuth sends `Cache-Control: no-store` on every response from v4.12.0. The exception is the public key set (JWKS), which sends `public, max-age=300` because it is the same for every caller. Configure the CDN as well, because some CDNs ignore origin headers or apply a minimum TTL.

| CDN setting | Value for `/v1/auth/*` |
|---|---|
| Cache policy | No caching. CloudFront: the managed `CachingDisabled` policy, or `min_ttl = 0` and `default_ttl = 0` |
| Minimum TTL | `0` |
| Error caching | `0` seconds for every 4xx and 5xx code (CloudFront: a custom error response with `error_caching_min_ttl = 0`) |
| Cookies | Forward all cookies to the origin |
| Query strings | Forward all. `oauth_login` reads `oauth_callback_url` and `frontend_redirect_url` |
| Headers | Forward `Authorization`, `Origin`, `Content-Type`, `X-CSRF-Token` and `Sec-Fetch-Mode` |
| `Set-Cookie` from the origin | Pass it through unchanged |
| Methods | Allow `GET`, `POST` and `OPTIONS` |

Apply the same rule to any API behind the same CDN that returns data for one user or sets cookies. Cache a response only when the origin sends a `Cache-Control` header that allows it. With CloudFront, a default TTL above 0 caches every response that has no `Cache-Control` header.

---

## Check the CDN

Call `oauth_login` two times and compare the responses:

```bash
U='https://<host>/v1/auth/oauth_login?oauth_callback_url=https://<host>/v1/auth/oauth_return&frontend_redirect_url=https://<host>'
for i in 1 2; do curl -s -o /dev/null -D - "$U" | grep -iE '^(x-cache|age|cache-control):|state='; done
```

- The two `state` values must be different.
- `cache-control` must be `no-store`.
- A cache hit (`x-cache: Hit`, or an `age` header) on this route means the CDN is not configured correctly.
