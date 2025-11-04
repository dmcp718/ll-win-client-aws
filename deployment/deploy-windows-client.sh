#!/bin/bash
#
# Deploy Windows Client Configuration via AWS SSM
# Simple, pragmatic approach using direct SSM commands
#
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration - Update these for your deployment
INSTANCE_ID="${1:-i-04a97c9efaa7eb3f3}"
REGION="${2:-us-east-1}"
SECRET_ARN="arn:aws:secretsmanager:us-east-1:534711626568:secret:ll-win-client/lucidlink/max.lucid-demo/credentials-1iu1Mp"
MOUNT_POINT="L:"

# Helper function to run SSM command and wait for result
run_ssm() {
    local description="$1"
    shift
    local commands=("$@")

    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} ${description}..."

    # Build JSON array of commands
    local json_commands=$(printf '%s\n' "${commands[@]}" | jq -R . | jq -s .)

    # Send command
    CMD_ID=$(aws ssm send-command \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --document-name "AWS-RunPowerShellScript" \
        --parameters "commands=${json_commands}" \
        --timeout-seconds 600 \
        --output text \
        --query 'Command.CommandId')

    echo -e "  ${YELLOW}Command ID:${NC} $CMD_ID"

    # Wait for completion
    sleep 10

    local max_attempts=60
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        STATUS=$(aws ssm get-command-invocation \
            --command-id "$CMD_ID" \
            --instance-id "$INSTANCE_ID" \
            --region "$REGION" \
            --query 'Status' \
            --output text 2>/dev/null || echo "Pending")

        if [ "$STATUS" = "Success" ]; then
            echo -e "  ${GREEN}✓ Success${NC}"

            # Show output
            OUTPUT=$(aws ssm get-command-invocation \
                --command-id "$CMD_ID" \
                --instance-id "$INSTANCE_ID" \
                --region "$REGION" \
                --query 'StandardOutputContent' \
                --output text)

            if [ -n "$OUTPUT" ]; then
                echo "$OUTPUT" | sed 's/^/    /'
            fi

            return 0

        elif [ "$STATUS" = "Failed" ] || [ "$STATUS" = "Cancelled" ] || [ "$STATUS" = "TimedOut" ]; then
            echo -e "  ${RED}✗ Failed (Status: $STATUS)${NC}"

            # Show error
            aws ssm get-command-invocation \
                --command-id "$CMD_ID" \
                --instance-id "$INSTANCE_ID" \
                --region "$REGION" \
                --query '[StandardOutputContent,StandardErrorContent]' \
                --output text | sed 's/^/    /'

            return 1
        fi

        # Still running
        sleep 10
        ((attempt++))
    done

    echo -e "  ${YELLOW}⏱ Timeout waiting for command${NC}"
    return 1
}

# Main deployment
main() {
    echo "=================================================="
    echo "  Windows Client Deployment via SSM"
    echo "=================================================="
    echo "Instance ID: $INSTANCE_ID"
    echo "Region:      $REGION"
    echo "=================================================="
    echo

    # Step 1: Install AWS CLI
    run_ssm "Installing AWS CLI" \
        '$awsCliPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"' \
        'if (Test-Path $awsCliPath) {' \
        '    Write-Host "AWS CLI already installed"' \
        '} else {' \
        '    Write-Host "Downloading AWS CLI..."' \
        '    $installerUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"' \
        '    $installerPath = "$env:TEMP\AWSCLIV2.msi"' \
        '    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath' \
        '    Write-Host "Installing..."' \
        '    Start-Process msiexec.exe -ArgumentList "/i $installerPath /quiet /norestart" -Wait' \
        '    Write-Host "AWS CLI installed successfully"' \
        '}'

    # Step 2: Install DCV Server and Configure Authentication
    run_ssm "Installing Amazon DCV Server (5-10 minutes)" \
        'Write-Host "Downloading DCV Server..."' \
        '$dcvUrl = "https://d1uj6qtbmh3dt5.cloudfront.net/nice-dcv-server-x64-Release.msi"' \
        '$dcvPath = "C:\Temp\dcv-server.msi"' \
        'New-Item -ItemType Directory -Path C:\Temp -Force | Out-Null' \
        'Invoke-WebRequest -Uri $dcvUrl -OutFile $dcvPath -TimeoutSec 600' \
        'Write-Host "Installing DCV Server..."' \
        'Start-Process msiexec.exe -ArgumentList "/i $dcvPath /quiet /norestart ADDLOCAL=ALL" -Wait' \
        'Write-Host "Setting Administrator password..."' \
        '$adminPassword = "Admin123"' \
        'Set-LocalUser -Name Administrator -Password (ConvertTo-SecureString $adminPassword -AsPlainText -Force)' \
        'Write-Host "Starting DCV services..."' \
        'Start-Sleep -Seconds 10' \
        'Start-Service -Name DcvServer -ErrorAction SilentlyContinue' \
        'Start-Sleep -Seconds 5' \
        'Write-Host "Creating DCV console session with Administrator..."' \
        '& "C:\Program Files\NICE\DCV\Server\bin\dcv" create-session --type=console --owner=Administrator console 2>&1' \
        'Write-Host "DCV Server configured with password: $adminPassword"'

    # Step 3: Install Chrome
    run_ssm "Installing Google Chrome" \
        'Write-Host "Downloading Chrome..."' \
        '$chromeUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"' \
        '$chromePath = "C:\Temp\chrome_installer.exe"' \
        'Invoke-WebRequest -Uri $chromeUrl -OutFile $chromePath -TimeoutSec 300' \
        'Write-Host "Installing Chrome..."' \
        'Start-Process $chromePath -ArgumentList "/silent /install" -Wait' \
        'Write-Host "Chrome installed successfully"'

    # Step 4: Install LucidLink (MSI version - WORKING)
    run_ssm "Installing LucidLink" \
        'Write-Host "Downloading LucidLink MSI..."' \
        '$installerUrl = "https://www.lucidlink.com/download/new-ll-latest/win/stable/"' \
        '$lucidlinkInstaller = "C:\Temp\LucidLink-Setup.msi"' \
        '& curl.exe -L -o $lucidlinkInstaller $installerUrl' \
        '$fileSize = (Get-Item $lucidlinkInstaller).Length' \
        'Write-Host "Downloaded: $([math]::Round($fileSize/1MB, 2)) MB"' \
        'Write-Host "Installing LucidLink MSI..."' \
        '$installLog = "C:\Temp\lucidlink-install.log"' \
        '$msiArgs = @("/i","`"$lucidlinkInstaller`"","/quiet","/norestart","/log","`"$installLog`"")' \
        '$process = Start-Process msiexec -Args $msiArgs -Wait -NoNewWindow -PassThru' \
        'Write-Host "MSI exit code: $($process.ExitCode)"' \
        'Start-Sleep -Seconds 10' \
        '$lucidPath = "C:\Program Files\LucidLink\bin\lucid.exe"' \
        'if (Test-Path $lucidPath) { Write-Host "LucidLink installed successfully" } else { Write-Host "WARNING: Installation may have failed" }'

    # Step 5: Configure LucidLink as Windows Service
    run_ssm "Configuring LucidLink filespace" \
        '$secretArn = "'"$SECRET_ARN"'"' \
        '$region = "'"$REGION"'"' \
        '$mountPoint = "'"$MOUNT_POINT"'"' \
        '$lucidPath = "C:\Program Files\LucidLink\bin\lucid.exe"' \
        'if (Test-Path $lucidPath) {' \
        '    Write-Host "Installing LucidLink service..."' \
        '    & $lucidPath service --install' \
        '    Start-Sleep -Seconds 3' \
        '    Write-Host "Starting LucidLink service..."' \
        '    & $lucidPath service --start' \
        '    Start-Sleep -Seconds 5' \
        '    Write-Host "Retrieving credentials from Secrets Manager..."' \
        '    $awsPath = "C:\Program Files\Amazon\AWSCLIV2\aws.exe"' \
        '    $secretJson = & $awsPath secretsmanager get-secret-value --secret-id $secretArn --region $region --query SecretString --output text' \
        '    $creds = $secretJson | ConvertFrom-Json' \
        '    Write-Host "Linking to filespace: $($creds.domain)"' \
        '    & $lucidPath link --fs $creds.domain --user $creds.username --password $creds.password --mount-point $mountPoint' \
        '    Start-Sleep -Seconds 10' \
        '    if (Test-Path $mountPoint) {' \
        '        Write-Host "SUCCESS: Filespace mounted to $mountPoint"' \
        '    } else {' \
        '        Write-Host "WARNING: Mount point not yet accessible (may need more time)"' \
        '    }' \
        '} else {' \
        '    Write-Host "ERROR: LucidLink not installed"' \
        '}'

    # Step 6: Verify DCV
    run_ssm "Verifying DCV status" \
        'Write-Host "=== DCV Services ==="' \
        'Get-Service -Name DCV* | Select-Object Name,Status,StartType | Format-Table' \
        'Write-Host ""' \
        'Write-Host "=== DCV Port Check ==="' \
        '$result = Test-NetConnection -ComputerName localhost -Port 8443 -WarningAction SilentlyContinue' \
        'if ($result.TcpTestSucceeded) {' \
        '    Write-Host "SUCCESS: DCV is listening on port 8443"' \
        '} else {' \
        '    Write-Host "WARNING: DCV port 8443 not accessible"' \
        '}'

    # Get public IP
    PUBLIC_IP=$(aws ec2 describe-instances \
        --instance-ids "$INSTANCE_ID" \
        --region "$REGION" \
        --query 'Reservations[0].Instances[0].PublicIpAddress' \
        --output text)

    echo
    echo "=================================================="
    echo -e "  ${GREEN}Deployment Complete!${NC}"
    echo "=================================================="
    echo -e "DCV URL: ${BLUE}https://${PUBLIC_IP}:8443${NC}"
    echo -e "Username: ${BLUE}Administrator${NC}"
    echo -e "Password: ${BLUE}Admin123${NC}"
    echo "=================================================="
    echo
    echo "Next steps:"
    echo "  1. Connect via DCV client or browser"
    echo "  2. Verify LucidLink mount point: $MOUNT_POINT"
    echo "  3. Test Chrome installation"
    echo
    echo "DCV Connection File:"
    echo "  Update your .dcv file with these credentials"
}

# Run main function
main "$@"
