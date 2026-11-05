---
description: Take Fabric ledger snapshots of a peer, keep them in S3, and join a new peer from a snapshot instead of replaying every block.
---

# Fabric Snapshot Archiver

A new Fabric peer that joins a channel normally gets every block from the
first block and replays them all. On a long chain this takes hours or days, and
the peer needs a disk large enough for the full history. A Fabric ledger
snapshot (Fabric 2.3 and later) holds the state of a channel at one block. A
peer can join the channel from a snapshot and get only the blocks after it.

The [fabric-snapshot-archiver](https://github.com/luthersystems/fabric-snapshot-archiver)
takes snapshots of a running peer, uploads them to S3, and joins a peer to the
channel from a snapshot in S3. In a Luther network it runs as a sidecar
container in each peer pod.

Use it to:

- Add a peer to a long chain quickly.
- Rebuild a peer whose ledger is lost or damaged.
- Run most peers on small, fast `gp3` volumes that hold only the blocks after
  the snapshot. See [Peer Ledger Storage](peer-storage.md).

## Limits of a peer that joined from a snapshot

- It cannot serve a block from before the snapshot.
- `GetHistoryForKey` does not return writes from before the snapshot.
- It has the public state at once, but it must get its private data from other
  peers (gossip reconciliation). This can take hours. Until it is done, a
  transaction that reads private data from an old block fails with
  `private data matching public hash version is not available`. See
  [Wait for private data](#wait-for-private-data).

Keep at least one peer with the full history if you need old blocks or the full
history of a key.

## Turn on the sidecar

In the mars inventory of the environment, set:

```yaml
k8s_fabric_peer_use_snapshot_archiver: true
# Optional: the archiver release. The default is the version mars was tested with.
k8s_fabric_peer_snapshot_archiver_version: v0.0.9
```

Then run the playbook that deploys the peers again. Each peer pod gets a
`fabric-snapshot-archiver` container. The container uses the admin MSP and the
TLS certificates of the peer, and mounts the peer ledger at
`/var/hyperledger/production`. It keeps snapshots in the static S3 bucket of
the environment, under `<environment>/fabric-snapshots/<channel>/<block>`.

The peer pod must run as a service account with an IAM role that may read and
write that S3 prefix. Set both of these:

```yaml
# Creates the service account with the IAM role.
k8s_fabric_peer_service_account_iam_role_arns:
  fabric-peer: arn:aws:iam::<account>:role/<role>
# Runs the peer pods as that service account. The default is "default".
k8s_fabric_peer_service_account: fabric-peer
```

## Take a snapshot

Run the `snapshot` command in the sidecar of a peer that is up to date:

```sh
kubectl exec -n <namespace> <peer-pod> -c fabric-snapshot-archiver -- \
  fabric-snapshot-archiver snapshot
```

The command:

1. Asks the peer for a snapshot at the current block height.
2. Waits for the snapshot to complete.
3. Compresses it and uploads it to S3.
4. Deletes the local copy.

Useful options:

| Option | Default | Use |
|---|---|---|
| `-c <channel>` | `luther` | The channel to snapshot |
| `-b <block>` | `0` (current block) | Take the snapshot when the channel reaches this block |
| `--timeout <duration>` | `15m` | How long to wait for the snapshot |
| `--no-delete` | delete | Keep the local snapshot after the upload |

All peers of a channel have the same ledger, so take snapshots from one peer
only.

Take a new snapshot from time to time. A peer that joins from an old snapshot
must get every block since that snapshot, and its volume holds all of them.

## Take snapshots on a schedule

The sidecar can take a snapshot on a schedule, upload it to S3, and delete the
oldest archives. It needs archiver v0.0.9 or later, and the first mars
release after v0.143.1 ([mars#340](https://github.com/luthersystems/mars/pull/340)).
In the mars inventory, set:

```yaml
k8s_fabric_peer_use_snapshot_archiver: true
k8s_fabric_peer_snapshot_archiver_schedule: true
# Optional, with their defaults:
k8s_fabric_peer_snapshot_archiver_cron: "0 2 * * *" # five-field cron, UTC
k8s_fabric_peer_snapshot_archiver_keep_archives: 14 # 0 keeps all
k8s_fabric_peer_snapshot_archiver_timeout: 2h       # wait for the peer
k8s_fabric_peer_snapshot_archiver_channel: luther
k8s_fabric_peer_snapshot_archiver_schedule_peers: [0]
```

Then run the playbook that deploys the peers again.

- **One peer of one org.** The schedule runs on peer0 only, because every peer
  has the same ledger. Turn it on in one org only: all orgs write to the same
  S3 prefix, so a second org uploads the same channel again and deletes the
  other org's archives.
- **Retention.** After each run whose archive is in S3, the archiver deletes
  the oldest archives of the channel, so that the newest
  `keep_archives` remain. It never deletes the archive it just uploaded. The
  IAM role needs `s3:DeleteObject` on the snapshot prefix. Without it,
  snapshots still upload and the metric `prune_failures_total` counts the
  refusals.
- **A run that cannot start** (a manual snapshot or a restore is running) is
  skipped and counts as `skipped`. A channel with no new block since the last
  run counts as a success and uploads nothing.
- **Recovery mode.** The schedule is off on a peer in recovery mode.
- **Security.** The archiver API has no authentication and can start a
  restore, so it listens on localhost in the pod. Use `kubectl exec` or
  `kubectl port-forward` to reach it.

The playbook stops before it changes anything if a setting is wrong: an
archiver older than v0.0.9, a timeout without a unit (`7200` in place of
`2h`), or a peer index that is not in the org.

### Alert when snapshots stop

Each scheduled peer has a `<release>-archiver` Service on port 9601 that
Prometheus scrapes. Alert when no archive reached S3 for more than a day, for a
daily schedule:

```
time() - fabric_snapshot_archiver_schedule_last_success_timestamp_seconds > 30 * 3600
```

| Metric | Meaning |
|---|---|
| `fabric_snapshot_archiver_schedule_last_success_timestamp_seconds` | When the newest archive of the channel reached S3. Read from S3 at start, so a restart does not reset it |
| `fabric_snapshot_archiver_schedule_last_run_timestamp_seconds` | When the last run started |
| `fabric_snapshot_archiver_schedule_runs_total{result}` | Runs by result: `succeeded`, `failed`, `skipped` |
| `fabric_snapshot_archiver_schedule_prune_failures_total` | Deletions of old archives that failed |

## Join a peer from a snapshot

The peer must be running and must not have joined the channel.

**Caution:** the mars channel step (role `k8s_fabric_channel`) joins every peer
that is not in the channel, from the first block. When you deploy a peer that
will join from a snapshot, run only the peer step (role `k8s_fabric_peer`), and
run the `restore` command before the next channel step. If the channel step
joins the peer first, the peer replays every block, and you must start again
with an empty ledger.

- **A new peer:** deploy it with the sidecar turned on. Do not join it to the
  channel.
- **A peer with a lost or damaged ledger:** put the peer in recovery mode with
  `k8s_fabric_peer_recovery_overrides` and run the playbook. The pod starts,
  but the peer process does not. Delete the old ledger from the sidecar
  (`rm -rf /var/hyperledger/production/ledgersData`). Then turn recovery mode
  off and run the playbook again, so the peer starts with an empty ledger.

Then run the `restore` command in the sidecar of that peer:

```sh
kubectl exec -n <namespace> <peer-pod> -c fabric-snapshot-archiver -- \
  fabric-snapshot-archiver restore
```

The command finds the newest snapshot of the channel in S3, downloads it, joins
the peer to the channel from it (`peer channel joinbysnapshot`), and deletes
the download. To use an older snapshot, give its block with `-b <block>`. Use
`-c <channel>` for a channel other than `luther`.

The peer then gets the blocks after the snapshot from the other peers.

### Wait for private data

Add `--wait-pvtdata` to make the restore wait until the peer has all of its
private data:

```sh
kubectl exec -n <namespace> <peer-pod> -c fabric-snapshot-archiver -- \
  fabric-snapshot-archiver restore --wait-pvtdata --chaincode-name cc-luther
```

Fabric has no command that reports how much private data a peer still misses,
so the archiver asks the chaincode. It calls substrate's `pvtdata_health_check`
endpoint every 5 minutes (`--pvtdata-poll-interval`) and stops after 8 hours
(`--pvtdata-timeout`). The check reads one sentinel key, which must be set once
per chain. The archiver
[README](https://github.com/luthersystems/fabric-snapshot-archiver#waiting-for-private-data---wait-pvtdata)
tells how.

If the wait times out, the peer stays joined. To wait again without a second
restore:

```sh
fabric-snapshot-archiver restore --no-s3 --no-restore --no-delete -b <block> --wait-pvtdata
```
