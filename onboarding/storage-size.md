#### **Each server has storage that records the events executed for your process. Events typically range from 20–200KB depending on how much processing your operations perform. As your product scales, you can increase storage size over time.**

Each node is assigned an **Amazon EBS volume** (using the cost-efficient, throughput-optimized `sc1` class), which is the **only source of persistent data** in the stack. These volumes store:

- The full **history of structured events** emitted by the common operations script (COS), stored in LevelDB.
- The **current state data** read and written by the COS as it drives your process.

By default, **each node stores a replica of the event history**, providing **active-active data replication** across the platform.

Volumes are provisioned via Kubernetes **Persistent Volume Claims (PVCs)**, support **dynamic resizing**, and are formatted with the **ext4** filesystem. They are located in an **availability zone based on your selected region**, and are protected with **full-disk encryption using AWS KMS-managed keys** for security.

**Optional features** such as **PVC snapshots** and **cross-zone replication** can be enabled for added redundancy and recovery, with additional storage costs.
