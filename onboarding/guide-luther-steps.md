This setup ensures Luther Systems can assume the role and deploy the platform while maintaining security through a limited trust relationship.

#### **01. Create a Cross-Account IAM Role**

1. Log into the AWS Management Console as an IAM administrator.
2. Navigate to IAM (Identity and Access Management).
3. Click Roles in the left sidebar.
4. Click Create Role.
5. Under Select trusted entity, choose AWS account.
6. Select Another AWS Account and enter the Luther Systems AWS account ID: 343039485463
7. Under Options, enable Require external ID Set the external ID to the value: luther-platform-deployment-<your_account_id>
8. (Replace <your_account_id> with your AWS account ID.)
9. Click Next.

#### **02. Attach the IAM Policies**

For full admin access, attach the AdministratorAccess managed policy:

1. Click Attach policies directly.
2. In the search bar, type AdministratorAccess and select it.
3. Click Next.

Alternatively, if you want a more restrictive policy (once we review the necessary permissions), you can attach a custom policy.

#### **03. Name and Create the Role**

1. Set the role name to:
2. luther-platform-deployer-admin
3. Click Create Role.
4. After creation, open the new role and copy the Role ARN (e.g., arn:aws:iam::CUSTOMER_ACCOUNT_ID:role/luther-platform-deployer-admin).

#### **04. Allow Luther Systems to Assume This Role**

1.  Go to the role you just created
2.  Click the Trust relationships tab.
3.  Click Edit trust policy.
4.  Replace the policy with the following JSON:

```hcl
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::343039485463:role/plt-or-prod-argo-role-terraform0"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

5.  Click Update policy.

#### **05. Share the Role ARN with Luther Systems**

Send Luther Systems the role ARN so they can assume the role and deploy the platform (e.g., arn:aws:iam::CUSTOMER_ACCOUNT_ID:role/luther-platform-deployer-admin)

#### **Automating This Process with Terraform**

If the customer prefers using Terraform, they can create this role using the following:resource 'aws_iam_role' 'luther_platform_deployer

```hcl
{
  name = "luther-platform-deployer-admin"
  description = "Provides access for Luther Systems to deploy the platform"
  assume_role_policy = data.aws_iam_policy_document.luther_assume_role.json
}

resource "aws_iam_role_policy_attachment" "admin" {
  role = aws_iam_role.luther_platform_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "luther_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::343039485463:role/plt-or-prod-argo-role-terraform0"]
    }
    actions = ["sts:AssumeRole"]
  }
}

The customer can apply this Terraform configuration to automatically create the role.
```
