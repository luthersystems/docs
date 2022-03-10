---
description: Smart Contract language for business applications.
---

# Copy of Ellipse: Dev Language

An embedded lisp system for Go programs.

****[https://github.com/luthersystems/elps](https://github.com/luthersystems/elps) ![CircleCI](https://circleci.com/gh/luthersystems/elps.svg?style=svg)

## Try it out

{% embed url="https://codepen.io/sam-at-luther/full/bGeJqKp" %}
Ellipse Playground: Interactive REPL (Read, Eval, Print, Loop)
{% endembed %}

An example WASM build is available on [github pages](https://luthersystems.github.io/elps/) ([source](https://github.com/luthersystems/elps/tree/master/\_examples/wasm)).

## Build

```
go get -d ./...
make
```

## Usage

Launch an interactive REPL

```
$ elps repl
> (+ 3 1)
4
>^D
done
$
```

Run a program in a file

```
$ elps run prog.lisp
```

Embedded execution in a Go program

```go
env := lisp.NewEnv(nil)
env.Reader = parser.NewReader()
lerr := lisp.InitializeUserEnv(env)
if !lerr.IsNil() {
   log.Panicf("initialization error: %v", lerr)
}
lerr = lisplib.LoadLibrary(env)
if !lerr.IsNil() {
    log.Panicf("stdlib error: %v", lerr)
}
env.LoadString(`(debug-print "hello-world")`)
```

## Reference

* [SICP Examples](https://github.com/luthersystems/elps/tree/master/\_examples/sicp)
