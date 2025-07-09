---
description: This guide walks you through updating the sandbox to include unit tests.
---

# Copy of Write Your First Unit Test

## **Fix an existing unit test**

The example business logic allows account balances to go negative. Let's enhance this logic by adding a constraint that account balances can never go negative.

1.  Let's start from the `phylum` directory:

    ```bash
    $ cd phylum
    ```
2.  Run the `account-functions` test that demonstrates a negative account balance of `-25`.

    ```bash
    $ make test

    # Output:
    ...
        --- PASS: TestFile_utils/account-functions (0.04s)
    ```
3.  Update the test to ensure that the account balance is never negative:

    ```diff
    diff --git a/phylum/utils_test.lisp b/phylum/utils_test.lisp
    index f859e17..f789dbe 100644
    --- a/phylum/utils_test.lisp
    +++ b/phylum/utils_test.lisp
    @@ -13,7 +13,6 @@
         (assert-equal 50 (get (create-account! person1 50) "current_balance"))
         (assert-equal 100 (get (get-account person0) "current_balance"))
         (assert (account-transfer! person0 person1 25))
    -    (assert (account-transfer! person1 person0 100))
    -    (assert (account-do person0 account-found?))
    -    (assert-equal -25 (account-do person1 get-balance))
    -    (assert-equal 175 (account-do person0 get-balance))))
    +    (assert-not (account-transfer! person1 person0 100))
    +    (assert-equal 75 (get (get-account person0) "current_balance"))
    +    (assert-equal 75 (get (get-account person1) "current_balance"))))
    ```
4.  The test now fails because the transfer still succeeds:

    ```bash
    $ make test

    # Output:
    ...
     lisptest.go:252: utils_test.lisp:7: lisp:assert: the expressions is not falsey
    ```
5.  Let's add a rule to prohibit negative account balances:

    ```diff
    diff --git a/phylum/utils.lisp b/phylum/utils.lisp
    index 531ce1a..9f92528 100644
    --- a/phylum/utils.lisp
    +++ b/phylum/utils.lisp
    @@ -47,7 +47,6 @@
                                  (put-account! acct-id balance)))))
     
             ;; account-transfer! moves amount units between two accounts.
    -        ;; account-transfer! will allow account balances to go negative.
             (defun account-transfer! (from-id to-id amount)
               (account-do from-id
                           (lambda (from-found? from-bal)
    @@ -55,6 +54,7 @@
                                  (account-do to-id
                                              (lambda (to-found? to-bal)
                                                (and to-found?
    +                                                (>= (- from-bal amount) 0)
                                                     (put-account! from-id (- from-bal amount))
                                                     (put-account! to-id (+ to-bal amount)))))))))
    ```
6.  And re-run the test to confirm the test now passes:

    ```bash
    $ make test

    # Output:
    ...
    --- PASS: TestFile_utils (0.06s)
        --- PASS: TestFile_utils/$load (0.03s)
        --- PASS: TestFile_utils/account-functions (0.03s)
    PASS
    ```
7. 🎉Congratulations! You fixed your first bug.

## **Add a new unit test**

1. Let's add a new `elps` unit test to avoid creation of accounts with negative balances:
   1. ```bash
      diff --git a/phylum/utils_test.lisp b/phylum/utils_test.lisp
      index f789dbe..0db4c79 100644
      --- a/phylum/utils_test.lisp
      +++ b/phylum/utils_test.lisp
      @@ -16,3 +16,7 @@
           (assert-not (account-transfer! person1 person0 100))
           (assert-equal 75 (get (get-account person0) "current_balance"))
           (assert-equal 75 (get (get-account person1) "current_balance"))))
      +
      +(test "no-negative-accounts"
      +  (let ([person0 "person0"])
      +    (assert-not (create-account! person0 -100))))
      ```
2.  Run the new unit test to confirm that it fails:

    ```bash
    $ make test

    # Output:
    ...
        lisptest.go:252: utils_test.lisp:21: lisp:assert: the expressions is not falsey
                    expression: (create-account! "person0" -1)
                        result: (sorted-map "account_id" "person0" "current_balance" -1)
    ```
3.  Let's now add a check to prevent creating negative accounts:\


    ```diff
    diff --git a/phylum/utils.lisp b/phylum/utils.lisp
    index 531ce1a..610dede 100644
    --- a/phylum/utils.lisp
    +++ b/phylum/utils.lisp
    @@ -27,7 +27,8 @@
             (defun create-account! (acct-id balance)
               (account-do acct-id
                           (lambda (found? _)
                             (and (not found?)
    +                             (>= balance 0)
                                  (put-account! acct-id balance)
                                  (make-account acct-id balance)))))
    ```
4.  Run the tests now to see if they pass:

    ```bash
    $ make test

    # Output
    ...
    --- PASS: TestFile_utils (0.09s)
        --- PASS: TestFile_utils/$load (0.03s)
        --- PASS: TestFile_utils/account-functions (0.03s)
        --- PASS: TestFile_utils/no-negative-accounts (0.02s)
    PASS
    ```
5.  You can run an individual test as follows, where `--run` takes Go-style pattern matches to run tests (see `go test`).

    ```bash
    $ $(make echo:SHIRO_TEST) --run "/no-negative-accounts"
    # Output:
    ...
    --- PASS: TestFile_utils (0.06s)
        --- PASS: TestFile_utils/$load (0.03s)
        --- PASS: TestFile_utils/no-negative-accounts (0.02s)
    ```

_NOTE:_  the `account-functions` test are skipped.

_NOTE_: The `$load` test automatically runs on every run.
