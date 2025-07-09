#### **The VMs are the underlying computers that run your process operations code. Add more virtual machines to increase the reliability of your process operations, so if one computer restarts you can still operate uninterrupted.**

We provision **ARM-based burstable T4g instances** for each virtual machine, offering the best balance of performance and cost efficiency. Each VM is deployed in a **separate availability zone** (based on your selected region) to ensure **high availability and active-active data replication** across the platform.

These VMs run **Amazon Linux 2** and are part of an **Amazon EKS (Elastic Kubernetes Service) cluster**. EKS manages and schedules your **node pods**, which in turn mount **Persistent Volume Claims (PVCs)** to access event and state data.

You are allocated **dedicated infrastructure in your own AWS account** — these VMs are not shared across customers. This isolation ensures **maximum performance, data security, and compliance alignment**.

By default, we allocate **at least one node per VM**, allowing process operations to continue smoothly even if a server becomes unavailable. All VMs are configured with **AWS Auto Recovery**, which automatically restores instances during underlying hardware failures or outages — further enhancing resilience.

This setup enables **Kubernetes self-healing and rescheduling**, so pods are automatically redeployed in the event of failure. Combined with our distributed architecture, this ensures your process operations remain uninterrupted and performant across failure scenarios.
