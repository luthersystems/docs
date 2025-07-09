# Major Platform Release Announcement: v3.0.0 Enhancing Security and Performance

**Release Date**: September 1st, 2024

We are excited to announce a major upcoming release for our platform, scheduled for the end of August. This release includes several enhancements aimed at improving platform stability, performance, and operational efficiency. While these changes will bring significant benefits, they also include a couple of breaking changes that will require some preparation on your part.

## High-Level Summary

1. **Improved Performance**: We are implementing limits on the number of operations allowed in a single transaction to ensure smoother and faster processing.
2. **Improved Security**: These limits also protect against application bugs that could be exploited to slow down other transactions and stop peers from processing transactions.
3. **Simplified Deployment**: We are adopting a new method for deploying business logic to our platform, making the process more straightforward and easier to manage.

## Detailed Technical Description

### 1. Transaction Simulation Key Access Limits

#### Current Scenario

Our platform includes the _substrate_ runtime, which runs as chaincode. Substrate provides a safe, deterministic, and "batteries included" development environment for process operations logic written in ELPS. Currently, there are no limitations on the number of keys read and written during transaction simulation. Each key access involves network communication between the substrate container and the connected Fabric peer via gRPC, with the peer accessing the underlying state database (LevelDB). This network communication introduces approximately 1ms of overhead per key lookup. Reducing the number of keys accessed results in shorter simulation times for the immediate transaction and has knock-on performance benefits due to the Fabric peer architecture.

The Fabric peer architecture is designed to be multithreaded, using a worker pool of Go routines that concurrently process transactions. When a peer receives a new block from the Orderer, it needs to validate and commit this block to the ledger and update the state database with the read-write sets (changes) resulting from committing the transactions in the block. Because block commitment alters the state database and transactions concurrently read from the state database, Fabric uses a "read-write" lock ([RWMutex](https://pkg.go.dev/sync#RWMutex)) to ensure both transaction simulation and block commitment operate on a single consistent version of the state database. The simulation process uses a "read lock," and the block commitment process uses a "write lock." If a peer is processing a transaction and receives a new block, the peer must wait for all pending transactions to complete before committing the block. If a transaction is received while the block is waiting to be committed, it is scheduled for simulation after the block is committed and cannot be processed concurrently. This "waiting" or "blocking" due to the lock results in delays. Transactions that take a long time (e.g., because they read many keys) can significantly impact the overall performance of the peer.

#### Example

Suppose a peer is processing three transactions at t0: two short ones (200ms) and one long one (5s). It also receives a block at t0. The peer needs to wait for these three transactions to complete before it commits the block. After 200ms (t0+200ms), the two short transactions complete. If the peer receives a fourth short transaction at t0 + 1s, it must wait 4 more seconds (t0+5s) for the slow transaction to finish before committing the block and then processing the fourth transaction. Although the fourth transaction normally takes only 200ms, in this scenario, it takes 4.2s due to the "clog" from the slow transaction.

#### Implications

This "clog" affects block confirmations. After a transaction is simulated, the gateway (Shiroclient gateway) submits the transaction to the orderer for commitment. The gateway must wait for a block confirmation event from the peer before confirming to the application that the transaction was successfully committed. If the peer is processing a slow transaction, block confirmations for fast transactions are delayed. In other words, "slow transactions" delay all surrounding requests.

See the appendix for current approaches to addressing these delays.

#### New Key Limit

To address these limitations, we are implementing a key limit of 400 unique keys per transaction, functioning as the equivalent of a rate limit. Transactions that access more than 400 keys will immediately abort with an unexpected exception. Just as API rate limits are necessary to ensure the security and overall performance of backend systems, the same reasons motivate the key limit. This protects against "runaway" transactions that adversely impact the entire system, and limits the scope of denial of service (DoS) attacks. If your application does not read more than 400 keys as part of its regular process operations, no change is necessary. However, if your application does read more than 400 keys (and not due to a logic bug), you must update your application to ensure transactions do not access more than 400 keys.

The limit of 400 was chosen to put a simulation cap of roughly 400ms. As a rule of thumb, each key lookup takes ~1ms in production environments. In a worst case locking scenario, this enforces an upper bound of ~800ms (400ms during the simulation, and 400ms waiting for confirmation due to another transaction) delay due to the lock. This 800ms does not include network, retry, or ordering delays. We chose not to limit the execution time directly, since time is non-deterministic in chaincode, and a function of the underlying hardware which is different across environments.

#### Suggested Preparation Steps & Guidance

- **Assess and Refactor:** Identify transactions that access more than 400 keys and refactor them using these techniques:
  - **Split Transactions:** Break down large transactions into multiple smaller ones. For example, a transaction performing user permission checks and data verification checks can be split into separate transactions and endpoints.
  - **Merge data accessed together into common keys:** For data that is spread across keys that is often accessed together within a transaction should be put into a single key. For example, a list of user IDs associated with a case should be stored directly on the case key, and not as a growing list of keys.
- **Adopt the CQRS Pattern**: Offload read-intensive operations to a relational database with fast and automatic indexing. The CQRS (Command Query Responsibility Segregation) pattern separates read and write operations, allowing for more efficient processing of read-only transactions. For more information, refer to the [CQRS architectural pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/cqrs).
- **Use Transaction Caching**: Implement application-level caching (such as Redis) for repetitive read operations, especially for slow back-to-back read transactions that unnecessarily recalculate data that hasn't changed.

**Note**: Substrate migration transactions are not impacted by these key limits.

### 2. Adoption of Chaincode as a Service (CCaaS) Pattern

#### Current Deployment Model

Substrate runs as external chaincode on Fabric. The current deployment involves sidecar containers and automated scripts to bundle chaincode, which adds complexity to the deployment process.

#### New Deployment Model

With Fabric 2.5, we are adopting the CCaaS pattern as the default deployment model. This change simplifies the deployment process by:

- Eliminating the need for the [buildpack sidecar](https://hub.docker.com/repository/docker/luthersystems/buildpack/general) containers.
- Removing the need for automated shell scripts to generate chaincode bundles.

#### Benefits

- **Simplified Deployment:** Easier and faster deployment of chaincode.
- **Reduced Complexity:** Fewer components to manage and maintain.
- **Safer Updates:** More streamlined and predictable update processes.

#### Preparation Steps & Guidance

- **Review Documentation**: Familiarize yourself with the new CCaaS deployment process. Detailed documentation is available [here](https://hyperledger-fabric.readthedocs.io/en/latest/cc_basic.html).
- **Update Deployment Pipelines:** Modify your deployment pipelines to accommodate the new pattern. Specific CCaaS pipeline scripts can be found [here](https://github.com/luthersystems/mars/tree/main/ansible-roles/k8s_fabric_chaincode).
- **Test Deployments:** Conduct thorough testing of your chaincode in the new deployment environment to ensure smooth transitions.

## Appendix: Current Approaches

1. **Run More Peers:** By quickly restoring them from snapshots, the transaction "load" is spread across more peers, reducing the "blast" radius and the impact of slow transactions.
2. **Group Peers into "Fastlane" and "Slowlane"**: Using the `WithTargetEndpoints` Shiroclient-SDK-Go [feature](https://github.com/luthersystems/shiroclient-sdk-go/blob/1b76b2b8331b223e60438f4293c79131d042216d/shiroclient/configs.go#L128), short transactions are sent to the fast lane peers, avoiding slow "clogs." Slow transactions are routed to the "slowlane" peers. Assuming there are fewer slow transactions than fast ones, this method reduces the impact of slow transactions.
3. **Use Eventing Peers:** Set aside peers that do not simulate any transactions and use these \
   peers only for the event service. This allows them to rapidly process blocks and notify the gateway as soon as the pending transactions are committed, without being blocked by any transaction simulations. This is done by selectively disabling the event service (`eventService.eventSource` to false) in the gateway `fabric-client.yaml` configuration.

Although these methods help, they don't address the fundamental architectural constraints of the Fabric lock.
