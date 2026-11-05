---
description: Known issues in platform releases, the affected versions and the fix.
---

# Known Issues

This page lists known issues in platform releases. Each issue gives the
affected versions, the fixed version and a workaround. See the
[Release Notes](release-notes.md) for every release.

## LutherAuth v4.12.0: every refresh fails with 500

| | LutherAuth versions |
|---|---|
| **Affected** | v4.12.0, with refresh tokens on (`AUTH_ENABLE_REFRESH=true`) and a Redis user limited to `f_*` keys |
| **Not affected** | v4.11.0 and earlier. On v4.12.0, refresh works with a Redis user that may use every key, but `revoke-user` fails unless the user may also run `TTL` |
| **Fixed** | v4.13.0 and later |

v4.12.0 reads a `revoke-user` record on every refresh, under a key that does not start with `f_`. A Redis user with the [recommended permissions](connectors/lutherauth/sessions.md#redis-user-permissions) may not read that key, so Redis refuses and `POST /v1/auth/refresh` returns `500`. The v4.12.0 `revoke-user` command also runs `TTL`, which the recommended command list does not allow. Login and sign-out still work, but users are signed out when their access token expires.

Do not deploy v4.12.0. Upgrade to v4.13.0, or stay on v4.11.0 until you can.

## thread-first and thread-last refuse macro steps

| | substrate versions |
|---|---|
| **Affected** | v2.237.0 to v2.245.0 (ELPS v1.62.3 to v1.75.2) |
| **Not affected** | v2.236.0 and earlier |
| **Fixed** | v2.246.0 and later (ELPS v1.75.3) |

On an affected version, a `thread-first` or `thread-last` step fails when its
head is a macro or a special operator. Examples are `default`, `when`, `and`,
`or` and a macro that your phylum defines. The error is
`thread step is not a regular function`:

```lisp
(thread-first x (default 0) (+ 1))
```

The phylum loads, and `shirotester lint` does not report the step. The error
occurs when the endpoint runs, so unit tests that call the endpoint find it.

Upgrade to v2.246.0. Do not deploy an affected version. Until you upgrade, use a regular function as the
step:

```lisp
(defun default-to (v d) (if (nil? v) d v))
(thread-first x (default-to 0) (+ 1))
```

Details: [luthersystems/elps#820](https://github.com/luthersystems/elps/issues/820).
