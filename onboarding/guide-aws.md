This guide provides step-by-step instructions for creating an AWS account to deploy the Luther Platform in your environment.

#### **01. Sign Up for AWS**

1. Go to the AWS Sign-up Page:
   [https://aws.amazon.com/](https://aws.amazon.com/)
2. Click Create an AWS Account.
3. Enter your account details:

- Root email address: Use a dedicated email address for AWS administration.
- AWS account name: We recommend using a meaningful name, e.g., 'CompanyName-Luther-Platform'.
- Password: Set a strong password.
- Click Continue.

#### **02. Enter Contact Information**

1. Select Business Account (recommended for enterprises).
   - If this is for personal use, you can select Personal Account.
2. Fill in the Company Name, Phone Number, and Address.
3. Click Continue.

#### **03. Payment Information**

1. Enter your billing details (AWS requires a valid credit/debit card).
2. Click Verify and Continue.
   - AWS may place a small authorization charge to verify the card.

#### **04. Identity Verification**

1. Choose a verification method (SMS text message or phone call).
2. Enter your phone number and receive a verification code.
3. Enter the code and click Verify Code.

#### **05. Choose a Support Plan**

AWS provides four support plans:

- Basic (Free) – Recommended for testing or small workloads.
- Developer ($29/month+) – Best for small teams.
- Business ($100/month+) – Recommended for production deployments.
- Enterprise ($15,000/month+) – For large-scale enterprise support.

Select the appropriate plan for your needs and click Continue.

#### **06. Log In to Your AWS Account**

1. Go to the AWS Console:
   [https://aws.amazon.com/console/ ](https://aws.amazon.com/console/)
2. Click Sign In.
3. Enter your root email and password.

#### **07. Secure Your AWS Account (Highly Recommended)**

#### **Enable Multi-Factor Authentication (MFA)**

1. In the AWS Console, go to IAM.
2. Click Users → Select your Root User.
3. Under Security credentials, click Enable MFA.
4. Follow the instructions to set up an authenticator app (e.g., Google Authenticator, Authy).

#### **Create an Admin IAM User**

Using the root account for daily operations is discouraged.
To create an admin user:

5. In AWS Console, go to IAM → Users.
6. Click Add User.
7. Set User Name (e.g., "AdminUser").
8. Select AWS Management Console Access.
9. Set an initial password (enable "Require password reset").
10. Click Next: Permissions → Choose AdministratorAccess.
11. Click Create User.

Use this IAM user for daily AWS operations.
