### **How AWS Hosting Costs Are Estimated for the Luther Platform**

The Luther Platform runs on AWS and uses a mix of fixed and variable resources to operate customer environments. We estimate monthly hosting costs based on a few customer-specific inputs, such as the number of systems being integrated, how many servers and cores they run, and how much data is stored.

#### **🔧 Customer Inputs**

To calculate the cost, we ask for:

- **Number of Systems** – how many enterprise systems are connected. Each system is connected to a Luther node.
- **Number of Servers** – how many virtual servers run the platform nodes.
- **Cores per Server** – how much CPU is allocated per server and shared between nodes.
- **Storage\* (GB)** – how much disk space is needed per node.

\*based on typical data processed per system per run (300KB) and typical number of process runs (500 per month).

These inputs affect how much compute, storage, and monitoring the platform needs.

### **🧮 How We Estimate Costs**

We break the estimate into three parts:

#### **1. Fixed Costs (approx. £96/month)**

These are baseline services that run regardless of customer size:

- A managed Kubernetes cluster (EKS)
- Load balancer for handling traffic
- VPC, DNS, and Secrets Management (KMS/SSM)
- Tools like Grafana for dashboards and monitoring

These costs stay the same due to the base platform architecture. All estimates are based on the AWS eu-west-2 region in GBP, and do not include taxes.

#### **2. Provisioned Variable Costs (Based on Customer Inputs)**

These scale with the specific configuration:

- **EC2 Compute** – based on the number of cores.
- **EBS Storage** – based on total GB of storage needed.
- **Amazon Managed Prometheus (AMP)** – for monitoring nodes.

We optimize the processing nodes, and we also deploy additional consistency nodes to coordinate actions across the platform. As more systems are added, these nodes increase, raising resource usage.

- We calculate the total number of cores by multiplying the number of servers by the number of cores per server.
  - AWS charges a per-core rate for compute usage.
- We use the number of systems to determine how many processing nodes are needed.
  - Based on the number of nodes and storage per node (in GB), we estimate the total storage required.
  - AWS charges a per-GB rate for total storage usage.
- We also use the number of systems to estimate how many metrics will be tracked in Prometheus.
  - AWS charges a per-metric rate for Prometheus monitoring.
- These calculations together form the provisioned variable cost.

#### **3. Consumption Variable Costs (based on Process Runs)**

These costs depend on how much runtime activity your application generates — in other words, this scales dynamically with the number of process runs executed.

- **CloudWatch Logs** – tracks platform activity and grows with how many cores are active.
- **Data Transfer** – covers communication between different AWS services used by the platform.

These costs are similar to what you'd see on any cloud platform when users are actively using your application**. Instead of asking you to estimate process runs directly, we simplify the formula by basing these costs on the number of cores you specify.** This makes the estimate more convenient and easier for you to configure, while still reflecting typical traffic-based usage patterns.

- We again use the number of servers and cores per server to determine the total core count.
- From this, we estimate how many process runs the system handles per month\*.
- Using that estimated run count, we calculate usage-based costs for logging (CloudWatch) and data transfer.

**\*** This estimate is based on existing deployments with a typical number of process runs (500 per month)

### **Summary**

The calculator uses your specific configuration and process needs to generate a realistic monthly hosting estimate. You can adjust the inputs to explore trade-offs between performance, high availability, and cost.
