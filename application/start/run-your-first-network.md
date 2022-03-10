---
description: >-
  This guide shows you how to launch a local fabric network and deploy an update
  to your Smart Contract.
---

# Run Your First Network

## Launch Your Network

1\. Bring up a local Hyperledger Fabric network and install the Luther runtime (substrate):

```
$ make up
```

2\. Check the running `docker` containers to confirm the network is running. You'll see the default configuration brings up the following services:

* **1 x oracle (sandbox/oracle):**
  * Serves the API and includes logic for connecting to external services and transforming data for subsequent processing in the Smart Contract.
* **1 x chaincode (dev-peer0.org...):**
  * Executes the business logic rules written in `elps` directly within the deployed Smart Contract.
* **1 x shiroclient (luthersystems/shiroclient):**
  * Gateway into the fabric network. Contains a private key for an authorized identity to submit data (signed transactions) for processing by Smart Contracts on the network.&#x20;
* **1 x fabric-tools (hyperledger/fabric-tools):**
  * Helper scripts and utilities for managing the network.
* **1 x fabric-orderer (hyperledger/fabric-orderer):**
  * Ordering service that collects valid transactions and creates blocks that confirm transactions.&#x20;
* **1 x fabric-peer (hyperledger/fabric-peer):**
  * Network node that maintains a copy of the ledger and runs Smart Contracts for transaction execution and validation.
* **1 x fabric-ca (hyperledger/fabric-ca):**
  * Certificate authority that issues certificates for the peer's org and shiroclient identity.&#x20;

{% hint style="warning" %}
For illustrative purposes this network has 2 fabric orgs: 1) an org responsible for ordering transactions and generally operating the network, and 2) an org responsible for executing Smart Contracts. \
\
**Your production network will have multiple fabric orgs that cut across your groups in your business, as well as span external groups outside of your business.**&#x20;
{% endhint %}

The network executes the Smart Contracts to ensure that all the participants are in agreement as to the current state of your business process.&#x20;

```
$ docker ps | awk '{print $2;}' 
# Output:
sandbox/oracle
dev-peer0.org1.luther.systems-phylum-2.160.0-fabric2-0a302b31f1ac3fd4783a95bae8804e9d13ef0f7d54c2154ecd038d6b2b4bf5ce-12be208bed792721a794b4de9c8cf439c5dc79211f6fe179a9b44bf3b0504984
luthersystems/shiroclient:2.160.0-fabric2
hyperledger/fabric-tools:amd64-2.2.0
hyperledger/fabric-orderer:amd64-2.2.0
hyperledger/fabric-peer:amd64-2.2.0
hyperledger/fabric-ca:amd64-1.4.7                 
```

3\. Run the end-to-end integration tests against the network:

```
$ make integration
# Output:
...
┌─────────────────────────┬────────────────────┬───────────────────┐
│                         │           executed │            failed │
├─────────────────────────┼────────────────────┼───────────────────┤
│              iterations │                  1 │                 0 │
├─────────────────────────┼────────────────────┼───────────────────┤
│                requests │                  5 │                 0 │
├─────────────────────────┼────────────────────┼───────────────────┤
│            test-scripts │                 10 │                 0 │
├─────────────────────────┼────────────────────┼───────────────────┤
│      prerequest-scripts │                  2 │                 0 │
├─────────────────────────┼────────────────────┼───────────────────┤
│              assertions │                  5 │                 0 │
├─────────────────────────┴────────────────────┴───────────────────┤
│ total run duration: 904ms                                        │
├──────────────────────────────────────────────────────────────────┤
│ total data received: 364B (approx)                               │
├──────────────────────────────────────────────────────────────────┤
│ average response time: 114ms [min: 40ms, max: 172ms, s.d.: 47ms] │
└──────────────────────────────────────────────────────────────────┘      
```

4\. View the logs from your Smart Contract:

```
$ docker logs  $(docker ps | grep chaincode | awk '{print $1;}') 
# Output:
time="2021-07-20T19:37:27Z" level=info msg="Operation complete" dirty=false dur_ms=31 method=vbc_get_transactions op=Handle req_id=5719c5d9-3a83-49ff-8d85-4e3a914eca1f req_time="2021-07-20T19:37:27Z" time_op=Handle
time="2021-07-20T19:37:27Z" level=info msg="Handler found" endpoint=get_account op=Handle req_id=fe2c015d-44e5-4b08-b515-bea191e9c522 req_time="2021-07-20T19:37:27Z"
time="2021-07-20T19:37:27Z" level=info msg=GET account_id=xyz-4e6778bd-133c-4bfe-85c8-f61605a297e1 op=Handle req_id=fe2c015d-44e5-4b08-b515-bea191e9c522 req_time="2021-07-20T19:37:27Z"
time="2021-07-20T19:37:27Z" level=info msg="Operation complete" dirty=false dur_ms=24 method=get_account op=Handle req_id=fe2c015d-44e5-4b08-b515-bea191e9c522 req_time="2021-07-20T19:37:27Z" time_op=Handle
```

{% hint style="info" %}
Note that you see the log lines for the requests that were issued by the integration tests we ran in the previous step.Every request includes a `request_id` which is logged across all of the services that process the request and is helpful for debugging.&#x20;
{% endhint %}

## Deploy an Over-the-air Update

Let's update the business logic in your Smart Contract and deploy it on your running network. \
\
1\. Add a trace statement in the `phylum/routes.lisp` to print the transfer request message:

```
diff --git a/phylum/routes.lisp b/phylum/routes.lisp
index fdb34e4..36684ac 100644
--- a/phylum/routes.lisp
+++ b/phylum/routes.lisp
@@ -79,6 +79,7 @@
 
 ; make a payment of x units from entity a to entity b
 (defendpoint "transfer" (xfer)
+  (trace xfer "TRANSFER")
   (let* ([payer-id (get xfer "payer_id")]
          [payee-id (get xfer "payee_id")]
          [xfer-amount (to-int (get xfer "transfer_amount"))])
```

2\. Update the Smart Contract using `make init`

```
$ make init
```

3\. Run the integration tests again to create new transactions:

```
$ make integration
# Output:
...
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
│ total run duration: 684ms                                       │
├─────────────────────────────────────────────────────────────────┤
│ total data received: 364B (approx)                              │
├─────────────────────────────────────────────────────────────────┤
│ average response time: 88ms [min: 30ms, max: 136ms, s.d.: 39ms] │
└─────────────────────────────────────────────────────────────────┘
```

4\. View the Smart Contract logs and confirm you see the `trace` log line:

```
$ docker logs  $(docker ps | grep chaincode | awk '{print $1;}')
# Output:
...
time="2021-07-20T20:00:13Z" level=info msg="Handler found" endpoint=transfer op=Handle req_id=ec6d6a56-f5d2-4983-a40a-0f5a4d7acfa6 req_time="2021-07-20T20:00:13Z"
"TRANSFER" (sorted-map "payee_id" "xyz-4ed5ea9c-ac6b-4163-9d69-2e07923041d4" "payer_id" "abc-5585ff9f-dbad-4448-bdd6-c159bebe9e5c" "transfer_amount" "20")
...
```

{% hint style="info" %}
Note that the `trace` command will log the entire request object. The request includes data provided by the API, including the `payee_id`, `payer_id` and `transfer_amount`.
{% endhint %}

Congrats :tada: ! Your new code is now deployed on the running network.

{% hint style="warning" %}
In most cases you do not need to run the entire fabric network locally on your machine. Use `make mem-up` to bring up an "in-memory" emulation of the fabric network that runs directly in the `oracle` process and live-reloads any changes to the phylum.&#x20;

In-memory mode saves development time and should almost always be used, unless your business logic uses fabric specific commands that cannot be emulated.
{% endhint %}

5\. Bring down the network:

```
$ make down
```
