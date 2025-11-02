# Deployment Guide

Complete step-by-step guide for deploying Windows Server instances with LucidLink client on AWS.

**[← Back to Main README](../README.md)**

---

## Table of Contents

- [Before You Begin](#before-you-begin)
- [Configuration Wizard](#configuration-wizard)
- [Understanding the Deployment](#understanding-the-deployment)
- [Deployment Process](#deployment-process)
- [Accessing Your Instances](#accessing-your-instances)
- [Password Management](#password-management)
- [Monitoring Deployment Status](#monitoring-deployment-status)
- [Managing Your Deployment](#managing-your-deployment)
- [Cost Management](#cost-management)
- [Cleanup](#cleanup)

---

## Before You Begin

### Prerequisites Checklist

- ✅ AWS account with appropriate permissions (or IAM user configured)
- ✅ NVIDIA RTX Virtual Workstation AMI subscription (see [IAM Setup Guide](IAM-SETUP.md))
- ✅ Python 3.8+ with `uv` package manager
- ✅ Terraform 1.2+ installed
- ✅ AWS CLI v2 installed
- ✅ LucidLink credentials ready (filespace domain, username, password)

### What Gets Deployed

When you deploy, Terraform creates:

**Networking:**
- 1 VPC with custom CIDR block
- 1 Public subnet
- 1 Internet Gateway
- 1 Route table with internet route

**Compute:**
- N × Windows Server 2022 instances (you choose 1-10)
- GPU support (NVIDIA T4 GPUs on G4dn instance types)
- EC2 launch template with encrypted EBS volumes
- Security group with DCV (port 8443) and SSM access

**IAM:**
- Instance role for Windows clients
- Policies for Secrets Manager, CloudWatch, SSM

**Storage & Secrets:**
- AWS Secrets Manager secret for LucidLink credentials
- CloudWatch log group for instance logs (`/aws/ec2/ll-win-client`)

**Estimated Time**: 10-15 minutes for deployment

---

## Configuration Wizard

### Step 1: Start the Script

```bash
# From repository root
uv run ll-win-client-aws.py
```

### Step 2: Main Menu

You'll see the main menu:

```
1. Configure Client Deployment
2. View Configuration
3. Deploy Client Instances
4. View Deployment Status
5. Regenerate Connection Files (DCV)
6. Destroy Client Instances
7. Exit
```

### Step 3: Configure Deployment (Option 1)

The wizard will guide you through:

#### AWS Configuration
- **Region**: Select your deployment region (e.g., `us-east-1`, `us-west-2`, `eu-west-1`)
- **Access Key ID**: Your IAM user's access key
- **Secret Access Key**: Your IAM user's secret key
- **VPC CIDR**: Network range (default: `10.0.0.0/16`)

#### LucidLink Configuration
- **Filespace Domain**: Your LucidLink filespace (e.g., `myspace.lucidlink.com`)
- **Username**: Your LucidLink username
- **Password**: Your LucidLink password
- **Mount Point**: Drive letter or path (default: `L:`)
  - Examples: `L:`, `Z:`, or `C:\LucidLink`

#### Instance Configuration
- **Instance Type**: Choose GPU-accelerated instance
  - `g4dn.xlarge` (4 vCPU, 16 GB RAM, 1 GPU) - ~$0.50/hour
  - `g4dn.2xlarge` (8 vCPU, 32 GB RAM, 1 GPU) - ~$0.75/hour
  - `g4dn.4xlarge` (16 vCPU, 64 GB RAM, 1 GPU) - ~$1.20/hour
- **Number of Instances**: 1-10 instances
- **Root Volume Size**: 30-1000 GB (default: 100 GB)
- **SSH Key** (optional): Leave blank for automated SSM password setup

### Step 4: Review Configuration (Option 2)

Before deploying, review your configuration to ensure everything is correct.

---

## Understanding the Deployment

### What Happens During Deployment

1. **Terraform Initialization** (first run only)
   - Downloads AWS provider
   - Initializes state management

2. **Infrastructure Creation** (~5-8 minutes)
   - Creates VPC and networking
   - Launches Windows instances
   - Configures security groups
   - Creates IAM roles
   - Stores secrets in Secrets Manager

3. **Instance Initialization** (~5-10 minutes)
   - Windows boots and configures
   - AWS CLI installed
   - Amazon DCV server installed
   - LucidLink client downloaded and installed
   - Filespace mounted automatically
   - Services configured for auto-start

4. **Post-Deployment** (~2-3 minutes)
   - Script polls for instance readiness
   - Sets Windows Administrator password via SSM
   - Generates DCV connection files
   - Saves files to Desktop

**Total Time**: ~12-20 minutes

---

## Deployment Process

### Deploy (Option 3 from Main Menu)

1. Select **"3. Deploy Client Instances"** from main menu

2. **Terraform Plan** - Review changes:
   ```
   Plan: 15 to add, 0 to change, 0 to destroy
   ```

3. **Confirm Deployment** - Type `yes` when ready

4. **Watch Progress** - The script will:
   - Show Terraform output
   - Display instance creation progress
   - Poll for instance status
   - Set passwords automatically
   - Generate connection files

5. **Completion** - You'll see:
   ```
   ═══════════════════════════════════════════════════════════
   Connection Files Generated
   ═══════════════════════════════════════════════════════════

   Amazon DCV Connection
   Location: ~/Desktop/LucidLink-DCV/

   Files created:
   - ll-win-client-1.dcv
   - ll-win-client-2.dcv
   - PASSWORDS.txt
   ```

---

## Accessing Your Instances

### Using Amazon DCV (Recommended)

**First-Time Setup** (one-time):

1. **Download DCV Client**
   - Visit: https://download.nice-dcv.com/
   - Choose your OS (Windows, macOS, or Linux)
   - Install the client

2. **Connect to Instance**
   - Open: `~/Desktop/LucidLink-DCV/`
   - Double-click the `.dcv` file for your instance
   - When prompted:
     - **Username**: `Administrator`
     - **Password**: Auto-filled or see `PASSWORDS.txt`

**Why Amazon DCV?**
- ✅ GPU-accelerated graphics rendering
- ✅ Optimized for Adobe Creative Cloud
- ✅ Smoother video playback
- ✅ Better color accuracy
- ✅ QUIC protocol for high-latency networks
- ✅ TLS encryption

**DCV Connection Settings:**
- Protocol: HTTPS (port 8443)
- Session: Console (automatic)
- Video codec: H.264 (hardware-accelerated)
- Authentication: Windows authentication
- Display: Windowed (changeable to fullscreen)
- GPU acceleration: Enabled (NVIDIA T4)

**Performance Tips:**
- Use wired ethernet for best performance
- Close unnecessary local applications
- Enable "High Color Accuracy" for color-critical work
- Use fullscreen mode for immersive experience

### Using AWS Systems Manager (SSM)

For command-line access without GUI:

```bash
# Start interactive PowerShell session
aws ssm start-session --target <instance-id> --region <your-region>
```

**Benefits:**
- No inbound ports required
- Secure access through AWS API
- Useful for troubleshooting
- Can run commands remotely

---

## Password Management

### 🤖 Automated Password Setup (Default)

**How It Works:**
1. Script generates ONE secure 16-character password
2. Uses AWS SSM to set the SAME password on all instances
3. Displays password in terminal
4. Saves to: `~/Desktop/LucidLink-DCV/PASSWORDS.txt`

**Benefits:**
- ✅ No EC2 key pair required
- ✅ Fully automated
- ✅ ONE password for all instances (easy for demos)
- ✅ Works 5-10 minutes after instance launch
- ✅ Secure random password

**If SSM Isn't Ready Yet:**
- Wait 5-10 minutes for instance initialization
- Run the script again
- Choose **Menu Option 5: Regenerate Connection Files**
- Passwords will be set automatically

### 🔑 SSH Key Method (Alternative)

If you configured an SSH key during deployment:

1. Script will prompt to retrieve the Windows password
2. Provide path to your private key file (default: `~/.ssh/<key-name>.pem`)
3. Password will be decrypted and saved to: `~/Desktop/LucidLink-DCV/PASSWORDS.txt`

**Manual Password Retrieval:**
```bash
aws ec2 get-password-data \
  --instance-id <instance-id> \
  --priv-launch-key ~/.ssh/your-key.pem \
  --region <your-region> \
  --query 'PasswordData' \
  --output text | base64 --decode | openssl rsautl -decrypt -inkey ~/.ssh/your-key.pem
```

---

## Monitoring Deployment Status

### View Status (Option 4 from Main Menu)

Shows:
- Instance IDs
- Public/Private IPs
- Instance states
- SSM commands
- DCV connection info

**Example Output:**
```
Instance IDs: i-0123456789abcdef0, i-0fedcba9876543210
Public IPs: 54.123.45.67, 54.123.45.68
Private IPs: 10.0.1.10, 10.0.1.11
```

### Checking Instance Initialization

**On the Windows instance (via SSM):**
```powershell
# View initialization log
Get-Content C:\lucidlink-init.log

# Check LucidLink status
PowerShell -File C:\Scripts\lucidlink-status.ps1

# Verify mount point
Test-Path L:\
Get-ChildItem L:\
```

### Check LucidLink Service

```powershell
Get-Service -Name "Lucid"
Restart-Service -Name "Lucid"
```

---

## Managing Your Deployment

### Regenerate Connection Files (Option 5)

Use this when:
- Lost your connection files
- Need to reset passwords
- SSM wasn't ready during initial deployment

**What It Does:**
1. Retrieves current instance information
2. Generates new secure passwords
3. Sets passwords on all instances via SSM
4. Creates new DCV connection files
5. Saves files to Desktop

### View Configuration (Option 2)

Displays your current configuration without making changes:
- AWS settings
- LucidLink credentials (masked)
- Instance configuration
- Network settings

### Configuration Storage

Your configuration is stored at:
```
~/.ll-win-client/config.json
```

**Note**: Passwords are base64-encoded (basic obfuscation, not encrypted). Keep this file secure.

---

## Cost Management

### Estimated Hourly Costs (us-east-1)

**Compute:**
- G4dn.xlarge: ~$0.50/hour
- G4dn.2xlarge: ~$0.75/hour
- G4dn.4xlarge: ~$1.20/hour

**Storage:**
- EBS gp3 100GB: ~$0.01/hour
- Additional GB: ~$0.0001/hour

**Other Costs:**
- Data transfer out: Varies by usage
- Secrets Manager: ~$0.40/month per secret
- CloudWatch Logs: Minimal

### Cost Optimization Tips

- ✅ **Always destroy instances when not in use**
- ✅ Use the script's destroy option (don't leave running)
- ✅ Monitor costs in AWS Cost Explorer
- ✅ Consider smaller instance types for testing
- ✅ Use Terraform to track all resources

### Monitoring Costs

```bash
# View current month costs (if IAM user has CE access)
aws ce get-cost-and-usage \
  --time-period Start=2025-11-01,End=2025-12-01 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --profile ll-win-client
```

---

## Cleanup

### Destroy All Resources (Option 6)

**IMPORTANT**: This removes ALL instances and infrastructure!

1. Select **"6. Destroy Client Instances"** from main menu
2. Terraform will show what will be destroyed
3. Confirm with `yes`
4. Wait for completion (~3-5 minutes)

**What Gets Deleted:**
- All EC2 instances
- VPC and networking components
- Security groups
- IAM roles and instance profiles
- Secrets Manager secrets
- CloudWatch log groups

**What Remains:**
- Your local configuration at `~/.ll-win-client/config.json`
- Connection files on Desktop (manually delete if desired)
- IAM user (must be deleted separately - see [IAM Setup Guide](IAM-SETUP.md))

### Manual Cleanup (if needed)

```bash
cd terraform/clients
terraform destroy -auto-approve
```

### Cleaning Up Desktop Files

```bash
rm -rf ~/Desktop/LucidLink-DCV/
```

---

## Next Steps

- **Troubleshooting**: See [Troubleshooting Guide](TROUBLESHOOTING.md) for common issues
- **IAM Management**: See [IAM Setup Guide](IAM-SETUP.md) for IAM user management
- **GitHub Issues**: https://github.com/dmcp718/ll-win-client-aws/issues

---

**Related Documentation:**
- [Main README](../README.md)
- [IAM Setup Guide](IAM-SETUP.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md) *(coming soon)*

**Last Updated**: 2025-11-02
