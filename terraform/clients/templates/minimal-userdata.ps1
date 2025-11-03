<powershell>
# Minimal EC2 userdata - Downloads full setup script from S3 (no 16KB limit)
$LogFile = "C:\lucidlink-bootstrap.log"

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append
    Write-Host $Message
}

try {
    Write-Log "========================================="
    Write-Log "LucidLink Windows Client - Bootstrap"
    Write-Log "========================================="
    Write-Log "Downloading full setup script from S3..."

    # Download the full setup script from S3
    $BucketName = "${bucket_name}"
    $ScriptKey = "windows-setup.ps1"
    $LocalScript = "C:\windows-setup.ps1"

    # Use AWS PowerShell or AWS CLI to download the script
    $AwsCommand = "aws s3 cp s3://$BucketName/$ScriptKey $LocalScript --region ${aws_region}"
    Write-Log "Running: $AwsCommand"

    $process = Start-Process -FilePath "aws" -ArgumentList "s3","cp","s3://$BucketName/$ScriptKey",$LocalScript,"--region","${aws_region}" -Wait -PassThru -NoNewWindow

    if ($process.ExitCode -ne 0) {
        throw "Failed to download setup script from S3. Exit code: $($process.ExitCode)"
    }

    Write-Log "Successfully downloaded setup script"
    Write-Log "Script size: $((Get-Item $LocalScript).Length) bytes"
    Write-Log "========================================="
    Write-Log "Executing full setup script..."
    Write-Log "========================================="

    # Execute the downloaded script
    PowerShell -ExecutionPolicy Bypass -File $LocalScript

    Write-Log "========================================="
    Write-Log "Setup script execution completed"
    Write-Log "========================================="

} catch {
    Write-Log "ERROR: Bootstrap failed - $_"
    Write-Log "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
</powershell>
