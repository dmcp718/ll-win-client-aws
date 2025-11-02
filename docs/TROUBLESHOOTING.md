# Troubleshooting Guide

Common issues and solutions for LucidLink Windows client deployments on AWS.

**[← Back to Main README](../README.md)**

---

## Table of Contents

- [Prerequisites & Setup Issues](#prerequisites--setup-issues)
- [IAM & Permissions Issues](#iam--permissions-issues)
- [Terraform Issues](#terraform-issues)
- [Deployment Issues](#deployment-issues)
- [Network & Connectivity Issues](#network--connectivity-issues)
- [Amazon DCV Issues](#amazon-dcv-issues)
- [Password Issues](#password-issues)
- [LucidLink Issues](#lucidlink-issues)
- [Instance Issues](#instance-issues)
- [Getting Help](#getting-help)

---

## Prerequisites & Setup Issues

### "Terraform not found"

**Symptoms:**
```
bash: terraform: command not found
```

**Solution:**
Install Terraform from: https://www.terraform.io/downloads

**Verify installation:**
```bash
terraform -version
```

---

### "AWS CLI not found"

**Symptoms:**
```
bash: aws: command not found
```

**Solution:**
Install AWS CLI v2 from: https://aws.amazon.com/cli/

**Verify installation:**
```bash
aws --version
```

---

### "uv: command not found"

**Symptoms:**
```
bash: uv: command not found
```

**Solution:**
Install uv package manager:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

---

## IAM & Permissions Issues

### "AWS credentials invalid"

**Symptoms:**
- Error: "Unable to locate credentials"
- Error: "The security token included in the request is invalid"

**Solution:**
Verify your AWS credentials are configured correctly:

```bash
aws sts get-caller-identity --profile ll-win-client
```

**Expected output:**
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/ll-win-client/ll-win-client-deployer"
}
```

**If this fails:**
1. Check `~/.aws/credentials` file
2. Verify Access Key ID and Secret Access Key are correct
3. Recreate access keys if needed

---

### "User is not authorized to perform: ec2:RunInstances"

**Symptoms:**
```
Error: creating EC2 Instance: UnauthorizedOperation: You are not authorized to perform this operation.
```

**Cause**: Missing IAM permissions or policy not attached

**Solution**:
1. Verify the policy is attached:
```bash
aws iam list-attached-user-policies --user-name ll-win-client-deployer
```

2. Expected output should show `ll-win-client-deployer-policy`

3. If missing, re-attach:
```bash
aws iam attach-user-policy \
  --user-name ll-win-client-deployer \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/ll-win-client/ll-win-client-deployer-policy
```

---

### "User is not authorized to perform: iam:CreateRole"

**Symptoms:**
```
Error: creating IAM Role: AccessDenied: User is not authorized to perform: iam:CreateRole
```

**Cause**: IAM role name doesn't match required pattern

**Solution**:
- Terraform automatically prefixes roles with `ll-win-client-`
- This error should not occur with the default configuration
- If it does, verify the Terraform files haven't been modified
- Check `terraform/clients/ec2-client.tf` for role naming

---

### "User is not authorized to perform: secretsmanager:CreateSecret"

**Symptoms:**
```
Error: creating Secrets Manager Secret: AccessDenied
```

**Cause**: Secret name doesn't match required pattern

**Solution**:
- Terraform automatically prefixes secrets with `ll-win-client/`
- Verify `terraform/clients/ec2-client.tf` hasn't been modified
- Secret path should be: `ll-win-client/lucidlink/${filespace_domain}/credentials`

---

## Terraform Issues

### "Error locking state"

**Symptoms:**
```
Error: Error acquiring the state lock
Error message: ConditionalCheckFailedException
Lock Info: ID: ...
```

**Cause**: Previous Terraform operation was interrupted

**Solution**:
```bash
cd terraform/clients
terraform force-unlock <LOCK_ID>
```

Replace `<LOCK_ID>` with the ID shown in the error message.

---

### "Resource already exists"

**Symptoms:**
```
Error: creating EC2 VPC: VpcLimitExceeded
```
or
```
Error: resource already exists
```

**Cause**: Previous deployment wasn't fully destroyed

**Solution 1: Destroy via Script**
```bash
uv run ll-win-client-aws.py
# Choose Option 6: Destroy Client Instances
```

**Solution 2: Manual Destroy**
```bash
cd terraform/clients
terraform destroy -auto-approve
```

**Solution 3: Check AWS Console**
- Log into AWS Console
- Check for leftover resources in the region
- Manually delete if needed

---

### "No valid credential sources found"

**Symptoms:**
```
Error: error configuring Terraform AWS Provider: no valid credential sources found
```

**Cause**: AWS credentials not configured in Terraform directory

**Solution**:
Run the main script to generate proper Terraform configuration:
```bash
uv run ll-win-client-aws.py
# Choose Option 1: Configure
# Then Option 3: Deploy
```

The script automatically configures Terraform with your AWS credentials.

---

## Deployment Issues

### "AMI not found" or "OptInRequired"

**Symptoms:**
```
Error: creating EC2 Instance: OptInRequired: You are not subscribed to AMI ami-xxxxx
```

**Cause**: Haven't subscribed to NVIDIA RTX Virtual Workstation AMI

**Solution**:
1. Visit: https://aws.amazon.com/marketplace/pp/prodview-f4reygwmtxipu
2. Click "Continue to Subscribe"
3. Accept terms (free, no software fees)
4. Wait 1-2 minutes for confirmation
5. Re-run deployment

---

### "Instance limit exceeded"

**Symptoms:**
```
Error: InstanceLimitExceeded: You have requested more instances than your current instance limit
```

**Cause**: AWS account has default instance limits

**Solution**:
1. Check current limits:
```bash
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region <your-region>
```

2. Request increase via AWS Service Quotas console
3. Or reduce number of instances in deployment

---

### Deployment hangs at "Waiting for instances"

**Symptoms:**
- Script shows "Waiting for instances to be ready..."
- No progress for 10+ minutes

**Cause**: Instance initialization is slow or failed

**Solution 1: Check Instance Status**
```bash
aws ec2 describe-instance-status \
  --instance-ids <instance-id> \
  --region <your-region>
```

**Solution 2: Check System Log**
```bash
aws ec2 get-console-output \
  --instance-id <instance-id> \
  --region <your-region>
```

**Solution 3: Wait Longer**
- Windows Server initialization can take 15-20 minutes
- Be patient, especially on first boot

---

## Network & Connectivity Issues

### Can't connect to DCV server

**Symptoms:**
- DCV client shows "Connection failed"
- "Unable to connect to server"

**Check 1: Instance is Running**
```bash
aws ec2 describe-instances \
  --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].State.Name' \
  --region <your-region>
```

**Check 2: Security Group Rules**
```bash
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=ll-win-client-sg" \
  --region <your-region>
```

Verify port 8443 is open.

**Check 3: DCV Service Running**
Connect via SSM and check:
```powershell
Get-Service -Name "DCV Server"
```

**Solution**: Restart DCV service if needed:
```powershell
Restart-Service -Name "DCV Server"
```

---

### Firewall blocking connection

**Symptoms:**
- Connection times out
- "Connection refused"

**Solution**:
1. Check your local firewall allows outbound HTTPS (port 8443)
2. Try from a different network
3. Check corporate VPN isn't blocking

---

### Public IP not accessible

**Symptoms:**
- Can't ping or connect to public IP

**Check Internet Gateway:**
```bash
aws ec2 describe-internet-gateways \
  --filters "Name=attachment.vpc-id,Values=<vpc-id>" \
  --region <your-region>
```

**Check Route Table:**
```bash
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=<vpc-id>" \
  --region <your-region>
```

Verify there's a route to `0.0.0.0/0` via the Internet Gateway.

---

## Amazon DCV Issues

### DCV client not installed

**Symptoms:**
- Can't open `.dcv` files

**Solution**:
Download and install DCV client:
- Visit: https://download.nice-dcv.com/
- Choose your OS (Windows, macOS, Linux)
- Install the client
- Retry opening the `.dcv` file

---

### Black screen in DCV

**Symptoms:**
- DCV connects but shows black screen
- No desktop visible

**Cause**: GPU driver issues or DCV not fully initialized

**Solution 1: Wait**
- Windows may still be initializing
- Wait 5 more minutes and retry

**Solution 2: Reconnect**
- Disconnect DCV
- Wait 30 seconds
- Reconnect

**Solution 3: Restart DCV Server**
Connect via SSM:
```powershell
Restart-Service -Name "DCV Server"
```

---

### Poor DCV performance

**Symptoms:**
- Laggy cursor
- Choppy video
- High latency

**Solution 1: Check Network**
- Use wired ethernet instead of WiFi
- Close bandwidth-heavy applications
- Check internet speed

**Solution 2: DCV Settings**
- In DCV client, go to Settings
- Try different video codec settings
- Enable "Prefer performance over quality"

**Solution 3: Instance Size**
- Consider larger instance type (g4dn.2xlarge or g4dn.4xlarge)
- More CPU/RAM helps with encoding

---

## Password Issues

### Password not working

**Symptoms:**
- DCV prompts for password but it's rejected
- "Invalid credentials"

**Solution 1: Check PASSWORDS.txt**
```bash
cat ~/Desktop/LucidLink-DCV/PASSWORDS.txt
```

**Solution 2: Regenerate Password**
```bash
uv run ll-win-client-aws.py
# Choose Option 5: Regenerate Connection Files
```

**Solution 3: Manual Password Reset**
Connect via SSM and reset:
```powershell
$Password = ConvertTo-SecureString "YourNewPassword123!" -AsPlainText -Force
Set-LocalUser -Name "Administrator" -Password $Password
```

---

### SSM password setting failed

**Symptoms:**
```
⚠ Could not set password via SSM: InvalidInstanceId
```

**Cause**: SSM agent not ready yet

**Solution**:
1. Wait 5-10 minutes for instance to fully initialize
2. Run script again
3. Choose **Option 5: Regenerate Connection Files**
4. Script will retry password setting

---

### Can't decrypt password (SSH key method)

**Symptoms:**
```
Error: Failed to decrypt password
```

**Cause**: Wrong private key file or key format issue

**Solution 1: Verify Key Path**
```bash
ls -l ~/.ssh/<key-name>.pem
```

**Solution 2: Check Key Permissions**
```bash
chmod 400 ~/.ssh/<key-name>.pem
```

**Solution 3: Use SSM Method Instead**
- Don't configure SSH key during setup
- Let script use automated SSM password method

---

## LucidLink Issues

### LucidLink installer not found

**Symptoms:**
- Instance log shows "LucidLink installer download failed"

**Cause**: Download URL may have changed

**Check Logs:**
Connect via SSM:
```powershell
Get-Content C:\lucidlink-init.log
```

**Solution**:
- Check LucidLink's actual download URL
- May need to update `terraform/clients/templates/windows-userdata.ps1`
- Or manually install LucidLink after deployment

---

### Mount point not accessible

**Symptoms:**
- Can't access `L:\` drive
- LucidLink service not running

**Check Service:**
```powershell
Get-Service -Name "Lucid"
```

**Check Mount:**
```powershell
Test-Path L:\
```

**View Logs:**
```powershell
Get-Content C:\lucidlink-init.log
```

**Solution 1: Restart Service**
```powershell
Restart-Service -Name "Lucid"
```

**Solution 2: Re-mount**
```powershell
# Check current mounts
lucid status

# Remount if needed
lucid mount --fs <filespace> --user <username> --password <password> L:
```

---

### LucidLink credentials incorrect

**Symptoms:**
- Mount fails with "Authentication failed"

**Solution**:
1. Verify credentials in AWS Secrets Manager:
```bash
aws secretsmanager get-secret-value \
  --secret-id ll-win-client/lucidlink/<filespace>/credentials \
  --region <your-region>
```

2. Update if incorrect:
   - Run script → Option 1: Configure
   - Enter correct credentials
   - Redeploy (Option 3)

---

## Instance Issues

### Instance not accessible after 20 minutes

**Symptoms:**
- SSM Session Manager fails
- DCV can't connect
- No response

**Check Instance Status:**
```bash
aws ec2 describe-instance-status \
  --instance-ids <instance-id> \
  --region <your-region>
```

**Check System Log:**
```bash
aws ec2 get-console-output \
  --instance-id <instance-id> \
  --region <your-region>
```

**Solution**:
- If status checks are failing, instance may be unhealthy
- Try stopping and starting (not rebooting):
```bash
aws ec2 stop-instances --instance-ids <instance-id> --region <your-region>
# Wait a minute
aws ec2 start-instances --instance-ids <instance-id> --region <your-region>
```

---

### Instance terminated unexpectedly

**Symptoms:**
- Instance no longer appears in AWS console
- Terraform shows instance destroyed

**Check CloudTrail:**
```bash
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=<instance-id> \
  --region <your-region>
```

**Possible Causes:**
- Manual termination
- Auto-scaling policy (shouldn't be configured)
- Spot instance interruption (if using spot)

**Solution**:
Re-deploy using the script.

---

### Running out of disk space

**Symptoms:**
- `C:\` drive full
- Applications failing to start

**Check Disk Space:**
```powershell
Get-PSDrive C
```

**Solution 1: Increase Volume Size**
1. Destroy current deployment
2. Reconfigure with larger root volume
3. Redeploy

**Solution 2: Clean Up**
```powershell
# Clean temp files
Remove-Item C:\Windows\Temp\* -Recurse -Force

# Clean Windows Update files
DISM.exe /online /Cleanup-Image /StartComponentCleanup
```

---

## Getting Help

### CloudWatch Logs

Check instance logs:
```bash
aws logs tail /aws/ec2/ll-win-client \
  --since 1h \
  --follow \
  --region <your-region>
```

### Terraform State

View current infrastructure:
```bash
cd terraform/clients
terraform show
```

### Instance Logs

View initialization log:
```powershell
Get-Content C:\lucidlink-init.log -Tail 50
```

### Support Resources

1. **Check Terraform state**: `terraform/clients/terraform.tfstate`
2. **Review CloudWatch logs**: `/aws/ec2/ll-win-client`
3. **Instance logs**: `C:\lucidlink-init.log` (via SSM)
4. **Open GitHub issue**: https://github.com/dmcp718/ll-win-client-aws/issues
5. **AWS Support**: For AWS-specific issues

---

## Emergency Procedures

### Complete Reset

If everything is broken and you want to start fresh:

```bash
# 1. Destroy all infrastructure
cd terraform/clients
terraform destroy -force

# 2. Remove local config
rm -rf ~/.ll-win-client/

# 3. Remove Terraform state
rm -f terraform.tfstate*
rm -rf .terraform/

# 4. Start over
cd ../..
uv run ll-win-client-aws.py
```

---

**Related Documentation:**
- [Main README](../README.md)
- [IAM Setup Guide](IAM-SETUP.md)
- [Deployment Guide](DEPLOYMENT-GUIDE.md)

**Last Updated**: 2025-11-02
