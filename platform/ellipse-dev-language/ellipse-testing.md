# Ellipse Testing

## Overview

ELPS provides support for automated testing with package `testing`. It has facilities to define tests, run them and report the results. Tests are simply elps code.

## Defining tests

The core of the testing package is the `test` macro that allows you define a test. It takes as first argument a string that describes what functionality it tests. The body can be arbitrary elps code.

A simple test looks like this:

```
(test "sum"
    (assert-equal 3 (sum 1 2))
    (assert-equal 0 (sum 1 -1)))
```

To write a new test suite, you should create a file whose name ends with `_test.lisp`.

## Assertions

The example above uses the macro `assert-equal` to assert the result of the test. Assertions allow you to easily write test code. The `testing` package provides the following macros for assertion:

* `assert=`

Asserts that the specified numbers are equal.

```
(assert= 42 42) => true
```

* `assert-string=`

Asserts that the specified strings are lexicographically equal.

```
(assert-string= "foo" "foo") => true
```

* `assert-equal`

Asserts that the specified objects are equal.

```
(assert-equal 42 42) => true
(assert-equal "42" "42") => true
(assert-equal (list '42) (list '42)) => true
```

* `assert-nil`

Asserts that the specified object is `nil`.

```
(assert-nil '()) => true
```

* `assert-not-nil`

Asserts that the specified object is non-nil.

```
(assert-not-nil (list '())) => true
```

* `assert-not`

Asserts that the argument is `false`

```
(assert-not (equal? "foo" "bar"))) => true
```

## Running tests

There are two ways to run tests depending on whether you are using the ELPS standard library only or functions available in libraries provided by Luther's `substrate` platform.

* Elpstest Runner (Golang)

A simple test function using the runner looks like this:

```
func TestPackage(t *testing.T) {
    r := &elpstest.Runner{}
    r.RunTestFile(t, "package_test.lisp")
}
```

This is intended to be used with the `go test` command, and does not depend on `substrate`.

* Shirotester

This is a tool provided as a docker image that you can run locally to execute elps test files in the current directory.

```
docker run -v ${PWD}:/tmp -w /tmp 967058059066.dkr.ecr.eu-west-2.amazonaws.com/luthersystems/shirotester unit-tests .
```

Note this requires a `main.lisp` in the same directory as the test and must be in the same package.

It initialises the test environment with `substrate` functions.
