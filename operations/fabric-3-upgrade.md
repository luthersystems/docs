---
description: Upgrade a running Luther network from Hyperledger Fabric 2.5 to 3.x with Raft ordering, with the mars upgrade scripts.
---

# Fabric 3 Upgrade

This page tells you how to upgrade a running network from Hyperledger Fabric
2.5 to Fabric 3.1 or later. The network keeps Raft ordering. The scripts and
the full runbook are in [mars](https://github.com/luthersystems/mars), the
infrastructure tool that deploys Luther networks.

## Why upgrade

| Reason | Detail |
|---|---|
| Support | Fabric 2.5 is the last 2.x release line. Fixes go to 3.x. |
| Speed | A 3.x peer can send chaincode reads and writes in batches. Substrate uses this. |
| BFT | Fabric 3 adds BFT ordering. The upgrade keeps Raft. BFT is a separate change. |

## Where the scripts are

| Item | Location in mars |
|---|---|
| Runbook (full detail, errors and fixes) | [`docs/fabric-3-upgrade.md`](https://github.com/luthersystems/mars/blob/main/docs/fabric-3-upgrade.md) |
| Ansible role: pre-flight check and system channel removal | [`ansible-roles/k8s_fabric_upgrade_v3`](https://github.com/luthersystems/mars/tree/main/ansible-roles/k8s_fabric_upgrade_v3) |
| Shell scripts: `fabric3-preflight.sh`, `remove-system-channel.sh`, `fabric3-utils.sh`, `upgrade-pauser.sh` | [`ansible-roles/k8s_fabric_scripts/files/scripts`](https://github.com/luthersystems/mars/tree/main/ansible-roles/k8s_fabric_scripts/files/scripts) |
| End-to-end test on a local network | [`scripts/test-fabric3-upgrade.sh`](https://github.com/luthersystems/mars/blob/main/scripts/test-fabric3-upgrade.sh) |

Your infrastructure repository calls the role and the scripts from
playbooks. You run each playbook with mars, for example
`mars <env> ansible-playbook fabric3_preflight.yaml`.

## Steps

Do each step on a test network first. Do the next step only when the step
before it is done on every node.

| Step | What | Playbook | Undo |
|---|---|---|---|
| 0 | Take EBS snapshots of the orderer and peer volumes. Run the pre-flight check. | `fabric3_preflight.yaml` | Not needed |
| 1 | Restart the 2.5 orderers with channel participation on | `fabric_remove_system_channel.yaml` (first part) | Set the flag false and run the orderer playbook again |
| 2 | Remove the system channel | `fabric_remove_system_channel.yaml` (second part) | **None.** Restore the orderer volumes from the snapshots. |
| 3 | Upgrade the orderers, then the peers, to 3.x, one node at a time | `fabric_upgrade.yaml` with the new version | Restore the volumes from the snapshots |
| 4 | Run the pre-flight check again, check the health endpoint, and do one write | `fabric3_preflight.yaml` | Not needed |

**Caution:** step 2 has no undo. Take the snapshots in step 0 before you start
step 1.

The pre-flight check reads the network and changes nothing, so you can run it
at any time. It must say `READY` before step 3 and after it.

Step 1 sets this in the inventory of the environment. Keep it set from then
on:

```yaml
k8s_fabric_orderer_channel_participation: true
```

## What Fabric 3 removes

A 3.x node does not start when the network uses one of these items. The
pre-flight check finds each one before you change a node.

| Removed in Fabric 3 | Luther networks | Action |
|---|---|---|
| Upgrade from a version before 2.5 | 2.5 | None. Upgrade an older network to 2.5 first. |
| System channel | Each network has one. Nothing uses it at run time. | Steps 1 and 2 remove it. |
| Kafka and Solo ordering | Raft | None |
| Legacy chaincode lifecycle (`lscc`) | `_lifecycle` | None. The pre-flight check confirms it. |

You do not need the `V3_0` channel capability. It is only for BFT ordering.

## Prevent an upgrade by accident

A change of the Fabric version in the inventory is an upgrade. Do it only with
`fabric_upgrade.yaml`, which runs the pre-flight check and restarts one node
at a time. A plain orderer or peer playbook does neither. Make the plain
playbooks refuse to run when a running node has a different Fabric version
than the inventory. Then a version change cannot reach a network before its
upgrade runs.

## Known limits

| Limit | Detail |
|---|---|
| New networks | A new 3.x network has no system channel, and mars cannot create the first channel without one yet ([mars#343](https://github.com/luthersystems/mars/issues/343)). Create a new network on 2.5, then upgrade it. |
| Docker chaincode | A 3.x peer that builds chaincode with Docker uses the upstream `fabric-ccenv` image. Chaincode as a service (`ccaas`) is not affected. The pre-flight check shows a warning. |
