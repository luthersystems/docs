---
description: Known issues in platform releases, the affected versions and the fix.
---

# Known Issues

This page lists known issues in platform releases. Each issue gives the
affected versions, the fixed version and a workaround. See the
[Release Notes](release-notes.md) for every release.

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
