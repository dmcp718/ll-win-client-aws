# =============================================================================
# Tradeshow Windows Client Outputs
# =============================================================================

output "instance_ids" {
  description = "IDs of Windows client instances"
  value       = aws_instance.windows_client[*].id
}

output "private_ips" {
  description = "Private IPs of Windows client instances"
  value       = aws_instance.windows_client[*].private_ip
}

output "public_ips" {
  description = "Public IPs of Windows client instances"
  value       = aws_instance.windows_client[*].public_ip
}

output "mount_point" {
  description = "Mount point for LucidLink filespace on Windows instances"
  value       = var.mount_point
}

output "filespace_domain" {
  description = "LucidLink filespace domain configured for clients"
  value       = var.filespace_domain
}

output "vpc_id" {
  description = "VPC ID for the deployment"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "subnet_id" {
  description = "Subnet ID for client instances"
  value       = aws_subnet.public.id
}

output "region" {
  description = "AWS region for deployment"
  value       = var.aws_region
}

output "dcv_info" {
  description = "DCV connection information for Windows instances"
  value = {
    for idx, instance in aws_instance.windows_client :
    "client-${idx + 1}" => "DCV to ${instance.public_ip}:8443"
  }
}

output "ssm_commands" {
  description = "SSM Session Manager commands for Windows instances"
  value = {
    for idx, instance in aws_instance.windows_client :
    "client-${idx + 1}" => "aws ssm start-session --target ${instance.id} --region ${var.aws_region}"
  }
}

output "windows_ami_id" {
  description = "Windows AMI ID used for instances"
  value       = local.selected_ami_id
}

output "windows_ami_name" {
  description = "Windows AMI name used for instances"
  value       = var.use_nvidia_ami ? data.aws_ami.windows_2022_nvidia[0].name : data.aws_ami.windows_2022_standard.name
}

output "using_nvidia_ami" {
  description = "Whether NVIDIA RTX Virtual Workstation AMI is being used"
  value       = var.use_nvidia_ami
}
