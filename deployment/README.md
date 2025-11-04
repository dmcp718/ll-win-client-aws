# Windows Client Deployment

Simple, pragmatic deployment solution using AWS SSM direct commands.

## Why This Approach?

After extensive testing, we found that:
- ❌ **UserData scripts** fail due to encoding/line-ending issues
- ❌ **Ansible** has connection plugin compatibility issues
- ✅ **Direct SSM commands** work reliably and simply

## Usage

### Deploy to Instance

```bash
./deploy-windows-client.sh [instance-id] [region]
```

**Example:**
```bash
./deploy-windows-client.sh i-04a97c9efaa7eb3f3 us-east-1
```

### What Gets Installed

1. **AWS CLI v2** - For retrieving credentials from Secrets Manager
2. **Amazon DCV Server** - Remote desktop on port 8443
3. **Google Chrome** - Web browser
4. **LucidLink** - Filespace client with automatic mount configuration

## Architecture

```
┌─────────────────┐
│  Your Terminal  │
└────────┬────────┘
         │ AWS CLI
         ▼
┌─────────────────┐
│  AWS SSM API    │
└────────┬────────┘
         │ SSM Agent
         ▼
┌─────────────────┐
│ Windows EC2     │
│  - Runs commands│
│  - No encoding  │
│  - No files     │
└─────────────────┘
```

## Key Features

- **No file transfers** - All commands inline (no encoding issues)
- **Simple debugging** - Clear command output
- **No dependencies** - Just AWS CLI
- **Idempotent** - Safe to re-run
- **Fast feedback** - See results immediately

## Requirements

- AWS CLI configured with appropriate credentials
- Instance must have SSM agent running (enabled by default on Amazon AMIs)
- Security group must allow outbound HTTPS (for downloads)
- IAM role with SSM permissions

## Troubleshooting

### Check SSM Status
```bash
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=i-xxx" \
  --region us-east-1
```

### View Command Output
```bash
aws ssm get-command-invocation \
  --command-id cmd-xxx \
  --instance-id i-xxx \
  --region us-east-1
```

### Check DCV Manually
```bash
aws ssm send-command \
  --instance-ids i-xxx \
  --region us-east-1 \
  --document-name "AWS-RunPowerShellScript" \
  --parameters 'commands=["Get-Service DCV*","Test-NetConnection -Port 8443 localhost"]'
```

## Integration with Terraform

See `terraform-provisioner.tf` for example of integrating this approach with Terraform `null_resource` provisioners.

## Archived Approaches

- `../ansible/` - Ansible playbook (not used - connection issues)
- `../terraform/clients/templates/` - UserData scripts (not used - encoding issues)

These are kept for reference but not recommended for production use.
