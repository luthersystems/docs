#### **The number of cores is effectively the “size” of each server. More cores means the server can process more concurrent tasks. Since tasks are typically processed quickly, you can start with 2 and increase as you grow.**

The Luther Platform is built in **Golang**, a highly efficient language designed for concurrency. Go automatically allocates work across threads, which scale naturally with the number of CPU cores. This makes **vertical scaling hassle-free** — as you add cores, the application immediately puts them to use without requiring any configuration changes.

Most of the compute is dedicated to **executing the common operations script (COS)** on new events — driving your process logic forward by evaluating steps, interacting with external systems, and updating state. A smaller portion of compute ensures the **validation and integrity of historical event data**.

We recommend starting with **at least 2 cores per server**. With only a single core, the system can only handle one event at a time, which may quickly lead to **delays and processing bottlenecks** as load increases. Two or more cores allow the platform to process events concurrently, keeping throughput high and latency low.
