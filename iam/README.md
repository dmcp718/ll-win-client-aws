# IAM Configuration

This directory contains Terraform configuration and automation scripts for creating a limited-privilege IAM user for LucidLink Windows client deployments.

## Quick Start

**Recommended: Use the automated setup script**

```bash
cd iam
./setup.sh
```

Follow the prompts to create the IAM user and access keys.

**Alternative: Use Terraform**

```bash
cd iam
terraform init
terraform apply
```

Then create access keys:
```bash
aws iam create-access-key --user-name ll-win-client-deployer
```

## Documentation

**For complete setup instructions, see: [docs/IAM-SETUP.md](../docs/IAM-SETUP.md)**

The comprehensive guide includes:
- Why use an IAM user
- Multiple setup methods
- Testing procedures
- Permissions overview
- Security best practices
- Troubleshooting
- Cleanup instructions

## Files in This Directory

- **`setup.sh`**: Automated IAM user creation script
- **`cleanup.sh`**: Automated IAM user removal script
- **`update-policy.sh`**: Update IAM policy script
- **`ll-win-client-user-policy.json`**: IAM policy document
- **`main.tf`**: Terraform configuration for IAM user
- **`QUICKSTART.md`**: Legacy quick start guide (see docs/IAM-SETUP.md instead)

## Support

- **Full Documentation**: [docs/IAM-SETUP.md](../docs/IAM-SETUP.md)
- **Main README**: [../README.md](../README.md)
- **GitHub Issues**: https://github.com/dmcp718/ll-win-client-aws/issues

---

**Last Updated**: 2025-11-02
