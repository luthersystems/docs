---
description: Choose the EBS volume type for Fabric peers and orderers, sc1 or gp3, from measured block commit times and cost.
---

# Peer Ledger Storage

A Fabric peer writes every block to its disk twice: once to the block store
and once to the state database. So the volume type of the peer ledger sets how
fast the network commits transactions. This page compares the two EBS volume
types that Luther networks use, `sc1` (cold HDD) and `gp3` (general purpose
SSD), and tells you which one to use for each node.

## Summary

| Node | Volume type | Why |
|---|---|---|
| Peer that joined from a [snapshot](fabric-snapshot-archiver.md) | `gp3` | It holds only the blocks since the snapshot, so a small fast volume is cheap |
| Peer that keeps the full chain history | `gp3`, or `sc1` if cost is more important than speed | A full history on `gp3` costs about 5 times more than on `sc1` |
| Orderer | `sc1` is sufficient | Its write-ahead log was as fast on `sc1` as on `gp3` |

## Measurements

We ran the same load (16 workers) on a test network twice: once with the peer
and orderer volumes on `sc1`, and once with them on `gp3`. Each peer had a
125 GiB volume.

| Metric | `sc1` | `gp3` |
|---|---|---|
| Peer block commit, per block | 910 ms | 10 ms |
| State database commit, per block | 273 ms | 4 ms |
| Gateway wait for commit | 2.1 s | 61 ms |
| Write latency, p50 / p95 | 3.5 s / 6.2 s | 0.32 s / 0.39 s |
| Read latency, p50 | 1.45 s | 0.24 s |
| Requests completed in 90 s | 844 | 5,108 (6 times more) |
| Orderer write-ahead log persist | 3 ms | 3 ms |

On `sc1` the peer disk was the bottleneck: the block store took 510 ms and the
state database 273 ms of each block commit. The orderer was not: its
write-ahead log took 3 ms on both volume types.

**Note:** `sc1` throughput increases with the volume size. A 4 TB `sc1` volume
has about 30 times the throughput of the 125 GiB test volume. On a network
with large `sc1` volumes, the gain from `gp3` is smaller than the table shows.
Measure your own network before and after the change.

## Cost

The monthly cost of 40 peers with 4 TB each, at us-west-2 list prices:

| Layout | Monthly cost |
|---|---|
| All `sc1` | about $2,400 |
| All `gp3` | about $13,000 |
| Tiered on every peer: recent blocks on `gp3`, older blocks on `sc1` (upcoming, see below) | about $2,800 |
| 2 or 3 archive peers with the full history (tiered), and all other peers joined from a snapshot on small `gp3` volumes | about $300 to $500 |

The last layout is the least expensive and the fastest. A peer that joined from
a snapshot keeps only the blocks after the snapshot, so its volume stays small.
Its volume grows with each new block, so take a new snapshot from time to time
and join new peers from the newest one.

A peer that joined from a snapshot has these limits:

- It cannot serve a block from before the snapshot.
- `GetHistoryForKey` does not return writes from before the snapshot.

Keep at least one peer with the full history if you need old blocks or the full
history of a key.

## Change a peer volume from sc1 to gp3

You can change the type of an existing EBS volume while the peer runs. You do
not have to copy the ledger. In the mars inventory of the environment, set:

```yaml
k8s_fabric_peer_volume_type_override: gp3
```

Then run the playbook that deploys the peers again. mars adds the annotation
`ebs.csi.aws.com/volumeType: gp3` to the volume claims of the peer, and the EBS
CSI driver changes the volume type. The volume stays online during the change.
We made this change on the test network.

Make sure that the change occurred. Find the EBS volume ID of the peer
(`kubectl get pv`), then:

```sh
aws ec2 describe-volumes-modifications --volume-ids <volume-id>
aws ec2 describe-volumes --volume-ids <volume-id> --query 'Volumes[0].VolumeType'
```

If the type did not change, the EBS CSI driver of the cluster does not modify
volumes from annotations. Change the volume with
`aws ec2 modify-volume --volume-id <volume-id> --volume-type gp3` instead.

**Note:** AWS lets you change a volume only once in 6 hours. The annotation is
also set on the Docker storage claim of a peer that builds chaincode with
Docker. An `sc1` volume must be 125 GiB or larger, so to go back to `sc1`, both
volumes must be that large. Otherwise go back to `gp2`.

The type of a new peer volume is set where the volume is made. On AWS,
Terraform makes the peer volumes (tf-modules `eks-ebs-persistentvolume-set`,
variable `init_volume_type`), and the peer claims them by label.
`k8s_fabric_peer_storage_class` must match the storage class of those volumes;
it does not set their type.

## Tiered storage (upcoming)

A peer keeps all of its old block files, but it reads them only to serve old
blocks. Tiered storage keeps the state database and the recent block files on
`gp3`, and moves the sealed (complete) block files to an `sc1` archive
volume, with a link in their old place so the peer still finds them. This gives `gp3` commit speed at near `sc1` cost for a peer that must keep the
full history. The archiver's `archive-blocks` mode, which moves the files,
is merged and goes out in fabric-snapshot-archiver v0.0.9
([fabric-snapshot-archiver#38](https://github.com/luthersystems/fabric-snapshot-archiver/pull/38)).
Support in the mars fabric-peer chart is in progress
([luthersystems/mars#337](https://github.com/luthersystems/mars/pull/337)).

## Other options we examined

| Option | Result |
|---|---|
| Change the EBS volume type in place | Used: this is the change above. EBS has no tiering inside one volume |
| Kubernetes `VolumeAttributesClass` | Changes the type, IOPS or throughput of a volume claim. No tiering |
| Amazon FSx for NetApp ONTAP | The only built-in option with fast sync and cheap cold data: an SSD tier that moves cold blocks to a capacity pool. It adds a minimum throughput charge, network latency on each sync and a new service to run |
| Amazon EFS with Infrequent Access | Not used: sync over NFS is slow, and the LevelDB state database on NFS is a risk |
| Mountpoint for Amazon S3 | Not used: it does not support sync or appends to a file |
| EC2 instance store (NVMe) | Fastest, but the data is lost with the node. Use it only for a peer that can join again from a snapshot |
