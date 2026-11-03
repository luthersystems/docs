---
description: Use ELPS record types to keep data and the methods that change it together, with checks on every change.
---

# Records and Interfaces

A record type defines objects with named, typed fields and with methods that change them. The type checks every field when an object is made and every change a method makes. A failed method leaves the object as it was before the call.

Use a record type for a business object with rules, for example an account that must never go below zero. Use a [validator](schema.md) for data that you only read, such as a request body.

Record types are part of the `schema` package (`s:`), from ELPS v1.95.0. To run an example, paste it into `elps repl`, or read this page on [docs.luthersystems.com](https://docs.luthersystems.com/develop-business-logic/business-logic/language-guide/records), where each example runs in your browser.

---

## Define a record type

```lisp
(set 'type-name
  (s:make-record "type-name"
    field...
    method...
    :check check-function))
```

- A field is `(s:has-key "name" type...)` or, for a field that can be left out, `(s:may-have-key "name" type...)`. The types are the ones a [validator](schema.md#types) takes.
- A method is `(s:method name (receiver args...) body...)`. The receiver is the object the method is called on.
- `:check` is optional. It is a function of the object that raises an error when the object breaks a rule.
- Bind the type with `set` at the top level of a file.

Call the type to make an object. Call the object with a quoted name to read a field or call a method.

```lisp
(set 'account
  (s:make-record "account"
    (s:has-key "owner" s:string)
    (s:has-key "balance" s:number)
    (s:method deposit (acct amount)
      (s:set-field! acct 'balance (+ (acct 'balance) amount)))
    (s:method withdraw (acct amount)
      (s:set-field! acct 'balance (- (acct 'balance) amount)))
    :check (lambda (acct)
             (when (< (acct 'balance) 0)
               (error 'overdrawn (acct 'balance))))))

(set 'acct (account :owner "Ada" :balance 100))
(acct 'deposit 50)
(acct 'withdraw 30)
(list (acct 'owner) (acct 'balance))  ; evaluates to '("Ada" 120)
```

You can also make an object from a sorted map, for example a JSON object: `(account (json:load-string "..."))`. The type checks each field, so a request with a bad field fails there.

---

## Method calls are atomic

A method call works like a database transaction. If the method raises an error, or `:check` refuses the object after it, every field goes back to its value before the call. Code that catches the error still has a valid object.

```lisp
(set 'account
  (s:make-record "account"
    (s:has-key "balance" s:number)
    (s:method withdraw (acct amount)
      (s:set-field! acct 'balance (- (acct 'balance) amount)))
    :check (lambda (acct)
             (when (< (acct 'balance) 0)
               (error 'overdrawn (acct 'balance))))))

(set 'acct (account :balance 100))

(set 'result (ignore-errors (acct 'withdraw 500)))  ; :check raises overdrawn

(list result (acct 'balance))  ; evaluates to '(() 100)
```

The rollback covers one object. If a method changes two objects and then fails, the other object keeps its change. A phylum endpoint that raises an error already rolls back its whole transaction, so the rollback matters when your code catches an error and keeps going.

---

## Rules for changes

| Rule | Why |
|---|---|
| Change a field only with `s:set-field!`, in a method of the object's type | So every change goes through the type's checks |
| Do not change a field in `:check` | `:check` only reads the object |
| Add a method later with `s:defmethod` only at the top level of a file | The type must be complete when the phylum finishes loading |
| Build a new value and set it, do not change a field's value in place (for example with `assoc!`) | The type cannot see or undo a change in place |

A call that breaks one of the first three rules raises `record-error`. The ELPS lint checks, such as `record-set-outside-method`, report these mistakes before the code runs.

---

## Typed arguments

Write a method argument as `[name type]` to check it before the body runs. A bad call changes nothing. `:returns type`, after the arguments, checks the value the method returns.

```lisp
(set 'positive (s:make-validator "positive" s:number (s:positive)))

(set 'wallet
  (s:make-record "wallet"
    (s:has-key "balance" s:number)
    (s:method top-up (w [amount positive] &optional [memo s:string])
      (s:set-field! w 'balance (+ (w 'balance) amount)))
    (s:method available (w) :returns s:number
      (w 'balance))))

(set 'w (wallet :balance 0))
(w 'top-up 25 "card")
(list (w 'available)
      (s:is? (ignore-errors (w 'top-up -5)) s:nil))  ; evaluates to '(25 true)
```

Call `(w 'top-up -5)` alone to see the error. It names the method and the argument.

| Argument | Checked |
|---|---|
| `[amount positive]` | Always |
| `&optional [memo s:string]` | When the call gives it |
| `&key [fee s:number]` | When the call gives `:fee` |
| `&rest [xs s:number]` | Each item |

Use `[other :self]` for an argument of the type you define, and `[to 'payee]` for a type that is defined later in the file.

---

## Interfaces

An interface names a set of methods. An object satisfies an interface when its type has each method, with arguments that accept each call the interface allows. A type does not need to say which interfaces it satisfies.

Use an interface when code must work with more than one record type. This example pays any object that has a `pay` method:

```lisp
(set 'payable (s:make-interface "payable" (pay (amount)) (amount-due ())))

(set 'invoice
  (s:make-record "invoice"
    (s:has-key "supplier" s:string)
    (s:has-key "due" s:number)
    (s:method amount-due (inv) (inv 'due))
    (s:method pay (inv amount)
      (s:set-field! inv 'due (- (inv 'due) amount)))))

(set 'payroll
  (s:make-record "payroll"
    (s:has-key "staff" (s:map-of s:string s:number))
    (s:method amount-due (run)
      (foldl (lambda (total name) (+ total (get (run 'staff) name)))
             0 (keys (run 'staff))))
    (s:method pay (run amount)
      (s:set-field! run 'staff (sorted-map)))))

(defun pay-in-full (bill)
  (s:validate payable bill)
  (let ([due (bill 'amount-due)])
    (bill 'pay due)
    due))

(map 'list pay-in-full
  (list (invoice :supplier "Acme" :due 400)
        (payroll :staff (sorted-map "ana" 3000 "li" 2800))))  ; evaluates to '(400 5800)
```

An interface is a validator. Use it as the type of a field, `(s:has-key "payer" payable)`, or of a list, `(s:of payable)`.

To require a type to satisfy an interface, add `:implements (payable)` to `s:make-record`. A method that does not fit then fails when the type is defined.

---

## Use records with match

[`match`](pattern-matching.md) can test the type of an object and bind its fields:

```lisp
(set 'invoice
  (s:make-record "invoice"
    (s:has-key "supplier" s:string)
    (s:has-key "due" s:number)))

(set 'payroll
  (s:make-record "payroll"
    (s:has-key "staff" (s:map-of s:string s:number))))

(defun describe-bill (bill)
  (match bill
    ((invoice :supplier who :due due) :when (> due 0) (list 'owe who due))
    ([_ invoice] 'paid-invoice)
    ((payroll :staff staff) (list 'payroll-for (length (keys staff))))
    (_ 'unknown)))

(map 'list describe-bill
  (list (invoice :supplier "Acme" :due 400)
        (invoice :supplier "Bolt" :due 0)
        (payroll :staff (sorted-map "ana" 3000))
        "not a bill"))
```

---

## Other functions

| Function | Returns |
|---|---|
| `(s:fields obj)` | A copy of the object's fields as a sorted map |
| `(s:record? value)` | `true` when the value is an object of a record type |
| `(s:defmethod type name (receiver args...) body...)` | Adds a method to a type, at the top level of a file |
| `(s:ref type)` | A type that passes an object of `type` and does not check its fields. Use it only for objects your own code made |
