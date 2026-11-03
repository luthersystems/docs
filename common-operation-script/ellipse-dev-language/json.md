---
description: How ELPS reads and writes JSON, and the rules for numbers, null, keys, canonical bytes and typed JSON.
---

# Working with JSON

Most phylum endpoints read JSON and write JSON. The `json` package converts between JSON and ELPS values. This page gives the rules that matter in a phylum: how numbers, `null` and keys convert, and how to get the same bytes on every peer.

To run an example, paste it into `elps repl`, or read this page on [docs.luthersystems.com](https://docs.luthersystems.com/develop-business-logic/business-logic/language-guide/json), where each example runs in your browser.

---

## How JSON converts

| JSON | ELPS value after `json:load-string` |
|---|---|
| object | sorted map with string keys |
| array | vector |
| string | string |
| number | float, also when it has no fraction (see [Numbers](#numbers)) |
| `true`, `false` | the symbols `true` and `false` |
| `null` | `()` |

`json:dump-string` and `json:dump-bytes` convert the other way. A list dumps as a JSON array. `()` dumps as `null`.

```lisp
(set 'request (json:load-string """{"claim_id": "c-1", "items": [1, 2], "note": null, "urgent": true}"""))

(list (get request "claim_id")
      (get request "items")
      (get request "note")
      (get request "urgent"))  ; evaluates to '("c-1" (vector 1 2) () true)
```

---

## Numbers

**Every JSON number loads as a float.** `2500` loads as the float `2500`. This has two effects:

- A function that needs an int, such as `nth`, refuses the value. A schema check with `s:int` fails. Use `s:number`.
- An integer above 2^53 (9007199254740992) is rounded, and nothing reports it. Two different IDs can load as the same value.

Give `:exact-integers true` to a load function to keep each number that is written without a `.` or an exponent as an exact int:

```lisp
(set 'doc """{"id": 9007199254740993, "count": 3, "price": 1.5}""")

(list (json:dump-string (json:load-string doc))
      (json:dump-string (json:load-string doc :exact-integers true))
      (type (get (json:load-string doc :exact-integers true) "count")))
```

With `:exact-integers true`, an integer too large for an ELPS int raises `json:integer-range-error` in place of a rounded value. Another way to keep a large ID exact is to send it as a JSON string and convert it with `to-int`.

---

## null

A JSON `null` loads as `()`. So a key with the value `null` and a missing key read the same with `get`. Use `key?` to tell them apart:

```lisp
(set 'm (json:load-string """{"note": null}"""))

(list (get m "note") (get m "other") (key? m "note") (key? m "other"))  ; evaluates to '(() () true false)
```

To write `null`, dump `()` or the value `json:null`.

---

## Keys

A JSON object loads as a sorted map with string keys. `get` also accepts a symbol with the same name, but `keys` always returns strings.

A keyword keeps its colon when you dump it: `(sorted-map :height 1)` dumps as `{":height":1}`. Use string keys for JSON.

```lisp
(list (json:dump-string (sorted-map "height" 1))
      (json:dump-string (sorted-map :height 1)))  ; evaluates to '("{\"height\":1}" "{\":height\":1}")
```

---

## Canonical JSON for hashes and keys

Every endorser must compute the same bytes. When you hash a value, or build a state key from it, dump it in canonical form: `(json:dump-string value :canonize true)`. Canonical form converts symbols and keywords to strings, lists to vectors, bytes to base64 strings and whole-number floats to ints, and sorts the keys. Every elps version gives the same canonical bytes for the same value.

```lisp
(list (json:dump-string (list 'a :b 1.0 ()) :canonize true)
      (equal? (json:dump-string (sorted-map "b" 1 "a" 2.0) :canonize true)
              (json:dump-string (sorted-map "a" 2 "b" 1) :canonize true)))  ; evaluates to '("[\"a\",\":b\",1,null]" true)
```

A value that canonical form cannot hold exactly, such as an int above 2^53 or NaN, raises `json:canonize-error`.

---

## Typed JSON

Plain JSON loses types: `5` and `5.0` dump the same, a symbol comes back as a string and a list comes back as a vector. To store an ELPS value and get the same value back, dump it with `:typed true` and load it with `:typed true`. The output is still JSON. Only the values that plain JSON cannot tell apart get a short tag that starts with `~`.

```lisp
(set 'value (list 'approved 5.0 :urgent (vector 1 2)))

(list (json:dump-string value :typed true)
      (equal? value (json:load-string (json:dump-string value :typed true) :typed true)))
```

| ELPS value | Plain JSON | Typed JSON |
|---|---|---|
| `5` | `5` | `5` |
| `5.0` | `5` | `"~d5"` |
| `:kw` | `":kw"` | `"~:kw"` |
| `'sym` | `"sym"` | `"~$sym"` |
| `'(1 2)` | `[1,2]` | `["~#list",[1,2]]` |
| `(vector 1 2)` | `[1,2]` | `[1,2]` |
| `"~x"` | `"~x"` | `"~~x"` |
