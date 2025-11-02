# LucidLink Windows Client - AWS Deployment

Automated deployment tool for Windows Server instances with LucidLink client on AWS.

GitHub Repository: https://github.com/dmcp718/ll-win-client-aws.git

## Overview

This project provides an interactive TUI (Terminal User Interface) for deploying Windows Server 2022 instances with the LucidLink client pre-configured. Perfect for demonstrations, temporary cloud workstations, and remote GPU-accelerated workflows.

## Features

- **Interactive Configuration Wizard**: Step-by-step setup for all deployment parameters
- **Windows Server 2022 with GPU Support**: NVIDIA RTX Virtual Workstation AMI with pre-installed GRID/RTX drivers
- **GPU-Accelerated Graphics**: G4dn instance types with NVIDIA T4 GPUs for Adobe Creative Cloud compatibility
- **Amazon DCV Remote Access**: High-performance remote desktop with GPU-accelerated graphics
- **LucidLink Integration**: Automatic installation and configuration of LucidLink Windows client
- **Automatic Connection Files**: Pre-configured .dcv files saved directly to Desktop
- **🤖 Automated Password Setup**: No SSH key needed! Uses AWS SSM to set secure passwords automatically
- **Windows Password Management**: Automatic generation, setting, and saving of Administrator passwords
- **AWS Secrets Manager**: Secure credential storage for LucidLink authentication
- **SSM Session Manager**: Automated password setting via AWS Systems Manager
- **Standalone VPC**: Self-contained networking with Internet Gateway
- **Multi-Instance Support**: Deploy 1-10 instances simultaneously
- **Rich TUI**: Beautiful terminal interface with progress tracking

## Requirements

### AWS Marketplace Subscription (One-Time Setup)

Before first deployment, subscribe to the **NVIDIA RTX Virtual Workstation AMI** (free, no additional charges):
- Visit: https://aws.amazon.com/marketplace/pp/prodview-f4reygwmtxipu
- Click "Continue to Subscribe" and accept terms
- This enables GPU-accelerated graphics for Adobe Creative Cloud

### Local Machine

- **Python 3.8+** with `uv` package manager
- **Python Libraries**: rich, boto3, pyyaml, cryptography (auto-installed via uv)
- **Terraform 1.2+**: Infrastructure as Code tool
- **AWS CLI v2**: AWS command-line interface
- **AWS Credentials**: Access Key ID and Secret Access Key with EC2/VPC/Secrets Manager/SSM permissions
- **EC2 Key Pair** (optional): Not required for automated SSM password setup

### AWS Permissions Required

- EC2: Create/manage instances, security groups, key pairs
- VPC: Create/manage VPCs, subnets, internet gateways, route tables
- IAM: Create/manage roles and instance profiles
- Secrets Manager: Create/manage secrets for LucidLink credentials
- CloudWatch: Create log groups
- SSM: Session Manager access, SendCommand (for automated password setup)

## Installation

```bash
# Clone the repository
git clone https://github.com/dmcp718/ll-win-client-aws.git
cd ll-win-client-aws

# Install Python dependencies using uv
uv sync

# Verify Terraform is installed
terraform -version

# Verify AWS CLI is installed
aws --version
```

## Quick Start

### 1. Run the Interactive Setup

```bash
# Start the interactive TUI
uv run ll-win-client-aws.py

# Or with auto-approve (skip confirmation prompts)
uv run ll-win-client-aws.py -y
```

### 2. Configure Deployment

The wizard will guide you through:

1. **AWS Region**: Select your deployment region (default: us-east-1)
2. **AWS Credentials**: Provide Access Key ID and Secret Access Key
3. **VPC Configuration**: Set CIDR block (default: 10.0.0.0/16)
4. **LucidLink Credentials**:
   - Filespace domain (e.g., `myspace.lucidlink.com`)
   - Username
   - Password
   - Mount point (default: `L:`) - Can be a drive letter (L:, Z:) or path (C:\LucidLink)
5. **Instance Configuration**:
   - Instance type (GPU options: g4dn.xlarge, g4dn.2xlarge, g4dn.4xlarge)
   - Number of instances (1-10)
   - Root volume size (30-1000 GB)
6. **SSH Key** (optional): Leave blank for automated SSM password setup

**Note**: SSH key is completely optional! The script will automatically set passwords using AWS Systems Manager.

### 3. Deploy Infrastructure

From the main menu:
- **Option 1**: Configure Client Deployment
- **Option 2**: View Configuration
- **Option 3**: Deploy Client Instances (launches AWS resources)
- **Option 4**: View Deployment Status
- **Option 5**: Destroy Client Instances

## Configuration Storage

Configuration is stored locally at:
```
~/.ll-win-client/config.json
```

Passwords are base64-encoded (not encrypted) for basic obfuscation.

## Project Structure

```
ll-win-client-aws/
├── ll-win-client-aws.py          # Main Python script with TUI
├── pyproject.toml                 # Python dependencies
├── README.md                      # This file
└── terraform/
    └── clients/
        ├── main.tf                # VPC and networking
        ├── variables.tf           # Input variables
        ├── ec2-client.tf          # Windows instances and IAM
        ├── outputs.tf             # Output values
        └── templates/
            └── windows-userdata.ps1  # PowerShell initialization script
```

## Terraform Details

The deployment creates:

### Networking
- 1 VPC with custom CIDR
- 1 Public subnet
- 1 Internet Gateway
- 1 Route table

### Compute
- N × Windows Server 2022 instances (t3.large+ recommended)
- EC2 launch template with encrypted EBS volumes
- Security group with DCV (port 8443) and SSM access

### IAM
- Instance role for Windows clients
- Policies for Secrets Manager, CloudWatch, SSM

### Secrets
- AWS Secrets Manager secret with LucidLink credentials

### Logging
- CloudWatch log group for instance logs

## Instance Initialization

When instances launch, the PowerShell userdata script:

1. **Installs AWS CLI v2** (if not present)
2. **Downloads LucidLink** from specified URL
3. **Installs LucidLink** silently
4. **Retrieves credentials** from AWS Secrets Manager
5. **Mounts filespace** at specified mount point
6. **Configures service** for automatic startup
7. **Creates helper scripts** for status checking

## Accessing Instances

### Amazon DCV Connection

After deployment, the script **automatically generates Amazon DCV connection files** for each instance:

**DCV files location**: `~/Desktop/LucidLink-DCV/`

**First-time setup**:
1. Download the Amazon DCV client from: https://download.nice-dcv.com/
2. Install the DCV client on your local machine (Windows, macOS, or Linux)

**To connect**:
1. Open your Desktop and find the **"LucidLink-DCV"** folder
2. Double-click the `.dcv` file for the instance you want to connect to
3. Enter credentials when prompted:
   - Username: **Administrator**
   - Password: (from PASSWORDS.txt or terminal output)

**File naming**:
- `ll-win-client-1.dcv`
- `ll-win-client-2.dcv`
- etc.

**Why Amazon DCV?**
- ✅ **Superior graphics performance** - Hardware-accelerated GPU rendering
- ✅ **Optimized for Adobe Creative Cloud** - Best performance for graphics-intensive applications
- ✅ **Smoother video playback** - Higher frame rates and lower latency
- ✅ **Professional graphics support** - Better color accuracy
- ✅ **QUIC protocol support** - Better performance over high-latency connections

### Getting the Windows Administrator Password

#### 🤖 Automated Password Setup (Recommended - No SSH Key Required!)

**The script now AUTOMATICALLY sets secure passwords using AWS Systems Manager!**

**During deployment OR when using "Regenerate Connection Files":**
1. Script generates ONE secure 16-character password
2. Uses AWS SSM to set the SAME password on all instances (no SSH key needed)
3. Displays password in terminal
4. Saves to: `~/Desktop/LucidLink-DCV/PASSWORDS.txt`

**Benefits:**
- ✅ No EC2 key pair required
- ✅ Fully automated
- ✅ ONE password for all instances (easy to remember for demos)
- ✅ Works 5-10 minutes after instance launch (when SSM agent is ready)
- ✅ Secure random password
- ✅ No manual steps needed

**If SSM isn't ready yet:**
- Wait 5-10 minutes for instance initialization
- Run the script again
- Choose **Menu Option 5: Regenerate Connection Files**
- Passwords will be set automatically

#### 🔑 SSH Key Method (Alternative)

If you configured an SSH key during deployment:
- Script will prompt to retrieve the Windows password
- Provide path to your private key file (default: `~/.ssh/<key-name>.pem`)
- Password will be decrypted and saved to: `~/Desktop/LucidLink-DCV/PASSWORDS.txt`

#### Manual Password Retrieval (If Needed)

```bash
# Using AWS CLI (requires private key)
aws ec2 get-password-data \
  --instance-id <instance-id> \
  --priv-launch-key ~/.ssh/your-key.pem \
  --region us-east-1 \
  --query 'PasswordData' \
  --output text | base64 --decode | openssl rsautl -decrypt -inkey ~/.ssh/your-key.pem
```

### AWS Systems Manager (Command-Line Access)

For command-line access without GUI:

```bash
# Start interactive PowerShell session
aws ssm start-session --target <instance-id> --region us-east-1
```

### Amazon DCV Connection Settings

The generated DCV files are pre-configured with:
- **Protocol**: HTTPS (port 8443)
- **Session**: Console session (automatic)
- **Video codec**: H.264 (hardware-accelerated)
- **Authentication**: Windows authentication (system)
- **Display**: Windowed mode (can be changed to fullscreen in client)
- **GPU acceleration**: Enabled (NVIDIA T4 GPU)
- **QUIC protocol**: Enabled (for better performance over high-latency networks)

**DCV Performance Tips:**
- Use a wired ethernet connection for best performance
- Close unnecessary applications on your local machine
- For color-critical work, use the "High Color Accuracy" option in DCV client settings
- Enable fullscreen mode in DCV client for immersive experience

## Monitoring and Troubleshooting

### Check Instance Status

From the TUI, use **Option 4: View Deployment Status** to see:
- Instance IDs
- Public/Private IPs
- Instance states
- SSM commands

### View Initialization Logs

On the Windows instance:
```powershell
# View initialization log
Get-Content C:\lucidlink-init.log

# Check LucidLink status
PowerShell -File C:\Scripts\lucidlink-status.ps1

# Verify mount point
Test-Path C:\LucidLink
Get-ChildItem C:\LucidLink
```

### Check LucidLink Service

```powershell
Get-Service -Name "Lucid"
Restart-Service -Name "Lucid"
```

## Cleanup

### Destroy All Resources

From the TUI:
- **Option 5**: Destroy Client Instances

Or manually:
```bash
cd terraform/clients
terraform destroy -auto-approve
```

This will remove:
- All EC2 instances
- VPC and networking components
- Security groups
- IAM roles
- Secrets Manager secrets
- CloudWatch log groups

## Cost Considerations

Estimated hourly costs (us-east-1, as of 2025):
- **t3.large**: ~$0.08/hour
- **t3.xlarge**: ~$0.17/hour
- **m5.large**: ~$0.10/hour
- **EBS gp3 100GB**: ~$0.01/hour

Additional costs:
- Data transfer out
- Secrets Manager (minimal)
- CloudWatch Logs (minimal)

**Always destroy resources when not in use!**

## Limitations

### LucidLink Installer

The script attempts to download LucidLink from:
```
https://www.lucidlink.com/download/latest/windows
```

**Note**: This URL may require adjustment based on LucidLink's actual download mechanism. You may need to:
1. Pre-download the installer
2. Host it on S3
3. Update `lucidlink_installer_url` variable

### Windows License

Windows Server instances require appropriate licensing. AWS provides license-included AMIs (included in instance cost).

## Troubleshooting

### "Terraform not found"
Install Terraform from: https://www.terraform.io/downloads

### "AWS credentials invalid"
Verify your credentials:
```bash
aws sts get-caller-identity
```

### "LucidLink installer not found"
The download URL may need adjustment. Check LucidLink's documentation for the correct Windows installer download link.

### "Instance not accessible"
Wait 5-10 minutes after deployment for Windows initialization to complete.

### "Mount point not accessible"
Check initialization logs on the instance and verify LucidLink service is running.

## Security Notes

- **Passwords**:
  - LucidLink credentials stored base64-encoded locally, encrypted in AWS Secrets Manager
  - Windows passwords saved in plaintext on Desktop (only if retrieved)
  - **Important**: Protect `~/Desktop/LucidLink-DCV/PASSWORDS.txt` - delete after use or store securely
- **DCV Access**:
  - Enabled for GUI connection (port 8443/HTTPS)
  - Restricted to configured CIDR blocks (default: 0.0.0.0/0)
  - **Recommendation**: Restrict `allowed_cidr_blocks` to your IP range for enhanced security
  - Uses TLS encryption for all connections
- **SSM**: Alternative access method (no inbound ports required)
- **Encryption**: All EBS volumes encrypted at rest
- **Firewall**: Security groups restrict traffic by default
- **Private Keys**: Keep EC2 key pairs secure (required for password decryption if using SSH key method)

## Support

For issues:
1. Check CloudWatch logs: `/aws/ec2/ll-win-client`
2. Review instance logs: `C:\lucidlink-init.log`
3. Verify Terraform state: `terraform/clients/terraform.tfstate`
4. Open an issue on GitHub: https://github.com/dmcp718/ll-win-client-aws/issues

## License

MIT License - See LICENSE file for details.

---

**Last Updated**: 2025-02-01
