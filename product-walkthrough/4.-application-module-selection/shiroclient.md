---
description: >-
  Shiroclient is both a gateway (microservice) to the fabric network, and a
  command line tool for interacting with the fabric network.
---

# Copy of Shiroclient

It acts as an intermediary between the application (middleware) code and to the substrate chaincode. Specifically, it supports communication from off-chain services written in Go to directly send messages and receive messages from on-chain Smart Contracts written in the domain specific language (elps). Shiroclient also supports time-based rules which need to be executed after a certain time or at a specific schedule, and a GDPR library.

For more details on the shiroclient-sdk-go, please visit [https://pkg.go.dev/github.com/luthersystems/shiroclient-sdk-go/shiroclient#pkg-overview](https://pkg.go.dev/github.com/luthersystems/shiroclient-sdk-go/shiroclient#pkg-overview)

### Shiroclient Transaction Flow

shiroclient uses the open source fabric-go-sdk project to create and manage transactions throughout the transaction lifecycle, for transactions that interact with luther chaincode (substrate). When shiroclient receives a request it needs to determine which peers to send the transaction to, for simulation and endorsement \[1]. As part of this lookup, shiroclient uses the peer discovery service provided by fabric. During peer discovery, shiroclient will communicate with an orderer to retrieve network configuration, which includes the organisations and peers on the network. After submitting a transaction to a peer for simulation & endorsement, shiroclient inspects the transaction response to determine if the transaction requires commitment. For example, substrate provides mechanisms for business logic to ensure that a transaction is not committed (see cc:force-tx-no-commit), similarly transactions without write-sets or transactions that throw an exception are not committed). If shiroclient determines the transaction requires commitment, then it passes the request to the fabric-go-sdk for commitment.

The fabric-go-sdk 1) uses the dicovery service to lookup peer that belongs to the same organisation, using the configured shiroclient MSP. The fabric-go-sdk then 2) registers an event listener on the peer for the transaction ID, so that the client is notified when the transaction has been committed into a block. Finally, 3) the fabric-go-sdk submits the transaction to the orderer to be ordered and committed in a block.

### Availability Considerations

Importantly, if the fabric-go-sdk cannot discover a peer within its own org as part of step 2), then it returns an error and does not submit the transaction for the orderer. In practice, this means if there are no peers available within shiroclient's organisation, then the fabric-go-sdk cannot commit write transactions. Importantly, 1) this does not effect read transactions that do not require commitment, and 2) this peer requirement is irrespective of the peers necessary for transaction endorsement per a chaincode endorsement policy. This means it is crucial that there is a peer available within the shiroclient's org. We recommend at least 2 peers for high availability.

\[1] https://hyperledger-fabric.readthedocs.io/en/release-2.2/txflow.html
