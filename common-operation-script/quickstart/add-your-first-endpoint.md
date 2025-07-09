---
description: >-
  This guide starts from the sandbox and walks you through adding a new endpoint
  to the REST/JSON API served by the Oracle. This covers adding functional tests
  in Go and editing the phylum.
---

# Copy of Add Your First Endpoint

## **Update the API Specification and the Oracle**

1.  Let's add a new endpoint to delete accounts.\
    Edit `api/srvpb/oracle.proto` to include the new endpoint:

    ```diff
    diff --git a/api/srvpb/oracle.proto b/api/srvpb/oracle.proto
    index de9fa94..13b5008 100644
    --- a/api/srvpb/oracle.proto
    +++ b/api/srvpb/oracle.proto
    @@ -152,4 +152,12 @@ service SandboxProcessor {
           tags: "Service"
         };
       }
    +  rpc DeleteAccount(cdm.DeleteAccountRequest) returns (cdm.DeleteAccountResponse) {
    +    option (google.api.http) = {
    +      delete: "/v1/accounts/{account_id}"
    +    };
    +    option (grpc.gateway.protoc_gen_swagger.options.openapiv2_operation) = {
    +      tags: "Service"
    +    };
    +  }
     }
    ```

    > _NOTE_: The middleware uses the [grpc-gateway](https://github.com/grpc-ecosystem/grpc-gateway) project to serve the REST/JSON API.
2.  Add the new models for the request and response messages:

    ```diff
    diff --git a/api/pb/oracle.proto b/api/pb/oracle.proto
    index 84bd583..b83c288 100644
    --- a/api/pb/oracle.proto
    +++ b/api/pb/oracle.proto
    @@ -74,3 +74,12 @@ message Account {
       string account_id = 1;
       int64 current_balance = 2;
     }
    +
    +message DeleteAccountRequest {
    +  string account_id = 1;
    +}
    +
    +message DeleteAccountResponse {
    +  common.Exception exception = 1;
    +}
    +

    ```
3.  Edit `phylum/phylum.go` to expose the new endpoint in the phylum SDK that is used by the oracle:

    ```diff
    diff --git a/phylum/phylum.go b/phylum/phylum.go
    index df6c0d3..ce9d03c 100644
    --- a/phylum/phylum.go
    +++ b/phylum/phylum.go
    @@ -53,6 +53,9 @@ var (
            phylumTransfer = &phylumMethod{
                    method: "transfer",
            }
    +       phylumDeleteAccount = &phylumMethod{
    +               method: "delete_account",
    +       }
     )

     func joinConfig(base []func() (Config, error), add []Config) (conf []Config, err error) {
    @@ -305,3 +308,12 @@ func (s *Client) Transfer(ctx context.Context, req *pb.TransferRequest, config .
            }
            return resp, nil
     }
    +
    +func (s *Client) DeleteAccount(ctx context.Context, req *pb.DeleteAccountRequest, config ...Config) (*pb.DeleteAccountResponse, error) {
    +       resp := &pb.DeleteAccountResponse{}
    +       err := s.callMethod(ctx, phylumDeleteAccount, cmdParams(req), resp, config)
    +       if err != nil {
    +               return nil, err
    +       }
    +       return resp, nil
    +}
    ```


4.  Edit the Oracle to call the new delete function:

    ```diff
    diff --git a/oracleserv/sandbox-oracle/oracle/oracle.go b/oracleserv/sandbox-oracle/oracle/oracle.go
    index 6fe6baf..88feba7 100644
    --- a/oracleserv/sandbox-oracle/oracle/oracle.go
    +++ b/oracleserv/sandbox-oracle/oracle/oracle.go
    @@ -285,3 +285,8 @@ func (orc *Oracle) Transfer(ctx context.Context, in *pb.TransferRequest) (*pb.Tr
     func (orc *Oracle) Close() error {
            return orc.phylum.Close()
     }
    +
    +func (orc *Oracle) DeleteAccount(ctx context.Context, in *pb.DeleteAccountRequest) (*pb.DeleteAccountResponse, error) {
    +       sopts := orc.txConfigs(ctx)
    +       return orc.phylum.DeleteAccount(ctx, in, sopts...)
    +}
    ```


5.  Edit `oracleserv/sandbox-oracle/oracle/oracle_test.go` to add a functional test in the Oracle to test account deletion:

    ```
    diff --git a/oracleserv/sandbox-oracle/oracle/oracle_test.go b/oracleserv/sandbox-oracle/oracle/oracle_test.go
    index dce4610..fc9ca94 100644
    --- a/oracleserv/sandbox-oracle/oracle/oracle_test.go
    +++ b/oracleserv/sandbox-oracle/oracle/oracle_test.go
    @@ -150,6 +150,10 @@ func TestCreateAccount(t *testing.T) {
                                    assert.NotNil(t, resp.Exception)
                            }
                    }
    +               _, err = server.DeleteAccount(ctx, &pb.DeleteAccountRequest{
    +                       AccountId: "abc",
    +               })
    +               assert.Nil(t, err)
            }
     }
    ```


6.  Run the functional tests and confirm that it fails:

    ```
    $(make host-go-env)
    go test -v -count 1 -run TestCreateAccount ./...
    Output:
        oracle_test.go:32: time="2021-07-15T16:15:35-07:00" level=error msg="json-rpc error received from phylum" cmd=delete_account jsonrpc_code=-32601 jsonrpc_message="Method not found"
        oracle_test.go:156: 
                    Error Trace:    oracle_test.go:156
                    Error:          Expected nil, but got: &errors.errorString{s:"unknown phylum error"}
                    Test:           TestCreateAccount
    ```

    > _NOTE_: `$(make host-go-env)` sets env in your local shell. It only needs to be called once per shell session.



## Add a New Endpoint to the Phylum

1.  Edit `phylum/utils.lisp` to add the delete account utility functions:

    ```diff
    diff --git a/phylum/utils.lisp b/phylum/utils.lisp
    index 5bed85c..34e8b37 100644
    --- a/phylum/utils.lisp
    +++ b/phylum/utils.lisp
    @@ -16,6 +16,10 @@
               (cc:infof (sorted-map "account_id" acct-id) "GET")
               (let* ([balance (statedb:get acct-id)])
                 (if (nil? balance) '() (to-int balance)))]
    +        [delete-account! (acct-id)
    +          (cc:infof (sorted-map "account_id" acct-id) "DELETE")
    +          (statedb:put acct-id '())
    +          true]
              [put-account! (acct-id balance)
               (cc:infof (sorted-map "account_id" acct-id "balance" balance) "PUT")
               (statedb:put acct-id (to-int balance))
    @@ -32,6 +36,12 @@
                                  (put-account! acct-id balance)
                                  (make-account acct-id balance)))))

    +
    +        (defun delete-account! (acct-id)
    +          (account-do acct-id
    +                      (lambda (found? balance)
    +                        (if found? (delete-account! acct-id) '()))))
    +
             ;; get-account retrieves an account record from statedb.  If the given
             ;; account does not exist a nil value is returned.
             (defun get-account (acct-id)

    ```
2. Edit `phylum/routes.lisp` to add the `delete_account` endpoint:

```diff
diff --git a/phylum/routes.lisp b/phylum/routes.lisp
index fdb34e4..c0a0c32 100644
--- a/phylum/routes.lisp
+++ b/phylum/routes.lisp
+
+; initialize entities a and b to integer values
+(defendpoint "delete_account" (acct)
+  (let* ([id (get acct "account_id")])
+    (if (delete-account! id)
+      (route-success ())
+      (set-exception-business "account does not exist"))))
```

3\. Run the functional tests again to confirm the tests now pass:

```bash
go test -v -count 1 -run TestCreateAccount ./...
Output:
--- PASS: TestCreateAccount (0.18s)
PASS
ok      github.com/luthersystems/sandbox/oracleserv/sandbox-oracle/oracle       0.466s
```

## Add an Integration Test

1.  Edit `tests/example/account.martin_collection.yaml` to include an integration test that calls the new endpoint:

    ```diff
    diff --git a/tests/example/account.martin_collection.yaml b/tests/example/account.martin_collection.yaml
    index 2a4e686..1cd4412 100644
    --- a/tests/example/account.martin_collection.yaml
    +++ b/tests/example/account.martin_collection.yaml
    @@ -67,3 +67,14 @@ tests:
                   // int64 protobuf fields come out as strings in javascript
                   pm.expect(data.account.current_balance).to.equal('120');
               });
    +
    +    - name: "Delete Account: 1"
    +      method: DELETE
    +      path: "v1/accounts/{{ACCT1}}"
    +      test_script: |
    +          pm.test("ok", () => {
    +              let data = pm.response.json();
    +              console.log(data);
    +              pm.response.to.have.status(200);
    +              pm.expect(data).to.not.have.property("exception");
    +            });
    ```


2.  Run the integration tests and confirm they all pass:

    ```bash
    $ make mem-up integration
    Output:
    ↳ Delete Account: 1
      DELETE http://sandbox_oracle:8080/v1/accounts/abc-3e3be99c-239a-45a9-99cd-f30d8b765155 [200 OK, 315B, 29ms]
      ┌
      │ 'X-Request-ID: 7b31bc56-e1db-44ec-b4c2-0028af58823a'
      │ {}
      └
      ✓  ok

    ┌─────────────────────────┬───────────────────┬───────────────────┐
    │                         │          executed │            failed │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │              iterations │                 1 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │                requests │                 6 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │            test-scripts │                12 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │      prerequest-scripts │                 2 │                 0 │
    ├─────────────────────────┼───────────────────┼───────────────────┤
    │              assertions │                 6 │                 0 │
    ├─────────────────────────┴───────────────────┴───────────────────┤
    │ total run duration: 597ms                                       │
    ├─────────────────────────────────────────────────────────────────┤
    │ total data received: 366B (approx)                              │
    ├─────────────────────────────────────────────────────────────────┤
    │ average response time: 51ms [min: 21ms, max: 179ms, s.d.: 57ms] │
    └─────────────────────────────────────────────────────────────────┘
    ```

    🎉 Congratulations! Your new endpoint is fully functional.

