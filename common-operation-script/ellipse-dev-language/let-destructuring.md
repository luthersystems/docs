---
description: Bind the parts of a list, vector, sorted map or record in one let or let* binding.
---

# Destructuring in let

A `let` or `let*` binding can have a pattern in place of a name. The value must fit the pattern, and each name in the pattern is bound. Use it to take a value apart in one step, in place of a chain of `nth`, `get` or field calls.

Binding patterns are in ELPS v1.93.0 and later. To run an example, paste it into `elps repl`, or read this page on [docs.luthersystems.com](https://docs.luthersystems.com/develop-business-logic/business-logic/language-guide/let-destructuring), where each example runs in your browser.

---

## Syntax

```lisp
(let ((name value)           ; a plain binding, as before
      (pattern value))       ; a binding pattern
  body...)
```

- A symbol in the name position is a name, as before. `_` is a name too.
- Any other value in the name position is a pattern.
- The patterns are the ones that [`match`](pattern-matching.md) takes, with the same rules.
- `[x 1]` and `(x 1)` are the same binding. The square brackets only make the binding easier to read.

---

## Take a list apart

```lisp
(let ([(list a b c) (list 1 2 3)])
  (+ a b c))  ; evaluates to 6
```

Use `&rest` to bind the other items as a new list:

```lisp
(let ([(list first &rest others) (list "a" "b" "c")])
  (list first others))  ; evaluates to '("a" '("b" "c"))
```

A function that returns more than one value can return a list. The caller binds each part by name:

```lisp
(defun min-max (xs)
  (list (apply min xs) (apply max xs)))

(let ([(list lo hi) (min-max (list 4 9 1 7))])
  (- hi lo))  ; evaluates to 8
```

---

## Take a vector apart

A list pattern does not fit a vector. Use a vector pattern for a value that `vector` or a JSON array gives.

```lisp
(let ([(vector x y) (json:load-string "[3, 4]")])
  (+ (* x x) (* y y)))  ; evaluates to 25
```

---

## Read keys from a sorted map

A sorted map pattern binds the value of each key. The map can have other keys. This is the usual way to read a JSON object.

```lisp
(let ([(sorted-map "name" name "age" age)
       (json:load-string "{\"name\": \"Ada\", \"age\": 36, \"city\": \"London\"}")])
  (concat 'string name " is " (to-string age)))  ; evaluates to "Ada is 36"
```

Patterns can hold other patterns. This binding reads two levels of a JSON document:

```lisp
(let ([(sorted-map "order" (sorted-map "id" id "lines" (vector first-line &rest _)))
       (json:load-string "{\"order\": {\"id\": \"o-1\", \"lines\": [\"apple\", \"pear\"]}}")])
  (list id first-line))  ; evaluates to '("o-1" "apple")
```

---

## Check a type

`[name T]` binds `name` only if the value has type `T`. In a binding, the pattern is the name, so it is in square brackets two times.

```lisp
(let ([[s s:string] "hello"])
  (string:uppercase s))  ; evaluates to "HELLO"
```

---

## Read fields from a record

A record pattern binds the fields of a record object. For record types, see the `s:make-record` section of the [libschema README](https://github.com/luthersystems/elps/blob/main/lisp/lisplib/libschema/README.md).

```lisp
(set 'point
  (s:make-record "point"
    (s:has-key "x" s:int)
    (s:has-key "y" s:int)))

(let ([(point :x x :y y) (point :x 2 :y 5)])
  (* x y))  ; evaluates to 10
```

---

## let and let*

In `let`, every value is evaluated first. Then the patterns are matched and the names are bound. A value cannot use a name from another binding of the same `let`.

In `let*`, each binding can use the names of the bindings before it, pattern names included.

```lisp
(let* ([(list start end) (list 10 25)]
       [length (- end start)]
       [(list half _) (list (/ length 2) 'unused)])
  (list start end length half))  ; evaluates to '(10 25 15 7.5)
```

---

## When the value does not fit

A value that does not fit its pattern raises `match-error`, a child of `error`. The message names the pattern and the type of the value. The example below shows the error. Remove the `3` to make the value fit.

```lisp
(let ([(list a b) (list 1 2 3)])
  (+ a b))
```

Catch `match-error` with `handler-bind` when bad input is possible:

```lisp
(defun pair-sum (v)
  (handler-bind ((match-error (lambda (c &rest args) 'not-a-pair)))
    (let ([(list a b) v])
      (+ a b))))

(list (pair-sum (list 1 2)) (pair-sum (list 1 2 3)))  ; evaluates to '(3 'not-a-pair)
```

To choose between shapes, use [`match`](pattern-matching.md). A binding has only one pattern, so a `:when` guard in a binding is an error.

---

## Rules

| Rule | Detail |
|------|--------|
| Plain names | A symbol binding works and costs what it did before patterns. |
| No fit | A value that does not fit raises `match-error`. |
| Guards | A `:when` guard in a binding is an error. |
| Scope in `let` | Every value is evaluated first, in the scope around the `let`. Then the names are bound. |
| Scope in `let*` | A value, and a type in a pattern, can use the bindings before it. |
| Cost | A pattern binding costs one step for each pattern node tried, the same as `match`. |

The full reference is the "Binding patterns" section of the [ELPS language reference](https://github.com/luthersystems/elps/blob/main/docs/lang.md#binding-patterns).
