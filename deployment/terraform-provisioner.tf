#
# Terraform Provisioner - SSM-based Windows Configuration
#
# This demonstrates how to integrate the SSM deployment approach
# with Terraform for repeatable deployments
#

resource "null_resource" "configure_windows_client" {
  # Trigger when instance is replaced or variables change
  triggers = {
    instance_id       = aws_instance.windows_client[0].id
    filespace_domain  = var.filespace_domain
    configuration_version = "1.0"  # Increment to force re-configuration
  }

  # Wait for SSM to be online
  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for SSM agent to be online..."
      for i in {1..60}; do
        STATUS=$(aws ssm describe-instance-information \
          --filters "Key=InstanceIds,Values=${aws_instance.windows_client[0].id}" \
          --region ${var.aws_region} \
          --query 'InstanceInformationList[0].PingStatus' \
          --output text 2>/dev/null || echo "Offline")

        if [ "$STATUS" = "Online" ]; then
          echo "SSM agent is online"
          break
        fi

        echo "Waiting... ($i/60)"
        sleep 10
      done
    EOT
  }

  # Install AWS CLI
  provisioner "local-exec" {
    command = <<-EOT
      ${path.module}/../deployment/run-ssm-command.sh \
        ${aws_instance.windows_client[0].id} \
        ${var.aws_region} \
        "Installing AWS CLI" \
        '$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"' \
        'if (Test-Path $awsCliPath) {' \
        '    Write-Host "AWS CLI already installed"' \
        '} else {' \
        '    Write-Host "Downloading..."' \
        '    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -OutFile "$env:TEMP\AWSCLIV2.msi"' \
        '    Start-Process msiexec.exe -ArgumentList "/i $env:TEMP\AWSCLIV2.msi /quiet /norestart" -Wait' \
        '    Write-Host "AWS CLI installed"' \
        '}'
    EOT
  }

  # Install DCV Server
  provisioner "local-exec" {
    command = <<-EOT
      ${path.module}/../deployment/run-ssm-command.sh \
        ${aws_instance.windows_client[0].id} \
        ${var.aws_region} \
        "Installing Amazon DCV" \
        'Write-Host "Downloading DCV Server..."' \
        '$dcvUrl = "https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-server-x64-Release.msi"' \
        'New-Item -ItemType Directory -Path C:\Temp -Force | Out-Null' \
        'Invoke-WebRequest -Uri $dcvUrl -OutFile C:\Temp\dcv-server.msi -TimeoutSec 600' \
        'Write-Host "Installing..."' \
        'Start-Process msiexec.exe -ArgumentList "/i C:\Temp\dcv-server.msi /quiet /norestart ADDLOCAL=ALL" -Wait' \
        'Start-Sleep -Seconds 10' \
        'Start-Service -Name DcvServer -ErrorAction SilentlyContinue' \
        'Start-Sleep -Seconds 5' \
        '& "C:\Program Files\NICE\DCV\Server\bin\dcv" create-session --type=console --owner=Administrator console 2>&1' \
        'Write-Host "DCV configured"'
    EOT
  }

  # Install Chrome
  provisioner "local-exec" {
    command = <<-EOT
      ${path.module}/../deployment/run-ssm-command.sh \
        ${aws_instance.windows_client[0].id} \
        ${var.aws_region} \
        "Installing Chrome" \
        'Invoke-WebRequest -Uri "https://dl.google.com/chrome/install/latest/chrome_installer.exe" -OutFile C:\Temp\chrome_installer.exe -TimeoutSec 300' \
        'Start-Process C:\Temp\chrome_installer.exe -ArgumentList "/silent /install" -Wait' \
        'Write-Host "Chrome installed"'
    EOT
  }

  depends_on = [
    aws_instance.windows_client,
    aws_iam_role_policy_attachment.windows_client_ssm
  ]
}

# Helper script for running SSM commands
# Save as: deployment/run-ssm-command.sh
#
# #!/bin/bash
# INSTANCE_ID="$1"
# REGION="$2"
# DESCRIPTION="$3"
# shift 3
# COMMANDS=("$@")
#
# echo "[$(date '+%H:%M:%S')] $DESCRIPTION..."
#
# JSON_COMMANDS=$(printf '%s\n' "${COMMANDS[@]}" | jq -R . | jq -s .)
#
# CMD_ID=$(aws ssm send-command \
#     --instance-ids "$INSTANCE_ID" \
#     --region "$REGION" \
#     --document-name "AWS-RunPowerShellScript" \
#     --parameters "commands=${JSON_COMMANDS}" \
#     --timeout-seconds 600 \
#     --output text \
#     --query 'Command.CommandId')
#
# # Wait for completion and display output
# # (implementation similar to deploy-windows-client.sh)

# Output DCV connection info
output "dcv_connection" {
  value = "https://${aws_instance.windows_client[0].public_ip}:8443"
  description = "DCV connection URL"
}
