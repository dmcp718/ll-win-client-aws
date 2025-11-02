# IAM User Setup Guide

Complete guide for creating a secure, limited-privilege IAM user for LucidLink Windows client deployments.

**[← Back to Main README](../README.md)**

---

## Table of Contents

- [Why Use an IAM User?](#why-use-an-iam-user)
- [Prerequisites](#prerequisites)
- [Quick Setup (Recommended)](#quick-setup-recommended)
- [Manual Setup Methods](#manual-setup-methods)
- [Testing Your Setup](#testing-your-setup)
- [Using with Deployment Script](#using-with-deployment-script)
- [Permissions Overview](#permissions-overview)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)

---

## Why Use an IAM User?

Instead of using your admin AWS credentials, this dedicated IAM user provides:

- ✅ **Security**: Limited permissions following the principle of least privilege
- ✅ **Flexibility**: Works in any AWS region you choose
- ✅ **Isolation**: Can't access S3, RDS, Lambda, or other unrelated services
- ✅ **Safety**: Can't modify your main AWS account settings or billing
- ✅ **Best Practice**: Follows AWS security recommendations

### What Can This User Do?

**✅ Allowed in any AWS region:**
- Create/destroy EC2 instances (Windows Server 2022)
- Manage VPCs, subnets, security groups, route tables
- Set Windows passwords via AWS Systems Manager (SSM)
- Connect to instances via SSM Session Manager
- Store LucidLink credentials in Secrets Manager
- Create CloudWatch log groups
- Create limited IAM roles for EC2 instances (prefixed with `ll-win-client-*`)

**❌ Not Allowed:**
- Create IAM users or broad IAM policies
- Access S3, RDS, Lambda, ECS, EKS, or other non-EC2 services
- Modify billing or account settings
- Delete or modify resources outside the `ll-win-client-*` namespace

---

## Prerequisites

### 1. AWS Marketplace Subscription (One-Time)

Before setting up the IAM user, **subscribe to the NVIDIA RTX Virtual Workstation AMI**:

1. Visit: https://aws.amazon.com/marketplace/pp/prodview-f4reygwmtxipu
2. Click **"Continue to Subscribe"**
3. Accept the terms (No additional software fees - free with G4dn instances)
4. Wait for confirmation (usually 1-2 minutes)

> **Note**: This is a one-time subscription per AWS account. The AMI includes pre-installed NVIDIA GRID/RTX drivers optimized for Adobe Creative Cloud. You only pay for the EC2 instance cost.

### 2. Local Tools

- AWS CLI v2 installed and configured with admin credentials
- Terraform 1.2+ (optional, for Terraform method)

---

## Quick Setup (Recommended)

**Fastest path to get started - approximately 5 minutes:**

### Step 1: Navigate to IAM directory

```bash
cd iam
```

### Step 2: Run the setup script

```bash
./setup.sh
```

The script will:
1. Create the IAM user `ll-win-client-deployer`
2. Attach the limited-permissions policy
3. Optionally create access keys
4. Optionally configure AWS CLI profile

**Save the Access Key ID and Secret Access Key shown at the end!**

### Step 3: Test the credentials

```bash
aws sts get-caller-identity --profile ll-win-client
```

Expected output:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/ll-win-client/ll-win-client-deployer"
}
```

### Step 4: Run the deployment script

```bash
cd ..
uv run ll-win-client-aws.py
```

When prompted, enter the Access Key ID and Secret Access Key from Step 2.

**Done!** → Skip to [Using with Deployment Script](#using-with-deployment-script)

---

## Manual Setup Methods

Choose one method if you prefer not to use the automated script.

### Method 1: Terraform (Infrastructure as Code)

**Benefits**: Declarative, version-controlled, repeatable

**Step 1: Initialize Terraform**
```bash
cd iam
terraform init
```

**Step 2: Review the plan**
```bash
terraform plan
```

**Step 3: Create the IAM user**
```bash
terraform apply
```

**Step 4: Create access keys manually**
```bash
aws iam create-access-key --user-name ll-win-client-deployer
```

Save the output:
- `AccessKeyId`
- `SecretAccessKey`

**Step 5: Configure AWS CLI profile (optional)**
```bash
aws configure --profile ll-win-client
# Enter Access Key ID
# Enter Secret Access Key
# Default region: (your choice, e.g., us-west-2)
# Default output format: json
```

---

### Method 2: AWS CLI

**Benefits**: No Terraform required, pure AWS CLI

**Step 1: Create the IAM user**
```bash
aws iam create-user --user-name ll-win-client-deployer --path /ll-win-client/
```

**Step 2: Create the IAM policy**
```bash
aws iam create-policy \
  --policy-name ll-win-client-deployer-policy \
  --path /ll-win-client/ \
  --policy-document file://ll-win-client-user-policy.json
```

**Step 3: Attach policy to user**
```bash
# Replace ACCOUNT_ID with your AWS account ID
export POLICY_ARN="arn:aws:iam::ACCOUNT_ID:policy/ll-win-client/ll-win-client-deployer-policy"

aws iam attach-user-policy \
  --user-name ll-win-client-deployer \
  --policy-arn $POLICY_ARN
```

**Step 4: Create access keys**
```bash
aws iam create-access-key --user-name ll-win-client-deployer
```

**Step 5: Configure AWS CLI profile (optional)**
```bash
aws configure --profile ll-win-client
# Enter credentials from step 4
```

---

## Testing Your Setup

After creating the IAM user, verify the permissions are working correctly:

### Test 1: Verify Identity
```bash
aws sts get-caller-identity --profile ll-win-client
```

**Expected**: Shows `ll-win-client-deployer` user ARN ✓

### Test 2: List EC2 Instances (Any Region)
```bash
aws ec2 describe-instances --region us-west-2 --profile ll-win-client
aws ec2 describe-instances --region us-east-1 --profile ll-win-client
aws ec2 describe-instances --region eu-west-1 --profile ll-win-client
```

**Expected**: Returns instance list for each region (may be empty) ✓

### Test 3: Try S3 Access (Should Fail)
```bash
aws s3 ls --profile ll-win-client
```

**Expected**: Access Denied error ✓

If all tests pass, your IAM user is configured correctly!

---

## Using with Deployment Script

Once you have the IAM user's access keys:

```bash
# From the repository root
uv run ll-win-client-aws.py
```

**When prompted:**
1. **AWS Region**: Enter your desired region (e.g., `us-west-2`, `us-east-1`, `eu-west-1`, `ap-southeast-1`)
2. **AWS Access Key ID**: Enter the Access Key ID from IAM user creation
3. **AWS Secret Access Key**: Enter the Secret Access Key from IAM user creation

The script will save these credentials locally in:
```
~/.ll-win-client/config.json
```

**Security Note**: This file contains base64-encoded credentials (not encrypted). Keep it secure or delete after use.

---

## Permissions Overview

### EC2 Permissions
- Full instance lifecycle management (run, stop, start, terminate)
- Network management (VPC, subnets, internet gateways, route tables)
- Security group management
- Key pair management
- AMI discovery (read-only)
- Password retrieval via GetPasswordData

### SSM Permissions
- Send commands to instances (for password setting)
- Get command execution status
- Start/terminate SSM sessions
- Describe instance information

### IAM Permissions (Limited)
- Create/delete roles for EC2 instances (must match pattern: `ll-win-client-*` or `tc-*`)
- Create/delete instance profiles (must match pattern: `ll-win-client-*` or `tc-*`)
- Pass roles to EC2 service only

### Secrets Manager Permissions
- Full secret management (must match pattern: `ll-win-client-*` or `tc-*`)
- Used for storing LucidLink credentials

### CloudWatch Logs Permissions
- Create/delete log groups (must match pattern: `/aws/ec2/ll-win-client-*` or `/aws/ec2/tc-*`)
- Set log retention policies

### Resource Naming Conventions

This IAM user can only manage resources with specific naming patterns:

| Resource Type | Required Prefix |
|---------------|----------------|
| IAM Roles | `ll-win-client-*` or `tc-*` |
| IAM Instance Profiles | `ll-win-client-*` or `tc-*` |
| Secrets Manager Secrets | `ll-win-client-*` or `tc-*` |
| CloudWatch Log Groups | `/aws/ec2/ll-win-client-*` or `/aws/ec2/tc-*` |

**Why?** This prevents the user from accidentally modifying unrelated AWS resources.

---

## Security Best Practices

### ✅ DO:
- Store access keys in a password manager (1Password, LastPass, etc.)
- Rotate access keys regularly (every 90 days)
- Use AWS CloudTrail to monitor API calls
- Delete access keys when no longer needed
- Use MFA on the root account that created this user
- Keep `~/.ll-win-client/config.json` secure

### ❌ DON'T:
- Commit access keys to Git repositories
- Share access keys via email or chat
- Store access keys in plaintext files
- Use root account credentials for deployments
- Give this user broader permissions

### 🔒 Emergency Response

If credentials are compromised:

```bash
# List access keys
aws iam list-access-keys --user-name ll-win-client-deployer

# Delete compromised key
aws iam delete-access-key --user-name ll-win-client-deployer --access-key-id AKIAXXXXXXXX

# Create new key
aws iam create-access-key --user-name ll-win-client-deployer
```

---

## Troubleshooting

### Error: "User is not authorized to perform: ec2:RunInstances"

**Cause**: Missing IAM permissions or policy not attached

**Solution**: Verify the policy is attached:
```bash
aws iam list-attached-user-policies --user-name ll-win-client-deployer
```

---

### Error: "User is not authorized to perform: iam:CreateRole"

**Cause**: IAM role name doesn't match required pattern

**Solution**: Ensure role names start with `ll-win-client-` or `tc-`. The Terraform configuration should automatically handle this.

---

### Error: "User is not authorized to perform: secretsmanager:CreateSecret"

**Cause**: Secret name doesn't match required pattern

**Solution**: Ensure secret names start with `ll-win-client-` or `tc-`. The deployment script should automatically handle this.

---

### Access keys not working

**Verify**:
```bash
aws sts get-caller-identity --profile ll-win-client
```

**Check**: Credentials in `~/.aws/credentials` under `[ll-win-client]` profile

**Recreate**: If needed, delete and create new access key

---

## Cleanup

When you no longer need the IAM user:

### Using Cleanup Script

```bash
cd iam
./cleanup.sh
```

This removes:
- IAM user
- IAM policy
- All access keys
- AWS CLI profile (optional)

---

### Using Terraform

```bash
cd iam
terraform destroy
```

---

### Using AWS CLI

```bash
# List and delete access keys first
aws iam list-access-keys --user-name ll-win-client-deployer
aws iam delete-access-key --user-name ll-win-client-deployer --access-key-id AKIAXXXXXXXXXXXXXXXX

# Detach policy
aws iam detach-user-policy \
  --user-name ll-win-client-deployer \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/ll-win-client/ll-win-client-deployer-policy

# Delete policy
aws iam delete-policy \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/ll-win-client/ll-win-client-deployer-policy

# Delete user
aws iam delete-user --user-name ll-win-client-deployer
```

---

## Cost Monitoring

This IAM user has read-only access to Cost Explorer:

```bash
# View current month costs
aws ce get-cost-and-usage \
  --time-period Start=2025-11-01,End=2025-12-01 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --profile ll-win-client
```

---

## Support

For issues or questions:
1. Check CloudTrail logs for denied API calls
2. Review IAM policy in `iam/ll-win-client-user-policy.json`
3. Test permissions using AWS Policy Simulator
4. Open an issue: https://github.com/dmcp718/ll-win-client-aws/issues

---

**Related Documentation:**
- [Main README](../README.md)
- [Deployment Guide](DEPLOYMENT-GUIDE.md) *(coming soon)*
- [Troubleshooting Guide](TROUBLESHOOTING.md) *(coming soon)*

**Last Updated**: 2025-11-02 | **Policy Version**: 1.0
