---
description: Use the ELPS match operator to test a value against patterns and bind the parts you need.
---

# Pattern Matching

`match` tests one value against a list of patterns. The first pattern that fits runs its body, with the names the pattern binds. Use it when the shape of a value decides what to do, for example when one endpoint takes several kinds of request.

`match` is in ELPS v1.93.0 and later. To run an example, paste it into `elps repl`, or read this page on [docs.luthersystems.com](https://docs.luthersystems.com/develop-business-logic/business-logic/language-guide/pattern-matching), where each example runs in your browser.

---

## When to use match

Use `match` when your code reads a value and then branches on what it contains. The usual case is input from outside the phylum: a JSON request, an event or a message from a connector. Each kind of input has its own fields, and the code must read the right fields for each kind.

This example handles claim events. Each event is a JSON object with a `type`. A large claim goes to a person for review. An event with a missing or unknown field is refused.

Without `match`, the code tests the type, reads each field with `get`, and checks each field by hand:

```lisp
(defun handle-claim-event (event)
  (let* ([type (get event "type")]
         [id (get event "claim_id")])
    (cond
      ((nil? id) (list 'refused "no claim_id"))
      ((equal? type "submitted")
       (let ([amount (get event "amount")])
         (cond ((nil? amount) (list 'refused "no amount"))
               ((> amount 10000) (list 'review id amount))
               (:else (list 'open id amount)))))
      ((equal? type "approved")
       (let ([approver (get event "approver")])
         (if (nil? approver)
           (list 'refused "no approver")
           (list 'approved id approver))))
      ((equal? type "rejected")
       (list 'rejected id (get event "reason")))
      (:else (list 'refused "unknown event")))))
```

With `match`, each clause states the shape of one kind of event and names the fields it needs. A clause fits only if every field it names is present, so a missing field falls through to the last clause.

```lisp
(defun handle-claim-event (event)
  (match event
    ((sorted-map "type" "submitted" "claim_id" id "amount" amount)
     :when (> amount 10000)
     (list 'review id amount))
    ((sorted-map "type" "submitted" "claim_id" id "amount" amount)
     (list 'open id amount))
    ((sorted-map "type" "approved" "claim_id" id "approver" approver)
     (list 'approved id approver))
    ((sorted-map "type" "rejected" "claim_id" id "reason" reason)
     (list 'rejected id reason))
    (:else (list 'refused event))))

(map 'list handle-claim-event
  (json:load-string """[
    {"type": "submitted", "claim_id": "c-1", "amount": 2500},
    {"type": "submitted", "claim_id": "c-2", "amount": 48000},
    {"type": "approved", "claim_id": "c-1", "approver": "ana"},
    {"type": "approved", "claim_id": "c-3"}
  ]"""))
```

The fourth event has no `approver`, so no clause for `approved` fits and the event is refused. Change the events to try other shapes.

Use `cond` in place of `match` when you test conditions that do not depend on the shape of one value, for example two unrelated flags.

---

## Syntax

```lisp
(match value
  (pattern body...)
  (pattern :when guard body...)
  (:else body...))
```

- `match` evaluates `value` one time.
- It tries each clause in order. A clause is a pattern, an optional `:when` guard and a body.
- The body of the first clause whose pattern fits, and whose guard is true, gives the result.
- A last `(:else body...)` clause fits every value.
- If no clause fits, `match` returns `()`.

---

## Match literal values

A number, string, keyword, `true`, `false` or `()` fits a value that is `equal?` to it. The pattern `_` fits every value and binds no name.

```lisp
(defun fee-percent (tier)
  (match tier
    ("gold" 0)
    ("silver" 1)
    (_ 2)))

(list (fee-percent "gold") (fee-percent "silver") (fee-percent "trial"))  ; evaluates to '(0 1 2)
```

Quote a symbol to match it. An unquoted symbol is a name that binds the value.

```lisp
(defun status-label (status)
  (match status
    ('paid "Paid")
    ('open "Open")
    (other (concat 'string "Unknown: " (to-string other)))))

(list (status-label 'paid) (status-label 'void))  ; evaluates to '("Paid" "Unknown: void")
```

---

## Take a list apart

`(list p...)` fits a list with exactly that number of items. Each item must fit its pattern. Add `&rest name` to fit a list with at least that number of items. `name` gets the other items as a new list.

```lisp
(defun run-command (cmd)
  (match cmd
    ((list 'deposit account amount) (list 'credit account amount))
    ((list 'transfer from to amount) (list 'debit from amount 'credit to amount))
    ((list 'notify &rest accounts) (list 'send-to (length accounts) 'accounts))
    (_ (list 'unknown-command cmd))))

(map 'list run-command
  (list (list 'deposit "acct-1" 100)
        (list 'transfer "acct-1" "acct-2" 40)
        (list 'notify "acct-1" "acct-2" "acct-3")
        (list 'close "acct-1")))
```

A list pattern fits only a list. It does not fit a vector, so the pattern also tests the type.

---

## Take a vector apart

`(vector p...)` fits a vector (a one-dimensional array) in the same way. Use it for the arrays that `json:load-string` returns. With `&rest`, the name gets the other items as a new vector.

```lisp
(defun first-line-item (lines)
  (match lines
    ((vector) "no lines")
    ((vector first &rest others) (list first (length others) 'more))))

(first-line-item (json:load-string "[\"apple\", \"pear\", \"plum\"]"))  ; evaluates to '("apple" 2 'more)
```

---

## Read keys from a sorted map

`(sorted-map key p ...)` fits a sorted map that has each key, with a value that fits the pattern. A key is a string, an int or a keyword. The map can have other keys.

```lisp
(defun payment-summary (payment)
  (match payment
    ((sorted-map "status" "paid" "amount" amount) (list 'paid amount))
    ((sorted-map "status" status) (list 'not-paid status))
    (:else 'unknown)))

(list
  (payment-summary (json:load-string "{\"status\": \"paid\", \"amount\": 120}"))
  (payment-summary (json:load-string "{\"status\": \"pending\"}"))
  (payment-summary (sorted-map)))
```

A pattern can hold another pattern. This clause reads a list from inside a map:

```lisp
(match (json:load-string "{\"point\": [3, 4]}")
  ((sorted-map "point" (vector x y)) (+ (* x x) (* y y))))  ; evaluates to 25
```

---

## Add a guard

Put `:when guard` after a pattern. The guard can use the names the pattern binds. If the guard is false, `match` tries the next clause. This example checks a payment amount.

```lisp
(defun payment-check (amount)
  (match amount
    (x :when (<= x 0) "refuse: not a positive amount")
    (x :when (> x 10000) "hold for review")
    (_ "pay")))

(map 'list payment-check (list -5 0 48000 250))
```

---

## Match on type

`[name T]` fits a value of type `T` and binds `name`. `T` is a type from the schema package `s`, for example `s:string` or `s:int`, a record type or an interface. Use `_` as the name to test the type only. This example accepts a customer ID as a string or as an int from an older client.

```lisp
(defun customer-key (id)
  (match id
    ([s s:string] s)
    ([n s:int] (concat 'string "cust-" (to-string n)))
    (_ ())))

(map 'list customer-key (list "cust-9" 42 1.5))  ; evaluates to '("cust-9" "cust-42" ())
```

---

## Match a record

`(T :field p ...)` fits an object of the record type `T` whose fields fit the patterns. A field that is not set reads as `()`. `(T)` tests the type only. For record types, see the `s:make-record` section of the [libschema README](https://github.com/luthersystems/elps/blob/main/lisp/lisplib/libschema/README.md).

```lisp
(set 'point
  (s:make-record "point"
    (s:has-key "x" s:int)
    (s:has-key "y" s:int)))

(defun where (p)
  (match p
    ((point :x 0 :y 0) "origin")
    ((point :x 0 :y y) (concat 'string "on the y axis at " (to-string y)))
    ((point :x x :y y) (list x y))))

(map 'list where (list (point :x 0 :y 0) (point :x 0 :y 5) (point :x 2 :y 3)))
```

---

## Rules

| Rule | Detail |
|------|--------|
| No clause fits | `match` returns `()`. It does not raise an error. |
| Order | Clauses are tried from top to bottom. Put specific patterns before general ones. |
| Repeated names | A pattern that binds the same name two times is an error. |
| Literal lists | The reader reads `[x T]` and `'(x T)` as the same value. To match a literal list, write `(list 'a 'b)`. |
| Guard errors | A false guard goes to the next clause. An error in a guard stops the match. |
| Cost | Each pattern node that `match` tries costs one step. |
| Lint | The `match-unreachable` check of `elps lint` reports a clause that can never run: a clause after one that fits every value, or a clause that repeats an earlier pattern with no guard. |

The same patterns work in `let` and `let*` bindings. See [Destructuring in let](let-destructuring.md).

The full reference is the `match` section of the [ELPS language reference](https://github.com/luthersystems/elps/blob/main/docs/lang.md#match).
