### **Luther Platform Node Architecture**

The Luther Platform separates responsibilities across two types of nodes to ensure high reliability, data integrity, and consistent process execution across systems:

---

### **Processing Nodes – Run Your Business Logic**

Each enterprise system you connect is assigned a **dedicated processing node**. These nodes:

- **Store and execute** the common operations script (COS), which contains your end-to-end process logic.
- **Use LevelDB**, a fast, embedded key-value store, to persist the history and state of each process locally.
- **Emit structured events** to and from external systems based on COS logic.

We chose to dedicate one node per system to **ensure isolation, reliability, and fault tolerance** — if one node encounters issues or is overloaded, it doesn't affect the others. This design also makes it easier to track system-specific behavior and debug workflows.

---

### **Consistency Nodes – Keep Everything in Sync**

The platform deploys **1 or 3 consistency nodes**, depending on your **infrastructure configuration** (i.e., the number of servers and availability zones). These nodes:

- **Ensure all processing nodes remain synchronized** across the cluster.
- **Manage the official history of transactions**, providing a source of truth for event ordering and validation.
- **Run etcd with Raft consensus**, a battle-tested mechanism used by Kubernetes itself to achieve **high availability and strong consistency**.

We use 3 nodes when your setup spans **3 or more availability zones**, allowing the system to **tolerate failure in one zone** while still reaching consensus. If you're running in a smaller setup with fewer zones, we use a **single consistency node** to reduce resource usage while maintaining functional correctness.

We selected etcd with Raft because it's **proven, well-integrated with Kubernetes, and easy to operate** in cloud environments. It gives us fast writes, strong consistency, and built-in quorum logic — all essential for keeping your distributed process state reliable.

---

Together, this architecture ensures that:

- Your **logic runs independently per system**, without interference.
- The system maintains **strong data consistency**, even across zones.
- You don’t need to configure or manage any of this — **we provision it automatically**, and provide visibility into how it’s operating.
