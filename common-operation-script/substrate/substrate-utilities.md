---
description: These utility functions are provided in the utils package.
---

# Common Utilities

You can access the following functions in the substrate REPL To run the REPL: `make repl`

---

## `caar`

Returns the first item of the first list of the outer list.

```lisp
(caar '('("A" "B" "C") '(3 2 1)))
"A"
```

---

## `cadar`

Takes the first inner list and returns the item after the first value.

```lisp
(cadar '('("A" "B" "C") '(3 2 1)))
"B"
```

---

## `cadr`

Returns the first item from the outer list after the first value.

```lisp
(cadr '('("A" "B" "C") "1" '(1 2 3)))
"1"
```

---

## `cddr`

Returns the last item of the last item of a list.

```lisp
(cddr '('("A" "B" "C") '(3 2 1) "1"))
"1"
```

---

## Sequence Helpers

```lisp
(third '(1 2 3 4 5 6 7 8 9 10))
3
(fourth '(1 2 3 4 5 6 7 8 9 10))
4
(fifth '(1 2 3 4 5 6 7 8 9 10))
5
(sixth '(1 2 3 4 5 6 7 8 9 10))
6
(seventh '(1 2 3 4 5 6 7 8 9 10))
7
(last '(1 2 3 4 5 6 7 8 9 10))
10
```

---

## `to-bool`

Interprets a truthy value, returning a boolean.

```lisp
(to-bool ())
false
(to-bool "false")
true
(to-bool "")
true
(to-bool 0)
true
(to-bool (vector))
true
(to-bool false)
false
```

---

## `implies`

Perform logical implies on the two arguments:

-   If the first argument is truthy, return the boolean value of the second argument
-   If the first argument if false, return true

```lisp
(implies false true)
true
(implies () false)
true
(implies "" false) ;; Note that <""> is truthy
false
(implies true false)
false
(implies true "test")
true
```

---

## `when`

The `when` macro acts as a "one-armed if" expression but also allows multiple consequent expressions which are evaluated as if in a progn.

```lisp
(when true (debug-print "hello"))
"hello"
()
(when false (debug-print "hello"))
()
```

---

## `unless`

The `unless` macro acts as a "one-armed if not" expression but also allows multiple consequent expressions which are evaluated as if in a progn.

```lisp
(unless true (debug-print "hello"))
()
(unless false (debug-print "hello"))
"hello"
()
```

---

## `while`

The `while` macro emulates the C "while" block. If predicate-expression evaluates to true, consequent-expressions are evaluated and then the process repeats. If and when the loop terminates, the predicate-expression will have just evaluated to false. The macro always evaluates to `()`.

```lisp
(let* ([x 10]
             [y  0])
        (while (> x 0)
          (set! x (- x 1))
          (set! y (+ y 1))
          (debug-print y)))
1
2
3
4
5
6
7
8
9
10
()
```

---

## `default`

Returns `x` if truthy, and `d` otherwise.

```lisp
(default () "fallback")
"fallback"
(default "" "fallback")
""
(default 123 "fallback")
123
```

---

## `default-string`

Returns `x` if the string isn't empty (`""`), and `d` otherwise.

```lisp
(default-string "" "fallback")
"fallback"
(default-string "ABC" "fallback")
"ABC"
```

---

## `curry`

Returns a function which will call FUN passing it INITIAL-ARGS and then any other args.

```lisp
(set 'test (sorted-map "A" 1 "B" 2 "C" 3))
(sorted-map "A" 1 "B" 2 "C" 3)
(map 'list (curry get test) (keys test))
'(1 2 3)
```

---

## `vector-if-nil`

Returns a empty vector if `x` is nil, and `x` otherwise.

```lisp
(vector-if-nil "")
""
(vector-if-nil "ABC")
"ABC"
```

---

## `bool-is-substantial`

Returns false for non-boolean values or `x` for booleans.

```lisp
(bool-is-substantial ())
false
(bool-is-substantial "true")
false
(bool-is-substantial true)
true
(bool-is-substantial false)
false
```

---

## `int-is-substantial`

Checks if the value can be interpreted as a int and is non-zero.

```lisp
(int-is-substantial "123")
false
(int-is-substantial ())
false
(int-is-substantial 123)
true
(int-is-substantial 123.0)
true
(int-is-substantial 123.1)
false
(int-is-substantial 0)
false
```

---

## `float-is-substantial`

Checks if the value can be interpreted as a float and is non-zero.

```lisp
(float-is-substantial "2")
false
(float-is-substantial 2)
false
(float-is-substantial 2.2)
true
(float-is-substantial 2.0)
true
(float-is-substantial 0.1)
true
(float-is-substantial 0.0)
false
```

---

## `string-is-substantial`

Checks if the value is a string and isn't empty.

```lisp
(string-is-substantial "")
false
(string-is-substantial "ABC")
true
(string-is-substantial ())
false
```

---

## `nil-if-empty-string`

Returns nil for empty strings, otherwise returns the input string.

```lisp
(nil-if-empty-string "")
()
(nil-if-empty-string "ABC")
"ABC"
```

---

## `num?`

Checks if the value is a number.

```lisp
(num? 0.0)
true
(num? "0")
false
(num? 123)
true
```

---

## `num-is-substantial`

Checks if the value can be interpreted as a number and is non-zero.

```lisp
(num-is-substantial 0)
false
(num-is-substantial 0.0)
false
(num-is-substantial "100")
false
(num-is-substantial 100)
true
(num-is-substantial -0.1)
true
```

---

## `seq?`

Checks if the value is a sequence (list or vector).

```lisp
(seq? ())
true
(seq? "")
false
(seq? (list 1 2 3))
true
(seq? (vector 1 2 4))
true
```

---

## `seq-is-substantial`

Checks if the value is a non-empty sequence.

```lisp
(seq-is-substantial ())
false
(seq-is-substantial '(1 2 3))
true
```

---

## `map-is-substantial`

Checks if the value is a non-empty map.

```lisp
(map-is-substantial 0)
false
(map-is-substantial (sorted-map))
false
(map-is-substantial (sorted-map "A" 1))
true
```

---

## `generic-is-substantial`

Checks the value is non-empty and substantial across types.

```lisp
(generic-is-substantial ())
false
(generic-is-substantial false)
false
(generic-is-substantial true)
true
(generic-is-substantial 1.1)
true
(generic-is-substantial '())
false
(generic-is-substantial '(1))
true
(generic-is-substantial (sorted-map "A" 1))
true
(generic-is-substantial +)
stdin:1: generic-is-substantial: unknown type in generic-is-substantial
```

---

## `widen-number`

Zero pads the number with a width of 20.

```lisp
(widen-number 11111111)
"00000000000011111111"
```

---

## `widen-number-pennies`

Zero pads to penny width.

```lisp
(widen-number-pennies 1)
"01"
(widen-number-pennies 20)
"20"
```

---

## `string-in?`

Checks if the string is in the string sequence.

```lisp
(string-in? "A" '("A" "B" "C"))
true
(string-in? "A" '("B" "C"))
false
```

---

## `strings-in?`

Determines that all strings in seq `s` are in seq `lis`.

```lisp
(strings-in? '("A" "B") '("A" "B" "C"))
true
(strings-in? '("A" "B") '("B" "C"))
false
```

---

## `string-starts-with?`

Checks if the string has the given prefix.

```lisp
(string-starts-with? "ABC" "A")
true
(string-starts-with? "ABC" "B")
false
```

---

## `string-substring`

Gets a string substring.

```lisp
(string-substring "ABC" 0 1)
"A"
(string-substring "ABC" 1 1)
""
(string-substring "ABC" 0 3)
"ABC"
```

---

## `string-is-digits?`

Checks if the string contains only numeric digits.

```lisp
(string-is-digits? "ABC")
false
(string-is-digits? "123")
true
```

---

## `string-is-hexdigits?`

Checks if the string contains only hexadecimal digits.

```lisp
(string-is-hexdigits? "ABC")
true
(string-is-hexdigits? "ABC123")
true
(string-is-hexdigits? "GHI")
false
```

---

## `string-is-guid?`

Checks if the string is a universally unique identifier.

```lisp
(string-is-guid? "ABC")
false
(string-is-guid? "5eb24518-8604-4998-805a-7d7097d02b3b")
true
```

---

## `basic-match`

Checks if the strings match, supports `?` to mach any character.

```lisp
elps> (basic-match "ABC" "AB")
false
elps> (basic-match "ABC" "ABC")
true
elps> (basic-match "ABC" "?B?")
true
```

---

## `count`

Counts the items matched by the predicate function.

```lisp
elps> (count #^(<= % 5) '(1 2 3 4 5 6 7 8 9 10))
5
elps> (count #^(> % 5) '(1 2 3 4 5 6 7 8 9 10))
5
elps> (count #^(> % 10) '(1 2 3 4 5 6 7 8 9 10))
0
```

---

## `seq-with-index`

Returns the sequence values with indexes.

```lisp
elps> (seq-with-index '("A" "B" "C"))
'('("A" 0) '("B" 1) '("C" 2))
```

---

## `foldlpairs`

`foldl` sequence pairs.

```lisp
elps> (foldlpairs (lambda (acc elma elmb) (append! acc (vector elma elmb))) (vector) '(1))
(vector)
elps> (foldlpairs (lambda (acc elma elmb) (append! acc (vector elma elmb))) (vector) '(1 2 3))
(vector (vector 1 2) (vector 2 3))
elps> (foldlpairs (lambda (acc elma elmb) (append! acc (vector elma elmb))) (vector) '(1 2 3 4))
(vector (vector 1 2) (vector 2 3) (vector 3 4))
```

---

## `deduplicate`

Deduplicate a sequence of hashable values.

```lisp
elps> (deduplicate '("A" "B" "C" "D" "C" "B" "A"))
'("A" "B" "C" "D")
```

---

## `deduplicate-list`

Same as `deduplicate`, but only for list sequences.

---

## `deduplicate-vector`

Same as `deduplicate`, but only for vector sequences.

---

## `make-string-set`

Creates a sorted-map with string keys mapping to true values.

```
elps> (make-string-set '("A" "B" "C" "D" "C" "B" "A"))
(sorted-map "A" true "B" true "C" true "D" true)
```

---

## `make-mergemap`

Constructs a new map by taking the union of keys, vals of maps m1 and m2, where m2 value override m1 values where both maps share a common key.

```lisp
elps> (make-mergemap (sorted-map "A" 1) (sorted-map "A" 123 "B" 99))
(sorted-map "A" 123 "B" 99)
```

---

## `make-submap`

Create a sorted-map containing the subset of m's values associated with keys in the sequence, map-keys. Any elements of map-keys that are not keys of m will not be keys of the returned submap either.

```lisp
elps> (make-submap (sorted-map "A" 123 "B" 99) '("A"))
(sorted-map "A" 123)
```

---

## `strings-unique?`

Returns true if all strings in sequence s1 are unique.

```lisp
elps> (strings-unique? '("A" "B"))
true
elps> (strings-unique? '("A" "A"))
false
```

---

## `strings-union`

Performs a union of two string sequences.

```lisp
elps> (strings-union 'list '("A" "B") '("C" "B"))
'("A" "B" "C")
```

---

## `strings-intersect`

Returns unique elements present in both sequences.

```lisp
elps> (strings-intersect 'list '("A" "B") '("C" "B"))
'("B")
```

---

## `strings-intersect-seqs`

Returns unique elements present in both sequences.

```lisp
elps> (strings-intersect 'list '("A" "B") '("C" "B"))
'("B")
```

---

## `strings-subtract`

Returns unique elements of sequence minuend which are not present in sequence subtrahend.

```lisp
elps> (strings-subtract 'list '("A" "B" "C") '("A" "B"))
'("C")
```

---

## `strings-xor`

Returns unique strings that are in seqa or seqb, but are not in both.

```lisp
elps> (strings-xor 'list '("A" "B" "C") '("A" "B"))
'("C")
```

---

## `strings-equal?`

Returns true if the unique strings in seqa are exactly same in seqb.

```lisp
elps> (strings-equal? '("A" "B" "C") '("A" "B"))
false
elps> (strings-equal? '("A" "B" "C") '("C" "A" "B"))
true
```

---

## `clear-map!`

Clears map values, mutating the input map.

```lisp
elps> (set 'test (sorted-map "A" 1))
(sorted-map "A" 1)
elps> (clear-map! test)
(sorted-map)
elps> test
(sorted-map)
```

---

## `deep-equal?`

Works closer to the way that `equal?` is supposed to for structured data.

```lisp
elps> (deep-equal? true true)
true
elps> (deep-equal? (sorted-map "B" 1 "A" 1) (sorted-map "A" 1 "B" 1))
true
elps> (deep-equal? true "HELLO")
false
```

---

## `denil`

Filters out nil values from a sequence.

```lisp
elps> (denil 'list '(1 2 3))
'(1 2 3)
elps> (denil 'list '(1 2 3 ()))
'(1 2 3)
```

---

## `human-join-strings`

Joins a list of strings with commas, and adds an "and" before the last element. It uses oxford comma style.

```lisp
elps> (human-join-strings '("This" "that" "other"))
"This, that, and other"
```

---

## `triml`

Remove leading spaces from a string.

**Deprecated:** use `(string:trim-left str " ")`, which is the same.

```lisp
elps> (triml " Hello World ")
"Hello World "
```

---

## `trimr`

Remove trailing spaces from a string.

**Deprecated:** use `(string:trim-right str " ")`, which is the same.

```lisp
elps> (trimr " Hello World ")
" Hello World"
```

---

## `trim`

Removes leading and trailing spaces from a string.

**Deprecated:** use `(string:trim str " ")`, which is the same. `string:trim-space` also removes tabs and newlines.

```lisp
elps> (trim " Hello World ")
"Hello World"
```

---

## `human-full-name`

Tries to construct a single full name string based on optional name fields.

```lisp
elps> (human-full-name "Charles " "   Robert" "   Darwin  ")
"Charles Robert Darwin"
```

---

## `encode-map-storage-key`

Encode a map to be used as part of a storage key delimited by ":". The encoding doesn't use ":" so that two maps may be used side-by-side in a storage key without ambiguity.

```lisp
shiro> (encode-map-storage-key (sorted-map "testkey" "testval" "fnord" "eris"))
"fnord=eris/testkey=testval"
```

---

## `map-with-index`

Map a function on a sequence, where the first argument to the function is `i` and the second argument to the function is the `i`\-th element. Returns a list.

```lisp
elps> (trim " Hello World ")
"Hello World"
```

---

## `strings-intersect-seqs`

Performs intersection across a sequence of string sequences.

```lisp
shiro> (strings-intersect-seqs 'list (list (list "1" "2" "3") (list "2" "3") (list "2")))
'("2")
```

---

## `find-pos`

find-pos iterates across seq and returns the last position that fn returned true.

If no element is found, 0 is returned, which requires special handling when the element found is the first element.

```lisp
shiro> (find-pos '(1 2 3 2) #^(equal? % 2))
3
shiro> (find-pos '(1 2 3 2) #^(equal? % 4))
0
```

---

## `decimal-money-add`

Add 2 decimal strings, and return a decimal string. DEPRECATED: Please use `libdecimal` instead of these decimal-money functions.

```lisp
shiro> (decimal-money-add "0.11" "1.99")
"2.10"
```

---

## `memoize`

An optimization technique by storing the results of expensive function calls and returning the cached result when the same inputs occur again.

```lisp
shiro> (let* ([t (lambda (x) (+ x 1))]
              [m (memoize-wrap t)])
         (m 1) ; system caches result.
         (m 2)
         (m 1)) ; system returns cached result.
2
```

---

## `now`

Returns current UTC time.

```lisp
shiro> now
"2020-11-25T19:26:38Z"
```

---

## `now-unix`

Returns current time as hexidecimal of the unix epoch time in seconds.

```lisp
shiro> now-unix
"5FBEB281"
```

---

## `cdar`

Returns everything but the first item of the first list, of the outer list.

```lisp
shiro> (cdar '('("A" "B" "C") '(1 2 3)))
'("B" "C")
```

---

## `widen-number-range`

Returns number range.

```lisp
shiro> widen-number-range
20
```

---

## `widen-number-pennies-range`

Returns pennies range.

```lisp
shiro> widen-number-pennies-range
2
```

---

## `widen-number-pennies-prefix`

Returns pennies prefix.

```lisp
shiro> widen-number-pennies-prefix
'("00" "0" "")
```

---

## `String-trailer`

Returns corpus without its first `(length prefix)` characters. It does **not** check that corpus starts with prefix: `(string-trailer "abcdef" "xy")` returns `"cdef"`.

**Deprecated:** use `string:trim-prefix` (substrate with elps v1.69.0 or later), which removes prefix only when corpus starts with it.

```lisp
shiro> (string-trailer "qwerty" "qwe")
"rty"
```

---

## `now-epoch`

Return current unix epoch time in seconds.

```lisp
shiro> (now-epoch)
1606333057
```

---

## `concat!`

Mutates the first vector to include the second vector as the last elements.

```lisp
shiro> (let* ([v1 (vector 1 2 3)]
              [v2 (vector 5 6 7)])
         (concat! v1 v2)
         v1)
(vector 1 2 3 5 6 7)
```

---

## `get-tx-metadata`

Get metadata (transaction metadata is stored in the state database under the transaction ID) with string key from the transaction context.

```lisp
shiro> (cc:set-tx-metadata "test-key" "test-value")
()
shiro> (cc:get-tx-metadata "test-key")
"test-value"
```

---

## `entity-metadata`

Returns a specified entry in the metadata field of an entity.

```lisp
shiro> (let* ([entity (sorted-map "metadata" (vector (sorted-map "name" "test"
                                                                 "bool_value" true)))])
         (entity-metadata entity "test"))
(sorted-map "bool_value" true "name" "test")
```

---

## `get-metadata-str`

Returns the string value for a specific entry in the metadata field of an entity.

```lisp
shiro> (let* ([entity (sorted-map "metadata" (vector (sorted-map "name" "test"
                                                                 "string_value" "data")))])
         (get-metadata-str entity "test"))
"data"
```

---

## `get-metadata-int`

Returns the integer value for a specific entry in the metadata field of an entity.

```lisp
shiro> (let* ([entity (sorted-map "metadata" (vector (sorted-map "name" "test"
                                                                 "int_value" 250)))])
         (get-metadata-int entity "test"))
250
```

---

## `assert-deep-equal`

Ensures the 2 arguments are deeply equal. Used in testing.

```lisp
shiro> (assert-deep-equal (sorted-map "1" 2) (sorted-map "1" 2))
()
shiro> (assert-deep-equal (sorted-map "1" 2) (sorted-map "1" 1))
<native code>: lisp:assert: the values are not ``deep-equal?''
        expression: (sorted-map "1" 1)
            result: (sorted-map "1" 1)
          expected: (sorted-map "1" 2)
Stack Trace [2 frames -- entrypoint last]:
  height 1: <native code>: lisp:assert
  height 0: <native code>: lisp:let* [terminal]
```

---

## `asset-not-deep-equal`

Ensures the 2 arguments are NOT deeply equal. Used in testing.

```lisp
shiro> (assert-not-deep-equal (sorted-map "1" 2) (sorted-map "1" 1))
()
shiro> (assert-not-deep-equal (sorted-map "1" 2) (sorted-map "1" 2))
<native code>: lisp:assert: the values are ``deep-equal?''
        expression: (sorted-map "1" 2)
            result: (sorted-map "1" 2)
Stack Trace [2 frames -- entrypoint last]:
  height 1: <native code>: lisp:assert
  height 0: <native code>: lisp:let* [terminal]
```

---

## `assert-condition`

Expects an exception or error to be returned and handles accordingly.

```lisp
shiro> (assert-condition set-exception-error (validate-nonempty-string (sorted-map "test" 123) "test"))
INFO[305120] generating exception                          description="test must be a non-empty string" id=shirotester-1 op=TestUtils req_time="2020-11-18T21:52:56Z" test-key-1=test-value-1 test-key-2=test-value-2 test-key-3=test-value-3 type=BUSINESS
()
shiro> (assert-condition set-exception-error (validate-nonempty-string (sorted-map "test" "123") "test"))
()
```

---

## `timestamp-to-date`

Converts a timestamp to a date.

```lisp
shiro>  (timestamp-to-date (cc:timestamp (cc:now)))
"2020-11-18"
```

---

## `date-now`

Returns today's date.

```lisp
shiro> (date-now)
"2020-11-18"
```

---

## `ymd-between-dates`

Returns the number of years, months, and days in between 2 dates as a vector.

```lisp
shiro> (ymd-between-dates "1997-08-05" "2020-11-18")
(vector 23 3 13)
```

---

## `ymd-extract`

Extracts the year, month, and date and returns that as a vector.

```lisp
shiro> (ymd-extract "1997-08-05")
(vector 1997 8 5)
```

---

## `decimal-money-from-int`

Returns the integer input in money format.

```lisp
shiro> (decimal-money-from-int 250)
"250.00"
```

---

## `decimal-money-from-vector`

Takes a vector of the dollar amount and cent amount as input and returns in money format.

```lisp
shiro> (decimal-money-from-vector (vector 250 25))
"250.25"
```

---

## `decimal-money-to-vector`

Takes a money amount as input and returns a vector of the dollar amount and the cent amount.

```lisp
shiro> (decimal-money-to-vector "250.25")
(vector 250 25)
```

---

## `decimal-money-cmp`

Whether the first money amount is larger than the second.

```lisp
shiro> (decimal-money-cmp "100.49" "100.50")
-1
shiro> (decimal-money-cmp "100.49" "100.49")
0
shiro> (decimal-money-cmp "100.49" "100.48")
1
```

---
