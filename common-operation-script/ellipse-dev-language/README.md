---
description: Smart Contract language for business applications.
---

# Dev Language

An embedded lisp system for Go programs.
Open source on github: [https://github.com/luthersystems/elps](https://github.com/luthersystems/elps)

---

## Try it out

```lisp
(+ 2 1)
```

An example WASM build is available on [github pages](https://luthersystems.github.io/elps/) ([source](https://github.com/luthersystems/elps/tree/main/_examples/wasm)).

---

## Build

```sh
go mod download
make
```

---

## Usage

Launch an interactive REPL

```sh
$ elps repl
> (+ 3 1)
4
>^D
done
$
```

Run a program in a file

```sh
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

---

## Reference

-   [SICP Examples](https://github.com/luthersystems/elps/tree/main/_examples/sicp)
