---
description: Give a service, a batch job or a partner system a LutherAuth token with no login, with the client credentials grant or the mint-token command.
---

# Service Tokens

A caller with no person behind it (a service, a batch job, a SOAP integration) needs a LutherAuth token without a login. LutherAuth v4.9.0 gives it one of two ways. Both use a client that you register in the LutherAuth configuration, so the token's claims come from your configuration and never from the caller.

| Method | Use it when | Token lifetime |
|---|---|---|
| [Client credentials grant](#get-a-token-with-the-client-credentials-grant) | The caller can keep a secret and fetch a new token before the old one expires | Short, 1 hour by default, at most `client-credentials-max-ttl` (24 hours by default) |
| [`mint-token` command](#mint-a-long-lived-token-in-the-pod) | The caller cannot fetch tokens and needs one long-lived token | Long, at most `client-credentials-mint-max-ttl` (2160 hours, 90 days, by default since v4.12.0; one year before) |

Prefer the client credentials grant. A short token that the caller renews limits the damage if it leaks. A long-lived token works until it expires, because an access token cannot be revoked.

Both methods replace the fake IdP (`jwt-enable-fake-idp`). The fake IdP signs any claims a caller sends, with no caller check and no lifetime limit, so anyone who can reach it can make a token for any user. Keep it off. [Upgrade LutherAuth](upgrade-v4-9-0.md#stop-using-the-fake-idp) tells you how to move its callers.

---

## What a service token is

A service token is a normal LutherAuth access token. LutherAuth signs it with the same key and the same issuer (`AUTH_JWT_ISSUER`) as a user's token, so the services that check LutherAuth tokens accept it with no change.

| Claim | Where it comes from |
|---|---|
| `iss` | `AUTH_JWT_ISSUER` of the LutherAuth deployment |
| `sub`, `aud`, `luther:groups`, `org` | the client's `claims` in `client-credentials-clients` |
| `username`, `email`, `name` | the client's `claims`, if you set them |
| `exp` | the client's `ttl`, or a shorter lifetime that the caller asks for |
| `jti` | a new random ID for each token, recorded in the LutherAuth log |

A service token has no `nonce`, so it cannot start a refresh token family. The caller gets a new token when the old one is about to expire.

---

## Settings

The client credentials settings are off by default. The `mint-token` command needs only `client-credentials-clients`.

| Setting (`AUTH_` + upper snake case) | Default | Meaning |
|---|---|---|
| `enable-client-credentials` | `false` | Turn on the token endpoint |
| `client-credentials-endpoint-path` | `/v1/auth/token` | Path of the token endpoint |
| `client-credentials-max-ttl` | `24h` | Longest lifetime from the token endpoint |
| `client-credentials-mint-max-ttl` | `2160h` (v4.12.0 and later; `8760h` before) | Longest lifetime from `mint-token`, and of a `mint_only` client |
| `client-credentials-clients` | empty | The client list: YAML, base64 encoded |

LutherAuth checks the client list strictly. A client `ttl` above its cap is an error. An unknown key (for example `group:` in place of `groups:`) is also an error, so a typo cannot drop a claim without a warning. When `enable-client-credentials` is `true`, an error stops LutherAuth at startup. When it is `false`, LutherAuth does not read the list at startup, and the error shows only when you run `mint-token`. After you change the list for a `mint_only` client, run `mint-token` once to check it.

---

## Register a client

**Step 1.** Make a secret in the LutherAuth image. Do not choose a secret by hand: LutherAuth stores only a fast hash, which is safe only for a long random secret. The command prints two lines, `client_secret: ...` and `secret_sha256: ...`. Send its output to a file that only you can read, not to the terminal, because a person with the secret can get tokens for the client.

```bash
umask 077
kubectl exec -n <namespace> deploy/<lutherauth deployment> -- \
  /opt/app gen-client-secret >client-secret.txt
grep secret_sha256 client-secret.txt   # the hash is safe to show
```

**Step 2.** Put `client_secret` in your secret store for the caller, then delete `client-secret.txt`. Never put the secret in a URL, a ticket or a chat.

**Step 3.** Add the client to the list. Put `secret_sha256` in `secrets_sha256`. A client for `mint-token` only has `mint_only: true` and no secret.

```yaml
- client_id: partner-soap      # gets tokens from the token endpoint
  secrets_sha256:
    - <secret_sha256 from gen-client-secret>
  ttl: 1h                      # optional, default 1h, at most client-credentials-max-ttl
  claims:
    sub: svc-partner-soap
    aud: my-app
    org: my-org
    groups: [soap-callers]
- client_id: partner-batch     # gets only minted tokens
  mint_only: true
  ttl: 2160h                   # at most client-credentials-mint-max-ttl
  claims:
    sub: svc-partner-batch
    aud: my-app
```

**Step 4.** Base64 encode the list into `AUTH_CLIENT_CREDENTIALS_CLIENTS`. Set `AUTH_ENABLE_CLIENT_CREDENTIALS=true` if a client uses the token endpoint. Then roll the LutherAuth pods.

```bash
base64 -w0 clients.yaml   # on macOS: base64 -i clients.yaml
```

Set `aud` to an audience that the receiving service accepts. A service that pins its audiences (see [Verify Tokens in Go](verify-tokens.md)) refuses a token with any other `aud`.

---

## Get a token with the client credentials grant

The caller sends its client ID and secret with HTTP Basic authentication, or as the `client_id` and `client_secret` form fields. It never sends them in the URL.

```bash
curl -u "partner-soap:$CLIENT_SECRET" \
  -d grant_type=client_credentials \
  https://<your auth host>/v1/auth/token
```

```json
{"access_token":"eyJ...","token_type":"Bearer","expires_in":3600,"token":"eyJ..."}
```

- `token` is a copy of `access_token` under the key that the fake IdP used, so a caller that moves off the fake IdP keeps its response parsing.
- The caller can ask for a shorter lifetime with `timeout` (a Go duration such as `30m`, in the form body or the query string). A request above the client's `ttl` gets the `ttl`. `expires_in` gives the lifetime in seconds.
- The caller gets a new token before `expires_in` runs out. It does not keep a token past its expiry.
- A wrong client ID or secret gets `401` with `{"error":"invalid_client"}`. A grant type other than `client_credentials` gets `400` with `{"error":"unsupported_grant_type"}`.

### Rotate a client secret

You can rotate a secret with no downtime:

1. Make a new secret with `gen-client-secret`.
2. Add its `secret_sha256` to the client's `secrets_sha256`, next to the old one, and roll the pods.
3. Give the caller the new secret.
4. Remove the old hash and roll the pods again.

---

## Mint a long-lived token in the pod

For a caller that cannot fetch tokens, run `mint-token` inside the LutherAuth pod. The command signs the token with the pod's own configuration, so the signing key never leaves the cluster, and the token endpoint does not need to be on.

```bash
kubectl exec -n <namespace> deploy/<lutherauth deployment> -- \
  /opt/app mint-token --client partner-batch --ttl 2160h
```

- `/opt/app` is the binary in the `luthersystems/auth` image. The command reads the pod's environment variables. If your deployment starts LutherAuth with `--config <file>`, add the same `--config <file>` to `mint-token` and `gen-client-secret`, or the command does not find the signing key.
- `--client` names a client in `client-credentials-clients`. The claims come from that client.
- `--ttl` is optional. The default is the client's `ttl`. A value above `client-credentials-mint-max-ttl` is an error. This cap is separate from `client-credentials-max-ttl`, so long minted tokens do not allow long tokens from the endpoint. A `mint_only` client with a `ttl` above the cap stops LutherAuth at startup.
- A `mint_only` client has no secret, and the token endpoint refuses it.
- The command refuses to run if it finds no `jwt-sign-key`. Without that key, each pod makes a random key at startup, and a token signed with it verifies nowhere else.
- The token goes to stdout, followed by a newline. The client ID, the `jti` and the expiry go to stderr. Record them with the token's owner, so that you can find the token again when it must be replaced.

### Store the token in a Kubernetes Secret

Do not print a long-lived token in a terminal: it stays in the scrollback and the shell history. When a workload in the same cluster uses the token, write it straight into a Kubernetes Secret in the workload's namespace. A pod can read only the Secrets in its own namespace.

```bash
#!/usr/bin/env bash
set -euo pipefail

AUTH_NS=<lutherauth namespace>
DEPLOY=<lutherauth deployment>
CLIENT=partner-batch
TARGET_NS=<namespace of the workload that uses the token>
SECRET=partner-batch-token        # one Secret for each token

umask 077
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Mint first, on its own. In a pipeline, a failed mint could store an empty token.
kubectl exec -n "$AUTH_NS" "deploy/$DEPLOY" -- \
  /opt/app mint-token --client "$CLIENT" --ttl 2160h >"$tmp/raw"

# Remove the trailing newline. A consumer that reads the whole file sends it on.
printf '%s' "$(cat "$tmp/raw")" >"$tmp/token"
[ -s "$tmp/token" ] || { echo "mint-token produced no token" >&2; exit 1; }

kubectl create secret generic "$SECRET" -n "$TARGET_NS" \
  --from-file=token="$tmp/token" --dry-run=client -o yaml |
  kubectl apply -f -
```

- Use a new Secret name for each token. On an existing Secret, `kubectl apply` overwrites its `token` key without a warning. Never use the name of a Secret that another tool owns.
- Do not put the Secret in the LutherAuth namespace unless the workload runs there. Keep the people who can read service tokens to the people who need them.
- A workload that reads the Secret as an environment variable needs a restart to see a new token. A workload that reads the mounted file sees it on its own.
- To hand the token to a secret store outside the cluster, pipe the `kubectl exec` output into that store's command. Do not copy it through the terminal.

### Replace a minted token

A minted token works until its `exp`. To replace it, mint a new one, give it to the caller, and let the old one expire.

An access token cannot be revoked. To stop a leaked token before its `exp`, replace the signing key:

1. Set `AUTH_JWT_SIGN_KEY` to a new key. Do not set `AUTH_JWT_SIGN_KEY_PREVIOUS`: it keeps the old public key in the JWKS, so the leaked token keeps working.
2. Roll the LutherAuth pods.
3. Wait 10 minutes. Services on lutherauth-sdk-go keep keys in a cache for up to 10 minutes, so they accept the old token until the cache expires.
4. Mint new tokens for every caller that had one.

Every token signed with the old key stops working, user tokens included. Users sign in again.

### Who can mint

`mint-token` is not a security boundary. A person who can run `kubectl exec` in the LutherAuth pod can also read the signing key and sign any token. Limit the Kubernetes `pods/exec` permission on the LutherAuth namespace to the people who may mint tokens. The Kubernetes audit log records each `exec`. The command gives those people one standard path that keeps tokens to the client list.
