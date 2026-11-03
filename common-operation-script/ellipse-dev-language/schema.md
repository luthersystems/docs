---
description: Use the ELPS schema package to check the type and shape of a value before your code uses it.
---

# Validating Data

The `schema` package checks that a value has the type and shape your code expects. Use it at the edge of a phylum, on each request and on each value you read from storage, so that the rest of the code can trust its data.

The package name is `s`. Write each name with the prefix, for example `s:validate`. Do not `(use-package 's)`: some of its names, such as `s:list` and `s:when`, then hide the core forms with the same names.

The `schema` package is in every phylum. To run an example, paste it into `elps repl`, or read this page on [docs.luthersystems.com](https://docs.luthersystems.com/develop-business-logic/business-logic/language-guide/schema), where each example runs in your browser.

---

## Why validate

A request body is JSON from outside the phylum. A field can be missing, have the wrong type or hold a value your business rules do not allow. Without a check, the error shows up later, far from its cause, or bad data goes into the ledger.

A validator states the rules in one place. `s:validate` returns `()` when the value passes, and raises an error that names the field when it does not.

```lisp
(set 'claim-id (s:make-validator "claim-id" s:string (s:lengt 0)))
(set 'amount (s:make-validator "amount" s:number (s:positive)))
(set 'currency (s:make-validator "currency" s:string (s:in "GBP" "EUR" "USD")))

(set 'claim-request
  (s:make-validator "claim-request" s:sorted-map
    (s:has-key "claim_id" claim-id)
    (s:has-key "amount" amount)
    (s:has-key "currency" currency)
    (s:may-have-key "note" s:string)))

(s:validate claim-request
  (json:load-string """{"claim_id": "c-1", "amount": 2500, "currency": "GBP"}"""))  ; evaluates to ()
```

Change `"GBP"` to `"JPY"`, or remove the `amount` field, to see the error.

---

## Make a validator

```lisp
(s:make-validator name type constraint...)
```

- `name` is a string. It appears in error messages.
- `type` is one of the built-in types below, or another validator.
- Each constraint adds a rule. A value must pass all of them.
- `s:make-validator` returns the validator. Bind it to a name with `set`.

`(s:validate validator value)` checks a value. `(s:is? value validator)` returns `true` or `false` in place of an error, so you can use it in a condition:

```lisp
(set 'currency (s:make-validator "currency" s:string (s:in "GBP" "EUR" "USD")))

(list (s:is? "EUR" currency) (s:is? "JPY" currency) (s:is? 5 currency))  ; evaluates to '(true false false)
```

`(s:as value validator)` returns the value when it passes, and raises the error when it does not.

---

## Types

| Type | Passes |
|---|---|
| `s:int` | An integer |
| `s:float` | A floating-point number |
| `s:number` | Any number |
| `s:string` | A string |
| `s:bool` | The symbols `true` and `false`, not the strings `"true"` and `"false"` |
| `s:bytes` | A byte sequence |
| `s:sorted-map` | A sorted map, for example a JSON object |
| `s:array` | An array, for example a JSON array |
| `s:list` | A list. `()` is the empty list |
| `s:sequence` | A list or an array |
| `s:nil` | `()`, for a field that can be empty |
| `s:fun` | A function |
| `s:error` | An error value |
| `s:tagged-value` | A value of a user-defined type |
| `s:any` | Any value |

---

## Constraints

| Constraint | The value must |
|---|---|
| `(s:in v1 v2 ...)` | Be equal to one of the values |
| `(s:regexp pattern)` | Match the regular expression ([Go syntax](https://github.com/google/re2/wiki/Syntax)) |
| `(s:gt n)`, `(s:gte n)`, `(s:lt n)`, `(s:lte n)` | Be greater than, at least, less than, or at most `n` |
| `(s:positive)`, `(s:negative)` | Be more than zero, or less than zero |
| `(s:len n)` | Have length `n` |
| `(s:lengt n)`, `(s:lengte n)`, `(s:lenlt n)`, `(s:lenlte n)` | Have a length more than, at least, less than, or at most `n` |
| `(s:of type)` | Be a list or array whose every item passes `type` |
| `(s:map-of key-type value-type)` | Be a sorted map whose every key and value pass the types |
| `(s:is-true)`, `(s:is-false)` | Be the symbol `true`, or the symbol `false` |
| `(s:is-truthy)`, `(s:is-falsy)` | Count as true, or as false |
| `(s:not constraint)` | Fail the constraint |

A constraint can also stand alone as the type of a key: `(s:has-key "currency" (s:in "GBP" "EUR"))`. Write constraints and validator names without a quote: `(s:gt 1)` and `(s:has-key "age" age)`, not `'(s:gt 1)` or `'age`.

```lisp
(set 'sort-code (s:make-validator "sort-code" s:string (s:regexp "^[0-9]{2}-[0-9]{2}-[0-9]{2}$")))
(set 'line-items (s:make-validator "line-items" s:array (s:of s:int) (s:lengt 0)))

(list (s:is? "12-34-56" sort-code)
      (s:is? "123456" sort-code)
      (s:is? (vector 120 45) line-items)
      (s:is? (vector) line-items))  ; evaluates to '(true false true false)
```

---

## Maps and JSON objects

These constraints check the keys of a sorted map. The keys are strings, as in a map from `json:load-string`.

| Constraint | Rule |
|---|---|
| `(s:has-key "k" type...)` | The key must be present, and its value must pass one of the types |
| `(s:may-have-key "k" type...)` | If the key is present, its value must pass one of the types |
| `(s:no-other-keys key-constraint...)` | The map must have no keys other than the ones the key constraints name |
| `(s:when "k" constraint "k2" constraint2...)` | When the value of `k` passes `constraint`, the value of `k2` must pass `constraint2` |

Each type after the key is an alternative: the value must pass one of them. So `(s:has-key "email" s:string s:nil)` accepts a string or `null`. To add rules to a key, make a validator with the rules and give it as the type. This is also how you build a large schema from small ones.

A JSON number is a float in ELPS, also when it has no fraction. Use `s:number`, not `s:int`, for a number that comes from JSON.

```lisp
(set 'address
  (s:make-validator "address" s:sorted-map
    (s:has-key "line1" s:string)
    (s:has-key "postcode" s:string)))

(set 'age (s:make-validator "age" s:number (s:gte 0)))

(set 'customer
  (s:make-validator "customer" s:sorted-map
    (s:no-other-keys
      (s:has-key "name" s:string)
      (s:has-key "age" age)
      (s:has-key "is_adult" s:bool)
      (s:has-key "address" address)
      (s:may-have-key "email" s:string s:nil))
    (s:when "age" (s:lt 18) "is_adult" (s:is-false))))

(s:is? (json:load-string """{
  "name": "Ada",
  "age": 36,
  "is_adult": true,
  "address": {"line1": "1 High St", "postcode": "AB1 2CD"},
  "email": null
}""") customer)  ; evaluates to true
```

Set `age` to `16` to see the `s:when` rule fail, or add a key that is not in the list to see `s:no-other-keys` fail.

---

## Handle a failed check

A check that fails raises one of two errors:

| Error | Cause |
|---|---|
| `wrong-type` | The value does not have the type, or the value of a key does not pass its validator |
| `failed-constraint` | A constraint on the value fails, for example a key is missing |

The error message names the key that failed.

A mistake in the validator itself, for example a constraint with the wrong arguments, raises `bad-arguments`. To turn a failed check into a response, catch only `wrong-type` and `failed-constraint`, so that a mistake in your own validator is not hidden:

```lisp
(set 'amount (s:make-validator "amount" s:number (s:positive)))

(defun check-amount (value)
  (handler-bind ((wrong-type (lambda (c &rest _) (list 'refused "the amount must be a number")))
                 (failed-constraint (lambda (c &rest _) (list 'refused "the amount must be more than zero"))))
    (s:validate amount value)
    (list 'ok value)))

(map 'list check-amount (list 250 -5 "250"))
```

---

## Validate a user-defined type

Pass a type that `deftype` made in place of the name. The validator then checks the value inside the tagged value. See [User-Defined Types](language-guide.md#user-defined-types).

```lisp
(deftype account-id (id) id)
(set 'valid-account-id (s:make-validator account-id s:string (s:regexp "^acct-[0-9]+$")))

(list (s:is? (new account-id "acct-42") valid-account-id)
      (s:is? (new account-id "42") valid-account-id))  ; evaluates to '(true false)
```

---

## Next

A validator checks data. To keep data and the functions that change it together, with the checks run on every change, use a [record type](records.md).
