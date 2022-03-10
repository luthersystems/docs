# Copy of Phylum Best Practices

### Syle Guidelines

Inspired by [Clojure Style Guidelines](https://github.com/bbatsov/clojure-style-guide#lisp-case):

#### Tabs vs Spaces

Use spaces for indentation. No hard tabs.

#### Line endings

Use Unix-style line endings.

#### Lisp Case

Use lisp-case for function and variable names.

#### Pred With Question Mark

The names of predicate methods (methods that return a boolean value) should end in a question mark (e.g., even?).

#### Mutating Fns With Exclamation Mark

The names of functions/macros that mutate the arguments or possibly state external to the function should end with an exclamation mark (e.g. reset!).

#### Underscore For Unused Bindings

Use \_ for destructuring targets and formal argument names whose value will be ignored by the code at hand.

#### Comment Upkeep

Keep existing comments up-to-date. An outdated comment is worse than no comment at all.

#### Comment Convention

See (Lisp Comment Tips)\[[https://www.gnu.org/software/emacs/manual/html\_node/elisp/Comment-Tips.html#Comment-Tips](https://www.gnu.org/software/emacs/manual/html\_node/elisp/Comment-Tips.html#Comment-Tips)] for detailed comment conventions.

From that article:

* Comments that start with a single semicolon, ‘;’, should all be aligned to the same column on the right of the source code. Such comments usually explain how the code on that line does its job. For example:
* Comments that start with two semicolons, ‘;;’, should be aligned to the same level of indentation as the code. Such comments usually describe the purpose of the following lines or the state of the program at that point.
* Comments that start with three semicolons, ‘;;;’, should start at the left margin. We use them for comments which should be considered a heading. By default, comments starting with at least three semicolons (followed by a single space and a non-whitespace character) are considered headings, comments starting with two or fewer are not. Historically, triple-semicolon comments have also been used for commenting out lines within a function, but this use is discouraged. When commenting out entire functions, use two semicolons.

#### Comment Labels

* NOTE: Use NOTE to indicate a more detailed or subtle description of a function or design decision.
* IMPORTANT: Use _IMPORTANT_ to call out critical non-obvious implementation details.
* BUG: Use BUG to indicate a known bug that is currently being worked around.
* TODO: Use TODO to note missing features or functionality that should be added at a later date.
* FIXME: Use FIXME to note broken code that needs to be fixed.
* OPTIMIZE: Use OPTIMIZE to note slow or inefficient code that may cause performance problems.
* HACK: Use HACK to note "code smells" where questionable coding practices were used and should be refactored away.
* REVIEW: Use REVIEW to note anything that should be looked at to confirm it is working as intended. For example: REVIEW: Are we sure this is how the client does X currently?

#### Running Unit Tests

Run `make test` to run all the unit tests defined in `*_test.lisp` files.

To run all the tests in one or more test files, run:

```
$(make echo:SHIRO_TEST) migrations_test.lisp [...]
```

To run specific tests with a regex, use `--run` which has 'go test -run' semantics \[1]. E.g.,

```
phylum❯ $(make echo:SHIRO_TEST) --run "/regulating"
=== RUN   TestFile_app
=== RUN   TestFile_app/$load
--- PASS: TestFile_app (1.75s)
    --- PASS: TestFile_app/$load (1.75s)
=== RUN   TestFile_assertions
=== RUN   TestFile_assertions/$load
--- PASS: TestFile_assertions (0.34s)
    --- PASS: TestFile_assertions/$load (0.34s)
=== RUN   TestFile_document
=== RUN   TestFile_document/$load
--- PASS: TestFile_document (0.37s)
    --- PASS: TestFile_document/$load (0.36s)
=== RUN   TestFile_mortgage
=== RUN   TestFile_mortgage/$load
--- PASS: TestFile_mortgage (0.32s)
    --- PASS: TestFile_mortgage/$load (0.32s)
=== RUN   TestFile_permission_utils
=== RUN   TestFile_permission_utils/$load
=== RUN   TestFile_permission_utils/perm-required-over-regulating-org?
--- PASS: TestFile_permission_utils (0.70s)
    --- PASS: TestFile_permission_utils/$load (0.35s)
    --- PASS: TestFile_permission_utils/perm-required-over-regulating-org? (0.35s)
=== RUN   TestFile_utils
=== RUN   TestFile_utils/$load
--- PASS: TestFile_utils (0.34s)
    --- PASS: TestFile_utils/$load (0.34s)
```

\[1] [https://golang.org/pkg/testing/#hdr-Subtests\_and\_Sub\_benchmarks](https://golang.org/pkg/testing/#hdr-Subtests\_and\_Sub\_benchmarks)
