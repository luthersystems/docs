#### **01. We’ll set up a dedicated Cloud account for you**

#### **02. The cloud provider will send you an email with an invite link to create a user account with viewing access.**

To ensure security, isolation, and full transparency, we provision a **completely separate AWS account** for your deployment. This account is **never shared or multi-tenant** — it is **dedicated exclusively to your organization**.

When Luther hosts the platform on your behalf, you are granted **read-only access** to the account, including **full visibility into AWS billing** so you can track usage and costs at any time.

As part of the account setup, we provision and preconfigure the following AWS services:

- **Route53**: Internal DNS records configured for the domain you provide, used to support service discovery across the platform.
- **CloudWatch**: Stores application logs from all services, integrated with alerting and Fluentd log streaming.
- **Managed Grafana**: Pre-integrated with Prometheus for dashboards and real-time monitoring.
- **AWS KMS (Key Management Service)**: Manages encryption keys for all storage and secrets.
- **Amazon S3**: Used for shared resources like Terraform state and backup data.
- **Amazon Managed Prometheus (AMP)**: Collects metrics from the platform and integrates with Grafana.
- **AWS Secrets Manager**: Securely stores credentials, API keys, and sensitive application secrets.

This dedicated account setup gives you a **secure, transparent, and isolated environment**, while allowing the Luther team to operate and maintain the platform on your behalf.
