# Operations

Guides for running a Luther network. Each page here is a copy of a page on
[docs.luthersystems.com](https://docs.luthersystems.com), made by the site
sync. Edit the page in luthersystems/frontpage-docs, not here. This index is
edited here.

- [peer-storage.md](peer-storage.md): Choose the EBS volume type of peers and
  orderers (`sc1` or `gp3`), with measured commit times and cost, and change a
  peer volume to `gp3` in place.
- [fabric-snapshot-archiver.md](fabric-snapshot-archiver.md): Take Fabric
  ledger snapshots of a peer, keep them in S3, and join a new peer from a
  snapshot.
