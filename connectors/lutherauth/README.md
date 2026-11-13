---
description: The Luther authentication service, its service tokens, token checks in Go services, and upgrades.
---

# LutherAuth

LutherAuth (the `luthersystems/auth` image) signs in users and services, and issues the Luther access tokens (JWTs) that Luther services check. It signs in users with OAuth 2.0 and OpenID Connect identity providers (IdPs) such as Auth0, Amazon Cognito, Azure AD B2C or another OpenID Connect provider, and with magic links sent by email. It signs in services with the OAuth 2.0 client credentials grant.

The current release is LutherAuth v4.15.0 ([`luthersystems/auth:v4.15.0`](https://hub.docker.com/r/luthersystems/auth/tags) on Docker Hub). Go services check its tokens with [lutherauth-sdk-go](https://github.com/luthersystems/lutherauth-sdk-go) ([v0.0.12](https://github.com/luthersystems/lutherauth-sdk-go/releases/tag/v0.0.12)).

| Task | Page |
|---|---|
| Give a service, a batch job or a partner system a token with no login | [Service Tokens](service-tokens.md) |
| Limit which pods can reach LutherAuth in Kubernetes | [Network Access](network-access.md) |
| Check LutherAuth tokens in a Go service, and pin the issuer | [Verify Tokens in Go](verify-tokens.md) |
| Upgrade an existing deployment from v4.7 or later, and stop using the fake IdP | [Upgrade LutherAuth](upgrade-v4-9-0.md) |
| Set login and session lifetimes, sign users out at LutherAuth and at the IdP, and end every session of a user | [Sessions, Sign-Out and Revocation](sessions.md) |
| Put LutherAuth behind a CDN such as CloudFront | [Behind a CDN](behind-a-cdn.md) |
| Protect cookie requests against CSRF, and keep the access token in an HttpOnly cookie | [CSRF Protection and Cookie Mode](csrf.md) |

Every setting on these pages is an environment variable: `AUTH_` followed by the setting name in upper snake case. For example, `enable-client-credentials` is `AUTH_ENABLE_CLIENT_CREDENTIALS`.

## OAuth 2.0 Flow with Cognito Overview (out of date)

The OAuth 2.0 workflow begins with the Luther client sending the user on a redirect to a resource provider. This gives the user the opportunity to grant permissions to our client to their resources. If this grant is successful, we consider that that to be a successful login to the luther services.

When the user first arrives at the Luther frontpage and attempts to log in, the frontend will access the auth service endpoint exposing the OAuth redirect, default localhost:8080/retrieveAuthUrl. This will return a 302 redirect to the resource provider (default Amazon Cognito) and allow the user to sign into it.

If sign in is successful, the resource provider will send the user's browser to the redirect url we asked it to, which in this case will be the auth service's second oauth endpoint + an auth code attached. The second endpoint takes the auth code, verifys the request's state is equal to the session state string we originally sent to the resource provider, then uses the auth code to request a user token from the resource provider. Once the token has been returned from the resource provider, the auth service will verify the token using its sign key, then it extracts the username and user roles from the cognito token and creates a luther claim from that. This luther claim is parsed into a JWT and attached to a final redirect to the luther portal via url#JWT. When the frontend receives the portal redirect, it will store the JWT in the URL as part of the session store, where the chaincode can access it as a means of validating users and user roles.

## ECR Access

The build requires build containers hosted in Luther's ECR.

## Git Workflow

All tests in master branch should always pass.

-   It should always be safe to cut a release off master.
-   Code should always be merged to master through a Pull Request (PR).
-   Follow the [7 rules of a git commit](https://chris.beams.io/posts/git-commit/) and [git commit message guide](https://github.com/RomuloOliveira/commit-messages-guide).
-   Builds should be reproducible.

Set your email for this repo:

```
git config user.email "firstName.lastName@luthersystems.com"
```

Use [Feature Branch Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow).

## Go mod

To use go mod with private GitHub repos set:

```
export GO111MODULE=on
git config --global url."git@github.com:".insteadOf "https://github.com/"
go env -w GOPRIVATE=github.com/luthersystems
```
