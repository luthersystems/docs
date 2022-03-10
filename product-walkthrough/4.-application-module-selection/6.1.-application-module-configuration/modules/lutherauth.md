---
description: Encompasses auth related tools needed for Luther authentication services.
---

# Copy of LutherAuth

Lutherauth is our authentication module which includes User and Application authentication through a number of methods. These include 0Auth2, Magic Links, AWS Cognito, and ADFS Support.

## OAuth 2.0 Flow with Cognito Overview (out of date)

The OAuth 2.0 workflow begins with the Luther client sending the user on a redirect to a resource provider. This gives the user the opportunity to grant permissions to our client to their resources. If this grant is successful, we consider that that to be a successful login to the luther services.

When the user first arrives at the Luther frontpage and attempts to log in, the frontend will access the auth service endpoint exposing the OAuth redirect, default localhost:8080/retrieveAuthUrl. This will return a 302 redirect to the resource provider (default Amazon Cognito) and allow the user to sign into it.

If sign in is successful, the resource provider will send the user's browser to the redirect url we asked it to, which in this case will be the auth service's second oauth endpoint + an auth code attached. The second endpoint takes the auth code, verifys the request's state is equal to the session state string we originally sent to the resource provider, then uses the auth code to request a user token from the resource provider. Once the token has been returned from the resource provider, the auth service will verify the token using its sign key, then it extracts the username and user roles from the cognito token and creates a luther claim from that. This luther claim is parsed into a JWT and attached to a final redirect to the luther portal via url#JWT. When the frontend receives the portal redirect, it will store the JWT in the URL as part of the session store, where the chaincode can access it as a means of validating users and user roles.

## ECR Access

The build requires build containers hosted in Luther's ECR.

## Git Workflow

All tests in master branch should always pass.

* _It should always be safe to cut a release off master_.
* _Code should always be merged to master through a Pull Request (PR)_.
* _Follow the_ [_7 rules of a git commit_](https://chris.beams.io/posts/git-commit/) _and_ [_git commit message guide_](https://github.com/RomuloOliveira/commit-messages-guide).
* _Builds should be reproducible_.

Set your email for this repo:

```
git config user.email "firstName.lastName@luthersystems.com"
```

Use [Feature Branch Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow).

## Go mod

To use go mod with private bitbucket repos set:

```
export GO111MODULE=on
git config --global url."git@bitbucket.org:".insteadOf "https://bitbucket.org/"
go env -w GOPRIVATE=bitbucket.org/luthersystems
```
