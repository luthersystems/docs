---
description: Reference for builtin functions.
---

# Standard Library

This page shows the most used functions with examples. The [Function Reference](function-reference.md) lists every function, macro and package of the ELPS release this site runs, generated from elps itself.

## Common Functions

### `debug-print`

Prints the supplied value(s).

```
elps> (set 'test (sorted-map "K" "V"))
(sorted-map "K" "V")
elps> (debug-print "Hello" test)
"Hello" (sorted-map "K" "V")
()
```

### `json:dump-string`

JSON encodes a value, returning the JSON as a string.

```
elps> (json:dump-string (sorted-map "K" "V"))
"{\"K\":\"V\"}"
```

### `json:dump-bytes`

JSON encodes a value, returning the JSON as bytes.

```
elps> (json:dump-bytes (sorted-map "K" "V"))
#<bytes 123 34 75 34 58 34 86 34 125>
elps> (to-string (json:dump-bytes (sorted-map "K" "V")))
"{\"K\":\"V\"}"
```

### `to-string`

Converts primitive values to their string representation.

```
elps> (to-string 1.0)
"1"
elps> (to-string 1.01)
"1.01"
elps> (to-string true)
"true"
```

### `to-bytes`

Converts a string value to bytes.

```
elps> (to-bytes "ABC123")
#<bytes 65 66 67 49 50 51>
```

### `to-int`

Converts string digits (\[0-9\]+) and floats to integers. For floats the fractional part is discarded. Allows integer to pass through.

```lisp
(to-int "42")
; 42
(to-int 42)
; 42
(to-int 42.9)
; 42
; (to-int "4.2") raises an error: "4.2" is not an integer
```

### `to-float`

Converts strings and integers to floats. Allows floats to pass through.

```
elps> (to-float "42.2")
42.2
elps> (to-float 42)
42
elps> (to-float -1.23456e+1)
-12.3456
```

### `car`

Returns the first element in a list.

```
elps> (car '("one" "two" "three"))
"one"
```

### `cdr`

Returns the list after the first item.

```
elps> (cdr '("head" "body" "tail"))
'("body" "tail")
```

### `rest`

Returns the sequence (list, vector) after the first item.

```
elps> (rest (vector "one" "two" "three" "four"))
'("two" "three" "four")
```

```
first / second
```

```
elps> (first '("one" "two" "three"))
"one"
elps> (second '("one" "two" "three"))
"two"
```

### `nth`

Gets the nth element of a sequence.

```
elps> (nth '(1 2 3 4) 0)
1
elps> (nth '(1 2 3 4) 3)
4
elps> (nth '(1 2 3 4) 4)
()
```

### `map`

Applies a function to a sequence of values.

```
elps> (defun cube (v) (* v v v))
()
elps> (map 'vector cube '(1 2 3 4 5 6))
(vector 1 8 27 64 125 216)
elps> (map 'vector (lambda (v) (* v v)) '(1 2 3 4 5 6))
(vector 1 4 9 16 25 36)
```

### `foldl`

Reduces a sequence using an applicator function and with an accumulator, evaluating from the left.

```
elps> (defun add (x y) (+ x y))
()
elps> (foldl add 0 '(1 2 3))
6
elps> (foldl add 10 '(1 1 1))
13
elps> (foldl (lambda (acc v) (assoc! acc (to-string v) v)) (sorted-map) '(1 2 3))
(sorted-map "1" 1 "2" 2 "3" 3)
elps> (foldl - 0 '(1 2 3))
-6 ; (((0 - 1) - 2) - 3)
```

### `foldr`

Reduces a sequence using an applicator function and with an accumulator, evaluating from the right.

```
elps> (foldr - 0 '(1 2 3))
2 ; (1 - (2 - (3 - 0)))
```

### `compose`

Returns a function that is the combination of two functions, with the first function using the product of the second function as its input.

```
elps> (set 'fn (compose (lambda (a) (+ a 1)) (lambda (b) (+ b 2))))
(lambda (b) (lisp:funcall (lambda (a) (+ a 1)) (lisp:apply (lambda (b) (+ b 2)) b ())))
elps> (fn 1)
4
```

### `unpack`

Unpack is a special case of apply and is more cumbersome. Instead of using unpack it is better to use apply and funcall.

```lisp
(unpack (lambda (x y) (+ x y)) '(2 7))
9
; (unpack (lambda (x y) (+ x y)) '(2 7 6)) raises an error: invalid number of arguments: 3
```

### `flip`

Returns a function with the parameter order reversed, the input function must have two parameters.

```
elps> (set 'fn (flip (lambda (x y) (concat 'string x y))))
(lambda (x y) ((lambda (x y) (concat 'string x y)) y x))
elps> (fn "hello" "world")
"worldhello"
```

### `assoc`

Associates a new key and value to a map, returning a copy without mutating the source map.

```
elps> (set 'test (sorted-map))
(sorted-map)
elps> (assoc test "1" 1)
(sorted-map "1" 1)
elps> test
(sorted-map)
```

### `assoc!`

Associates a new key and value to a map, mutating the source map in-place.

```
elps> (set 'test (sorted-map))
(sorted-map)
elps> (assoc! test "1" 1)
(sorted-map "1" 1)
elps> test
(sorted-map "1" 1)
```

### `dissoc`

Dissociate a value from a map via a key, returning a copy without mutating the source map.

```
elps> (set 'test (sorted-map "A" 1 "B" 2))
(sorted-map "A" 1 "B" 2)
elps> (dissoc test "A")
(sorted-map "B" 2)
elps> test
(sorted-map "A" 1 "B" 2)
```

### `dissoc!`

Dissociate a value from a map via a key, mutating the source map in-place.

```
elps> (set 'test (sorted-map "A" 1 "B" 2))
(sorted-map "A" 1 "B" 2)
elps> (dissoc! test "A")
(sorted-map "B" 2)
elps> test
(sorted-map "B" 2)
```

### `get`

Gets a map value by key.

```
elps> (set 'test (sorted-map "A" 1 "B" 2))
(sorted-map "A" 1 "B" 2)
elps> (get test "A")
1
```

### `keys`

Returns the key values of a map.

```
elps> (set 'test (sorted-map "A" 1 "B" 2))
(sorted-map "A" 1 "B" 2)
elps> (keys test)
'("A" "B")
```

### `key?`

Checks if the a key exists in a map.

```
elps> (set 'test (sorted-map "A" 1 "B" 2))
(sorted-map "A" 1 "B" 2)
elps> (key? test "X")
false
elps> (key? test "B")
true
```

### `concat`

Concatenates values.

```
elps> (concat 'string "A" "B" "C")
"ABC"
elps> (concat 'list '("A" "B" "C") '(1 2 3))
'("A" "B" "C" 1 2 3)
```

### `insert-index`

Inserts a value into a sequence at a specific index.

```lisp
(set 'test '(1 2 3))
'(1 2 3)
(insert-index 'list test 0 999)
'(999 1 2 3)
; (insert-index 'list test 42 123) raises an error: index out of bounds
```

### `stable-sort`

Performs a stable sort on a list using a predicate. The last argument can optionally be a function that takes the key and returns the comparison value. Mutates the list in-place.

```
elps> (set 'test (list 1 2 3))
'(1 2 3)
elps> (stable-sort > test)
'(3 2 1)
elps> (set 'test (list "C" "B" "A"))
'("C" "B" "A")
elps> (set 'lookup (sorted-map "A" 9 "B" 7 "C" 8))
(sorted-map "A" 9 "B" 7 "C" 8)
elps> (stable-sort > test (lambda (key) (get lookup key)))
'("A" "C" "B")
```

### `insert-sorted`

Inserts a value in its sort position.

```
elps> (set 'test '(1 2 4))
'(1 2 4)
elps> (insert-sorted 'list test < 3)
'(1 2 3 4)
```

### `search-sorted`

Search uses binary search to find and return the smallest index i in \[0, n) at which f(i) is true, assuming that on the range \[0, n), f(i) == true implies f(i+1) == true.

```
elps> (set 'test '(1 2 4))
'(1 2 4)
elps> (search-sorted (length test) (lambda (i) (= 4 (nth test i))))
2
```

### `select`

Selects values matching the predicate.

```
elps> (select 'list int? '("A" 1 "B" 2 "C" 3))
'(1 2 3)
```

### `reject`

Rejects values matching the predicate.

```
elps> (reject 'list int? '("A" 1 "B" 2 "C" 3))
'("A" "B" "C")
```

### `zip`

Zips one or more lists, composing a list of values from each input list. Tuples length is restricted to the smallest input list length.

```
elps> (zip 'list '(1 2 3))
'('(1) '(2) '(3))
elps> (zip 'list '(1 2 3) '("A" "B" "C") '(4 5 6))
'('(1 "A" 4) '(2 "B" 5) '(3 "C" 6))
elps> (zip 'list '(1 2 3) '("A" "B" "C") '(4 5))
'('(1 "A" 4) '(2 "B" 5))
```

### `make-sequence`

Generates a sequence, with an optional step value.

```
elps> (make-sequence 0 10)
'(0 1 2 3 4 5 6 7 8 9)
elps> (make-sequence 0 10 2)
'(0 2 4 6 8)
elps> (make-sequence 0 10 4)
'(0 4 8)
```

### `format-string`

Creates a string using format placeholders and values.

```lisp
(format-string "Hello {}, {} you?" "World" "how are")
```

### `reverse`

Reverses a sequence.

```
elps> (reverse 'list '(1 2 3))
'(3 2 1)
elps> (reverse 'list (reverse 'list '(1 2 3)))
'(1 2 3)
```

### `slice`

Returns the sub-slice of a sequence.

```lisp
(set 'test (make-sequence 0 10))
'(0 1 2 3 4 5 6 7 8 9)
(slice 'list test 3 6)
'(3 4 5)
; (slice 'list test 3 0) raises an error: end before start
```

### `list`

Returns a list compose of the supplied parameters.

```lisp
(list "A" 123 456 "B" '(0 1 2))
```

### `vector`

Creates a vector (array) value.

```
elps> (vector)
(vector)
elps> (vector 1 "2" 'three)
(vector 1 "2" 'three)
```

### `append`

Appends to the vector, returning a copy without mutating the source vector.

```
elps> (set 'test (vector 1 2))
(vector 1 2)
elps> (append 'vector test 3)
(vector 1 2 3)
elps> test
(vector 1 2)
```

### `append!`

Appends to the vector, mutating the source vector in-place.

```
elps> (set 'test (vector 1 2))
(vector 1 2)
elps> (append! test 3)
(vector 1 2 3)
elps> test
(vector 1 2 3)
```

### `append-bytes`

Appends to the byte vector, returning a copy without mutating the source vector.

```
elps> (set 'test (to-bytes "hello world"))
#<bytes 104 101 108 108 111 32 119 111 114 108 100>
elps> (append-bytes! test "!")
#<bytes 104 101 108 108 111 32 119 111 114 108 100 33>
elps> (to-string test)
"hello world"
```

### `append-bytes!`

Appends to the byte vector, mutating the source vector in-place.

```
elps> (set 'test (to-bytes "hello world"))
#<bytes 104 101 108 108 111 32 119 111 114 108 100>
elps> (append-bytes! test "!")
#<bytes 104 101 108 108 111 32 119 111 114 108 100 33>
elps> (to-string test)
"hello world!" ; Note exclamation mark
```

### `aref`

Gets the array element at the given index (counted from zero).

```lisp
(aref (vector "A" "B" "C") 0)
; "A"
(aref (vector "A" "B" "C") 0)
; "A"
(aref (vector "A" "B" "C") 2)
; "C"
; (aref (vector "A" "B" "C") 3) raises an error: index out of bounds
```

### `all?`

Test all items in a sequence match against a function.

```
elps> (all? (lambda (x) (> x 0)) '(1 2 3 4 5))
true
elps> (all? (lambda (x) (> x 0)) '(1 2 3 4 -5))
false
```

### `any?`

Test if any item in a sequence matches against a function.

```
elps> (any? string? '(1 2 3 4 5))
false
elps> (any? string? '(1 2 "3" 4 -5))
true
```

### `true?`

Checks if a value is truthy.

```
elps> (true? ())
false
elps> (true? "")
true
elps> (true? false)
false
elps> (true? true)
true
```

---

## Type Checking

```
elps> (nil? ())
true
elps> (nil? false)
false
elps> (list? '())
true
elps> (list? '(1 2 3))
true
elps> (list? "hello")
false
elps> (sorted-map? (sorted-map "hello" "world"))
true
elps> (sorted-map? "hello world")
false
elps> (array? (vector 1 2))
true
elps> (array? (list 1 2))
false
elps> (vector? (vector 1 2))
true
elps> (vector? (list 1 2))
false
elps> (bool? true)
true
elps> (bool? ())
false
elps> (number? 1.0)
true
elps> (number? 100)
true
elps> (number? "100")
false
elps> (int? 1)
true
elps> (int? -1)
true
elps> (int? -1.0)
false
elps> (float? 1)
false
elps> (float? 1.0)
true
elps> (symbol? 'hi)
true
elps> (symbol? "hi")
false
elps> (string? "")
true
elps> (string? "hi")
true
elps> (string? 'hi)
false
elps> (bytes? "hello")
false
elps> (bytes? (to-bytes "hello"))
true
```

### empty?

Determine if a sequence or string is empty.

```
elps> (empty? "")
true
elps> (nil? "")
false
elps> (empty? (vector))
true
elps> (empty? (list))
true
elps> (nil? (vector))
false
elps> (nil? (list))
true
```

---

## math

The `math` package has number functions and constants. Write each name with the `math:` prefix.

| Name | Returns |
|---|---|
| `(math:abs n)` | The absolute value of `n` |
| `(math:floor n)`, `(math:ceil n)` | `n` rounded down, or up, to an int |
| `(math:sqrt n)` | The square root of `n` |
| `(math:exp n)`, `(math:ln n)` | e to the power `n`, and the natural logarithm of `n` |
| `(math:log base n)` | The logarithm of `n` to `base` |
| `(math:sin r)`, `(math:cos r)`, `(math:tan r)` | Trigonometric functions of `r` radians. `asin`, `acos`, `atan` and the hyperbolic forms `sinh`, `cosh`, `tanh`, `asinh`, `acosh`, `atanh` are also available |
| `(math:nan? n)` | `true` when `n` is not a number (NaN) |
| `math:pi`, `math:inf`, `math:-inf` | The constants pi, positive infinity and negative infinity |

These functions use floating-point numbers. Do not use them for money: use the [decimal](../substrate/decimals.md) functions.

```lisp
(defun instalments (total)
  ; Split a total into equal payments of at most 250.
  (let ([count (math:ceil (/ total 250.0))])
    (list count (/ total count))))

(list (instalments 1000)
      (math:abs -42)
      (math:floor 2.7)
      (math:sqrt 16))  ; evaluates to '('(4 250) 42 2 4)
```

---

## regexp

The `regexp` package matches text against regular expressions. The pattern syntax is the [Go RE2 syntax](https://github.com/google/re2/wiki/Syntax).

| Name | Returns |
|---|---|
| `(regexp:regexp-compile pattern)` | A compiled regular expression. A bad pattern raises an error |
| `(regexp:regexp-match? re text)` | `true` when `text` contains a match for `re` |
| `(regexp:regexp-pattern re)` | The pattern string of `re` |
| `(regexp:regexp? value)` | `true` when `value` is a compiled regular expression |

Compile a pattern one time, at the top level of a file, and use it many times. To check a field of a request, you can also use the [`s:regexp`](schema.md#constraints) constraint.

```lisp
(set 'invoice-number (regexp:regexp-compile "^INV-[0-9]{4}$"))

(map 'list
     (lambda (s) (regexp:regexp-match? invoice-number s))
     (list "INV-0042" "inv-0042" "INV-42"))  ; evaluates to '(true false false)
```

`regexp-match?` finds a match anywhere in the text. Use `^` and `$` to match the whole text.

---

## base64

The `base64` package encodes bytes as base64 text and decodes it. Both functions return bytes. Use `to-string` to get a string.

| Name | Returns |
|---|---|
| `(base64:encode data)` | The base64 encoding of `data` (a string or bytes), as bytes |
| `(base64:decode text)` | The bytes that `text` encodes. Text that is not base64 raises an error |

```lisp
(set 'encoded (to-string (base64:encode (json:dump-string (sorted-map "claim_id" "c-1")))))

(list encoded
      (json:load-bytes (base64:decode encoded)))
```
