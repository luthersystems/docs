---
description: >-
  This guide starts from the sandbox and walks you through adding a new field to
  the account model. This covers adding integration tests as well as storing
  data on the network.
---

# Update Your Data Model

## **Update The Account Model**

1.  Bring up the Oracle and the Phylum using the "in-memory" mode network:

    ```bash
    $ make mem-up
    ```
2.  Update the `martin` test to pass in the new `name` field on creation of the second account:

    ```diff
    diff --git a/tests/example/account.martin_collection.yaml b/tests/example/account.martin_collection.yaml
    index 2a4e686..69515ac 100644
    --- a/tests/example/account.martin_collection.yaml
    +++ b/tests/example/account.martin_collection.yaml
    @@ -25,6 +25,7 @@ tests:
           path: "v1/accounts/{{ACCT2}}"
           body: |
               {
    +            "name": "Martin",
                 "current_balance": 100
               }
           setup_script: |
    ```
3.  Run the `martin` tests to confirm that the API returns a **400** status code for the unknown

    field.

    ```
    $ make tests-martin
    ❏ Sandbox Example:  Managing Account Balances
    ↳ Create Account 1
      POST http://sandbox_oracle:8080/v1/accounts/abc-7ebd3108-ce4c-4667-abc9-9f69c5d4c3ad [400 Bad Request, 400B, 6ms]
      ┌
      │ 'X-Request-ID: 938c1a87-7a4f-4c28-971a-e85e7aed5822'
      │ { exception:
      │    { type: 'BUSINESS',
      │      timestamp: '2021-07-15T20:45:45Z',
      │      description: 'unknown field "name" in cdm.Account
      │ ' } }
      └
      1. ok
      2⠄ AssertionFailure in test-script
    ```
4.  Let's add a new string field `name` to the Account model.\
    \
    These models are defined using Google's [protobuf](https://developers.google.com/protocol-buffers) spec. The entire stack from the API layer to the business logic re-use these models.\
    \
    Edit the `Account` message in `api/pb/oracle.proto` to include the new field:

    ```diff
    diff --git a/api/pb/oracle.proto b/api/pb/oracle.proto
    index 84bd583..c0862d0 100644
    --- a/api/pb/oracle.proto
    +++ b/api/pb/oracle.proto
    @@ -73,4 +73,5 @@ message TransferResponse {
     message Account {
       string account_id = 1;
       int64 current_balance = 2;
    +  string name = 3;
     }
    ```
5.  Run `make api` to generate the Go models used by the oracle:

    ```bash
    $ make api
    ```

    > _**NOTE**_: The Go structs defined in `api/pb/oracle.pb.go` are updated to include `Name`.
6.  Rebuild the Oracle to pickup the new changes, and run the tests again:

    ```bash
    $ make mem-down mem-up
    $ make tests-martin
    Output:
    ┌─────────────────────────┬───────────────────┬───────────────────┐
    │                         │          executed │            failed │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │              iterations │                 1 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │                requests │                 5 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │            test-scripts │                10 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │      prerequest-scripts │                 2 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │              assertions │                 5 │                 0 │
    ├─────────────────────────┴───────────────────┴───────────────────┤
    │ total run duration: 500ms                                       │
    ├─────────────────────────────────────────────────────────────────┤
    │ total data received: 364B (approx)                              │
    ├─────────────────────────────────────────────────────────────────┤
    │ average response time: 48ms [min: 24ms, max: 143ms, s.d.: 47ms] │
    └─────────────────────────────────────────────────────────────────┘
    ```
7.  Update the `martin` test to now check that the `Name` is returned when querying for an account:\


    > _NOTE_: `martin` uses the [postman](https://learning.postman.com) tool to run end-to-end tests. See the above link for documentation on how to write scripts with `postman`.

    ```diff
    diff --git a/tests/example/account.martin_collection.yaml b/tests/example/account.martin_collection.yaml
    index 2a4e686..3e1fc26 100644
    @@ -66,4 +67,6 @@ tests:
                   pm.expect(data.account.account_id).to.equal(pm.environment.get("ACCT2"));
                   // int64 protobuf fields come out as strings in javascript
                   pm.expect(data.account.current_balance).to.equal('120');
    +              pm.expect(data.account.name).to.equal("Martin");
               });
    ```
8.  Confirm the new test fails:

    ```bash
    $ make tests-martin
    Output:
      #  failure           detail

     1.  AssertionError    ok
                           expected {} to have property 'account'
                           at assertion:0 in test-script
                           inside "Sandbox Example:  Managing Account Balances / Transfer"

     2.  AssertionFailure
                           ok
                           at test-script:38:17
                           inside "Sandbox Example:  Managing Account Balances / Transfer"

    ```
9.  Update the business logic in the phylum to store and the optional account name. First update the`routes.lisp` file to include the new field in the `create-account!` call:

    ```
    +++ b/phylum/routes.lisp
    @@ -66,7 +66,7 @@
     ; initialize entities a and b to integer values
     (defendpoint "create_account" (create)
       (let* ([acct (get create "account")])
    -    (if (create-account! (get acct "account_id") (to-int (get acct "current_balance")))
    +    (if (create-account! (get acct "account_id") (to-int (get acct "current_balance")) (get acct "name"))
           (route-success ())
           (set-exception-business "account_id already exists"))))

    ```
10. Add helper functions to persist and retrieve the `name` field:

    ```
    diff --git a/phylum/utils.lisp b/phylum/utils.lisp
    index 5bed85c..a11ac30 100644
    --- a/phylum/utils.lisp
    +++ b/phylum/utils.lisp
    @@ -9,13 +9,23 @@
     ;; This block defines helper functions for account objects in the data model.
     ;; The helper functions have their own internal, private helpers which are
     ;; defined by labels.
    -(labels ([make-account (acct-id balance)
    +(labels ([make-account (acct-id balance &optional name)
               (sorted-map "account_id" acct-id
    +                      "name" name
                           "current_balance" (to-int balance))]
    +         [put-account-name! (acct-id name)
    +          (statedb:put (format-string "{}.name" acct-id) name)
    +          true]
    +         [get-account-name (acct-id)
    +          (statedb:get (format-string "{}.name" acct-id))]
              [get-balance (acct-id)
               (cc:infof (sorted-map "account_id" acct-id) "GET")
               (let* ([balance (statedb:get acct-id)])
                 (if (nil? balance) '() (to-int balance)))]
              [put-account! (acct-id balance)
               (cc:infof (sorted-map "account_id" acct-id "balance" balance) "PUT")
    ```

    > _**NOTE**_: The `statedb:put` function saves a value for a given key into the common ledger. All of the network participants have access to this state, and the updates are available across transactions. \
    > \
    > Here we use the `format-string` built-in to construct a unique key that we use to store the account name for a particular account ID.
11. Use the helper functions to check name at account creation and retrieval:

    ```
    diff --git a/phylum/utils.lisp b/phylum/utils.lisp
    index 5bed85c..a11ac30 100644
    --- a/phylum/utils.lisp
    +++ b/phylum/utils.lisp
    @@ -24,20 +34,21 @@
         ;; create-account! creates a new account record in statedb and records an
         ;; account object.  If the given acct-id already exists in statedb
         ;; create-account! does nothing and returns nil.
    -        (defun create-account! (acct-id balance)
    +        (defun create-account! (acct-id balance &optional name)
           (account-do acct-id
                   (lambda (found? _)
                 (and (not found?)
                      (>= (trace balance "balance") 0)
                      (put-account! acct-id balance)
    -                             (make-account acct-id balance)))))
    +                             (put-account-name! acct-id name)
    +                             (make-account acct-id balance name)))))

         ;; get-account retrieves an account record from statedb.  If the given
         ;; account does not exist a nil value is returned.
         (defun get-account (acct-id)
           (account-do acct-id
                   (lambda (found? balance)
    -                        (if found? (make-account acct-id balance) '()))))
    +                        (if found? (make-account acct-id balance (get-account-name acct-id)) '()))))
    ```
12. Run your unit tests to confirm the tests still pass

    ```
    $ make test
    Output:
    --- PASS: TestFile_utils (0.05s)
        --- PASS: TestFile_utils/$load (0.02s)
        --- PASS: TestFile_utils/account-functions (0.03s)
    PASS
    ```
13. Run your integration tests again to confirm that it now passes:

    ```
    $ make integration
    Output:
    ┌─────────────────────────┬───────────────────┬───────────────────┐
    │                         │          executed │            failed │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │              iterations │                 1 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │                requests │                 5 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │            test-scripts │                10 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │      prerequest-scripts │                 2 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │              assertions │                 5 │                 0 │
    ├─────────────────────────┴───────────────────┴───────────────────┤
    │ total run duration: 537ms                                       │
    ├─────────────────────────────────────────────────────────────────┤
    │ total data received: 380B (approx)                              │
    ├─────────────────────────────────────────────────────────────────┤
    │ average response time: 57ms [min: 17ms, max: 201ms, s.d.: 71ms] │
    └─────────────────────────────────────────────────────────────────┘

    ```

    > _**NOTE**_**:**  The phylum changes are automatically picked up by the Oracle running in-memory mode (live reload).

    🎉 Congrats! You have added your first field.\


