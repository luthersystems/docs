#### **We are provisioning a fully managed Kubernetes v1.30 cluster with the following configurations to ensure scalability, security, and ease of use.**

We’ve carefully selected this configuration to give you **a secure, production-grade platform** with **high availability and minimal management overhead**. Every decision — from the VM type to the network setup — is made to deliver a reliable, performant foundation so you can focus on building your process logic, not infrastructure.

---

### **Why Kubernetes (EKS)?**

Kubernetes is the leading platform for managing modern applications at scale. We use **Amazon EKS** to orchestrate containers securely and reliably, enabling consistent deployments, automated self-healing, and seamless upgrades — all while abstracting away the complexity of cluster maintenance.

---

### **High Availability by Design**

- **Multi-AZ Deployment**: The cluster is distributed across **multiple availability zones** to ensure resilience against failure in any single zone.
- **HA Controllers**: All critical components (including the ALB Ingress Controller) are deployed in a **high availability configuration**, ensuring that failure in one pod or zone doesn’t disrupt ingress or scheduling.
- **Dedicated VMs**: Each node runs on a dedicated T4g burstable ARM instance in your AWS account, giving you full control and **no noisy neighbors**.

---

### **Security You Don’t Have to Configure**

To meet enterprise-grade security standards, the cluster is configured with the following defaults:

- **Pod-Level IAM Roles**: Fine-grained control over what each pod can access in AWS.
- **RBAC (Role-Based Access Control)**: Least-privilege access enforced throughout the cluster.
- **Read-only volumes and restricted pod capabilities**: Limits what workloads can do at runtime — useful for passing security audits and preventing privilege escalation.
- **Dedicated VPC**: Your cluster runs in its own VPC to isolate traffic from other environments.
- **Network Security Groups (NSGs)**: Enforce **firewall-style rules** within the cluster, controlling pod-to-pod and pod-to-service communication to prevent lateral movement in case of compromise.

---

### **Built-in Observability and Management**

You shouldn't have to bolt on your own monitoring stack — so we've included tools that just work:

- **Prometheus** (via Helm): Tracks cluster and workload metrics; integrates with pre-configured Grafana dashboards and alerts.
- **Fluentd to CloudWatch**: All logs are automatically streamed to CloudWatch for long-term retention, search, and alerting.
- **ExternalDNS**: Automatically manages DNS records in your hosted zone based on Kubernetes service annotations.
- **ALB Ingress Controller** (HA): Dynamically provisions **Application Load Balancers** with TLS certificate management (including automatic issuance and renewal via ACM).

---

### **Essential Kubernetes Components**

- **CoreDNS**: Internal DNS-based service discovery.
- **CSI (Container Storage Interface)**: Dynamically provisions persistent volumes for workloads.
- **CNI (Container Network Interface)**: Enables advanced pod networking with high throughput and security.

---

This setup gives you **a powerful yet opinionated starting point**: secure by default, scalable from day one, and **expandable as your needs grow**.
