---
description: Decrease the AWS cost of a Luther network with ARM (Graviton) worker nodes, tiered peer storage and peers that join from a snapshot.
---

# Cloud Cost Optimization

Three changes decrease the AWS cost of a Luther network the most. Read the
limits of each change on its details page before you make it.

| Change | What it decreases | Typical saving | Details |
|---|---|---|---|
| Run the EKS worker nodes on ARM (Graviton) | Compute | About 20% per node-hour | [Run on ARM](#run-on-arm-graviton) |
| Keep old blocks on `sc1`, recent blocks on `gp3` | Peer storage | About 80% compared with all `gp3` | [Peer Ledger Storage](peer-storage.md#tiered-storage) |
| Join most peers from a snapshot | Peer storage | More than 95% compared with all `gp3` | [Fabric Snapshot Archiver](fabric-snapshot-archiver.md) |

The savings are estimates from us-west-2 list prices. Your savings depend on
your region, your load and your discounts.

## Run on ARM (Graviton)

AWS Graviton instances use ARM (`arm64`) processors. A Graviton instance costs
about 20% less per hour than the x86 instance of the same size, for example
`m7g.large` in place of `m7i.large`. Luther's own platform runs its EKS worker
nodes on Graviton (`t4g`).

### Images

Kubernetes pulls the `arm64` image on an ARM node. You do not change the image
names or tags. These images publish for `amd64` and `arm64`:

| Image | `arm64` |
|---|---|
| `luthersystems/substrate`, `luthersystems/shiroclient` | Yes |
| `luthersystems/auth` (lutherauth) | Yes |
| `luthersystems/connectorhub` | Yes |
| `luthersystems/fabric-snapshot-archiver` | Yes |
| `luthersystems/pdfserv`, `luthersystems/martin` | Yes |
| `luthersystems/awscli`, `luthersystems/dind`, `luthersystems/fabric-tools` | Yes |
| `hyperledger/fabric-peer`, `fabric-orderer` 2.5 and 3.1 | Yes |
| `hyperledger/fabric-peer`, `fabric-orderer` 2.2 and 2.4 | **No** |
| `hyperledger/fabric-ca` 1.5 | Yes |
| `hyperledger/fabric-ca` 1.4 | **No** |
| `luthersystems/fabric-ccenv` 2.5 and 3.1 | Yes |
| `luthersystems/fabric-ccenv`, `fabric-baseos` 2.2 and 2.4 | **No** |

**Fabric 2.5 or later, and Fabric CA 1.5 or later, are necessary for ARM.**
The Fabric 2.2 and 2.4 images and the Fabric CA 1.4 image are `amd64` only. On those versions, keep the nodes that run Fabric on x86, or
upgrade Fabric first (see [Fabric 3 Upgrade](fabric-3-upgrade.md)).

Check every other image that runs in your cluster, for example your own
services and monitoring agents. This command lists the architectures of one
image:

```sh
docker buildx imagetools inspect luthersystems/connectorhub:<version> | grep Platform
```

### Move a node group to Graviton

1. Make sure that every image on the node group publishes `arm64`.
2. Set the worker instance type to a Graviton type, for example `t4g`, `m7g`
   or `c7g`. The Luther `eks-vpc` Terraform module selects the ARM node AMI
   from the instance type. All instance types of one node group must be the
   same architecture.
3. Apply the change. EKS replaces the nodes, and Kubernetes starts each pod
   again with the `arm64` image.
4. Check that each pod is running:

   ```sh
   kubectl get pods -A -o wide
   ```

Move a test environment first, then production.

## Storage

The peer ledger is often the largest storage cost. For the measurements and
the cost of each layout, see [Peer Ledger Storage](peer-storage.md).
In summary:

- Put orderer volumes on `sc1`. The orderer's write-ahead log is as fast on
  `sc1` as on `gp3`.
- Keep 2 or 3 archive peers with the full chain history, with tiered storage:
  recent blocks on `gp3`, old blocks on `sc1`.
- Join all other peers from a snapshot, on small `gp3` volumes. A peer that
  joined from a snapshot keeps only the blocks after the snapshot. See
  [Fabric Snapshot Archiver](fabric-snapshot-archiver.md).

For 40 peers with 4 TB each, this layout costs about $300 to $500 each month.
All `gp3` costs about $13,000 each month.

## Test environments

These changes are for test environments only:

- Use Spot instances for the EKS worker nodes. Give the node group several
  instance types, so that EKS can find Spot capacity. Each type must allow at
  least as many pods as the base type. For example, `t4g.large` allows 35
  pods, but `m7g.large` allows 29, so a rolling deploy can fail with "Too many
  pods". Use the `.xlarge` sizes for the other types. A Spot node can stop at
  any time, so do not use Spot for production peers or orderers.
- Use smaller node and volume sizes than production. An `sc1` volume must be
  125 GiB or larger.
