---
description: Check LutherAuth tokens in a Go service with lutherauth-sdk-go, and pin each trusted issuer with WithIssuerPolicy.
---

# Verify Tokens in Go

A Go service checks LutherAuth tokens with [lutherauth-sdk-go](https://github.com/luthersystems/lutherauth-sdk-go). Use [v0.0.12](https://github.com/luthersystems/lutherauth-sdk-go/releases/tag/v0.0.12) or later, and set an issuer policy with `jwk.WithIssuerPolicy`. The policy says which issuers the service trusts, where each issuer's keys are, and which audiences its tokens must carry.

```bash
go get github.com/luthersystems/lutherauth-sdk-go@v0.0.12
```

| SDK release | Change | What you see |
|---|---|---|
| [v0.0.11](https://github.com/luthersystems/lutherauth-sdk-go/releases/tag/v0.0.11) | Refuses a LutherAuth refresh token used as a bearer token. Adds `WithExpectedIssuers`. | Nothing, unless a caller sent a refresh token as a bearer token |
| [v0.0.12](https://github.com/luthersystems/lutherauth-sdk-go/releases/tag/v0.0.12) | Adds `WithIssuerPolicy` ([luthersystems/lutherauth-sdk-go#53](https://github.com/luthersystems/lutherauth-sdk-go/pull/53)) | Nothing until you add a policy. Then a token from any other issuer is refused |

No existing SDK API is removed or changed, so you can upgrade a service with no code change. The issuer policy is the one change we ask you to make.

---

## Why pin the issuer

Without a pin, the SDK accepts a token from any issuer for which it can find a key. Most services send every issuer to the one LutherAuth JWKS URL. Such a service accepts every token that the LutherAuth key signed, whatever issuer the token names. The issuer pin stops a token of another kind, or from an issuer that you did not list, from passing as an access token for this service.

For each issuer you trust, the policy pins:

- the issuer name (`iss`)
- where its keys are (the JWKS URL)
- which audiences (`aud`) its tokens must carry and, for a workload identity, which subjects (`sub`)

---

## Find your values

Read these values from the settings of your LutherAuth deployment.

| Policy field | LutherAuth setting | Default |
|---|---|---|
| Issuer (the map key) | `AUTH_JWT_ISSUER` | `luther:auth:` |
| `JWKSURL` | `https://<your auth host>` + `AUTH_JWT_ENDPOINT_JWKS_PATH` | `/v1/auth/.well-known/jwks.json` |
| `Audience` for browser logins | `AUTH_OAUTH_APPLICATION_AUDIENCE` | none |
| `Audience` for magic link logins | `AUTH_MAGIC_LINK_AUTH_AUDIENCE` | none |
| `Audience` for [service tokens](service-tokens.md) | `claims.aud` of each client in `AUTH_CLIENT_CREDENTIALS_CLIENTS` | set for each client |

List every audience that a token for this service can carry. A token is accepted when it carries at least one of them. If you leave out the magic link audience or a client's audience, those tokens are refused with "audience not accepted".

---

## Set the policy

Replace the service's key options with one policy.

Before:

```go
jwk.WithIssuerToWebKeyURL(func(string) (string, error) {
    return "https://auth.example.com/v1/auth/.well-known/jwks.json", nil
}),
```

After:

```go
claimGetter := claims.NewJWKClaims(
    claims.NewAuthTokenGetter(),
    nil, // optional CSRF nonce getter
    logger,
    jwk.WithIssuerPolicy(map[string]jwk.IssuerPolicy{
        "luther:auth:": { // AUTH_JWT_ISSUER
            JWKSURL: "https://auth.example.com/v1/auth/.well-known/jwks.json",
            Audience: []string{
                "my-app",           // AUTH_OAUTH_APPLICATION_AUDIENCE
                "my-app-magiclink", // AUTH_MAGIC_LINK_AUTH_AUDIENCE, if you use magic links
                "my-app-batch",     // claims.aud of a service token client, if you use one
            },
        },
    }),
)
```

The host name and the audiences are examples. Use your own values from the table above.

Read the values from configuration, not from code, so that each environment sets its own. If the configuration is empty, the policy accepts no token. This is intentional: a pin that failed to load must not become no pin.

How the policy works with the older options:

- An issuer that is not a key of the map (and not in `WithExpectedIssuers`) is refused before a key is fetched.
- For an issuer in the map, `JWKSURL`, `Audience` and `Subject` win over `WithIssuerToWebKeyURL`, `WithExpectedAudience` and `WithExpectedSubject`, in any option order.
- An empty `Audience` or `Subject` is not checked, unless an older option checks it. An empty `JWKSURL` takes the keys from the other key options.
- The older options still apply to issuers that are not in the map. You can move one issuer at a time if you list the others in `WithExpectedIssuers`.

---

## Several issuers

Add one map entry for each issuer that the service trusts, for example a CI workload identity. Give each entry its own `JWKSURL`. A token that names one issuer but is signed with another issuer's key is refused.

The map key is the issuer name, so two LutherAuth environments with the same `AUTH_JWT_ISSUER` (for example the default `luther:auth:`) are one entry. The pin cannot tell them apart. Give each environment its own audiences and its own signing key, so that a token from one environment fails the audience check or the signature check in the other. To trust a second LutherAuth environment in the same service, give it its own `AUTH_JWT_ISSUER`. A change of `AUTH_JWT_ISSUER` makes every service that pins the old name refuse that environment's tokens, so update the services first.

```go
"https://token.actions.githubusercontent.com": {
    JWKSURL:  "https://token.actions.githubusercontent.com/.well-known/jwks",
    Audience: []string{"my-app-deploy"},
    Subject:  []string{"repo:my-org/my-app:environment:prod"},
},
```

---

## Check it

After the change, try these against the service in a test environment.

| Test | Expected result |
|---|---|
| Browser login, then an API call | Works |
| Magic link login, if you use it | Works |
| A [service token](service-tokens.md), if you use one | Works |
| A token for another audience | Refused: "audience not accepted" |
| A token from an issuer that is not in the policy | Refused: "issuer not accepted" |
| A token from another LutherAuth environment | Refused |
| The value of the `refresh` cookie sent as a bearer token | Refused: "refresh token is not a bearer token" |

More examples, and the token sources the SDK reads (gRPC metadata, cookies, headers), are in the [lutherauth-sdk-go README](https://github.com/luthersystems/lutherauth-sdk-go#readme).
