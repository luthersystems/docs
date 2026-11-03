---
description: Raise, catch, group and re-raise errors in ELPS with error, handler-bind, define-condition and rethrow.
---

# Errors and Conditions

An ELPS error has a condition, a symbol that names its kind, and data. `(error 'not-found "no claim" id)` raises the condition `not-found` with the data `"no claim"` and `id`. The [Language Guide](language-guide.md#errors) shows the basics. This page shows how to group conditions, which handler runs, and how to re-raise an error with more context.

To run an example, paste it into `elps repl`, or read this page on [docs.luthersystems.com](https://docs.luthersystems.com/develop-business-logic/business-logic/language-guide/errors), where each example runs in your browser.

---

## Catch an error

`handler-bind` binds a handler function to each condition. When the body raises one of them, the handler runs and its value is the value of `handler-bind`. The handler gets the condition and the data.

```lisp
(defun find-claim (id)
  (error 'not-found "no claim" id))

(handler-bind ((not-found (lambda (c &rest data) (list 'missing data))))
  (find-claim "c-9"))  ; evaluates to '('missing '("no claim" "c-9"))
```

A binding for `condition` catches every error. Do not use it to hide errors you did not expect.

---

## Group conditions

`(define-condition 'child 'parent)` gives a condition a parent. A handler for the parent then catches the child too. Define the parents first.

ELPS gives three built-in conditions the parent `error`: `argument-error` (a bad argument to a builtin), `match-error` (a value that does not fit a [binding pattern](let-destructuring.md)) and `record-error` (a broken [record](records.md) rule).

When more than one binding matches, the most specific one runs: the binding for the condition itself, then for its nearest parent, and `condition` last. The order you write the bindings in does not matter.

```lisp
(define-condition 'claim-error 'error)
(define-condition 'claim-not-found 'claim-error)
(define-condition 'claim-closed 'claim-error)

(defun handle (thunk)
  (handler-bind ((condition (lambda (c &rest _) 'unexpected))
                 (claim-error (lambda (c &rest _) (list 'refused c)))
                 (claim-not-found (lambda (c &rest _) 'not-found)))
    (funcall thunk)))

(list (handle (lambda () (error 'claim-not-found "c-9")))
      (handle (lambda () (error 'claim-closed "c-1")))
      (handle (lambda () (error 'other "oops"))))  ; evaluates to '('not-found '('refused 'claim-closed) 'unexpected)
```

`(condition-is? 'claim-closed 'claim-error)` returns `true`.

---

## Re-raise an error

To log an error and let it continue, call `(rethrow)` in the handler. `rethrow` keeps the original stack and data. `(apply error c data)` loses the stack, so do not use it.

`(rethrow :context "text")` adds text in front of the message, as Go's `fmt.Errorf("text: %w", err)` does. The condition and the data do not change, so outer handlers still match. `(error-message)` in a handler returns the message with its context.

```lisp
(defun load-claim (id) (error 'not-found "no claim" id))

(defun approve (id)
  (handler-bind ((not-found
                   (lambda (c &rest _)
                     (rethrow :context (format-string "approving {}" id)))))
    (load-claim id)))

(handler-bind ((not-found (lambda (c &rest _) (error-message))))
  (approve "c-9"))  ; evaluates to "approving c-9: no claim c-9"
```

---

## Clean up after an error

`with-cleanup` runs cleanup forms when its body ends, also when the body raises an error. It is the `finally` of other languages. See [with-cleanup](language-guide.md#with-cleanup).

`ignore-errors` returns `()` for any error. It hides mistakes, so use `handler-bind` with named conditions where you can.
