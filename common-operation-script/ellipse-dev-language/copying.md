---
description: Which ELPS functions change a value in place, when two names share one value, and when to copy.
---

# Copying and Mutation

Lists, vectors and sorted maps are references. When you bind a value to a second name, or take part of it with `slice`, `cdr` or `rest`, both names share the same elements. A function that changes a value in place changes it for every name that shares it.

To run an example, paste it into `elps repl`, or read this page on [docs.luthersystems.com](https://docs.luthersystems.com/develop-business-logic/business-logic/language-guide/copying), where each example runs in your browser.

---

## Functions that change a value

A function whose name ends in `!` changes its argument. The function without `!` returns a new value and leaves the argument as it was.

| Returns a new value | Changes its argument |
|---|---|
| `append`, `append-bytes` | `append!`, `append-bytes!` |
| `assoc`, `dissoc` | `assoc!`, `dissoc!` |
| `concat`, `insert-index`, `reverse`, `map`, `select` | `stable-sort` |

`stable-sort` is the one exception to the rule: it has no `!`, but it sorts in place.

```lisp
(set 'limits (sorted-map "daily" 500))
(set 'raised (assoc limits "daily" 1000))   ; a new map
(assoc! limits "monthly" 5000)              ; changes limits

(list limits raised)
```

---

## Views share elements

`slice`, `cdr` and `rest` return a view. A change to an element of the view changes the source too. Adding to a view never changes the source.

```lisp
(set 'scores (vector 5 4 3 2 1))
(stable-sort < (slice 'vector scores 0 3))   ; sorts the first 3 elements of scores

scores  ; evaluates to (vector 3 4 5 2 1)
```

To get a value that nothing else can change, copy it. `copy` makes a deep copy. `concat` copies one level.

```lisp
(set 'scores (vector 5 4 3 2 1))
(set 'top (copy (slice 'vector scores 0 3)))
(stable-sort < top)

(list top scores)  ; evaluates to '((vector 3 4 5) (vector 5 4 3 2 1))
```

---

## Do not change a quoted literal

A quoted value, such as `'(3 1 2)`, is part of the program text. A change to it would change the program, so ELPS refuses it with `modify-literal-error`. Build the value with `list` or `vector`, or `copy` the literal first.

```lisp
(list (stable-sort < (list 3 1 2))
      (stable-sort < (copy '(3 1 2)))
      (handler-bind ((modify-literal-error (lambda (c &rest _) 'refused)))
        (stable-sort < '(3 1 2))))  ; evaluates to '('(1 2 3) '(1 2 3) 'refused)
```

---

## What copy does not copy

`copy` does not copy a function. A function keeps the variables it was made with, so a copy of a map of functions still changes the original. To get a new object, call its constructor again, or use a [record type](records.md).

---

## Sort and map functions must not change values

`stable-sort` calls its compare function an unknown number of times, in an unknown order, with the list's own elements. A compare function must only compare. The same rule applies to the functions you give to `map`, `select`, `foldl` and the other functions that walk a sequence: do not change the sequence they walk.

```lisp
;; Wrong: changes each element while it sorts
(stable-sort (lambda (a b) (assoc! a "seen" true) (< (get a "n") (get b "n"))) rows)

;; Right: only compares
(stable-sort (lambda (a b) (< (get a "n") (get b "n"))) rows)
```

The lint checks `comparator-mutation` and `iteration-mutation` report these mistakes.
