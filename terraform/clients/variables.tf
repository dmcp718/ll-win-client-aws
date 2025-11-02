# =============================================================================
# Tradeshow Windows Client Deployment Variables
# =============================================================================

# =============================================================================
# AWS Configuration
# =============================================================================

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

# =============================================================================
# Instance Configuration
# =============================================================================

variable "instance_type" {
  description = "EC2 instance type for Windows client instances (GPU required for Adobe Creative Cloud)"
  type        = string
  default     = "g4dn.xlarge"

  validation {
    condition     = can(regex("^[a-z]+[0-9]+[a-z]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "Instance type must be a valid EC2 instance type (e.g., g4dn.xlarge, g4dn.2xlarge, g4dn.4xlarge)."
  }
}

variable "instance_count" {
  description = "Number of Windows client instances to launch"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10."
  }
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB for Windows instances"
  type        = number
  default     = 100

  validation {
    condition     = var.root_volume_size >= 30 && var.root_volume_size <= 1000
    error_message = "Root volume size must be between 30 and 1000 GB."
  }
}

# =============================================================================
# Windows AMI Configuration
# =============================================================================

variable "use_nvidia_ami" {
  description = "Use NVIDIA RTX Virtual Workstation AMI (requires AWS Marketplace subscription) or standard Windows Server 2022"
  type        = bool
  default     = false  # Set to false until NVIDIA marketplace subscription is active
}

variable "windows_ami_name_filter" {
  description = "AMI name filter for Windows Server (NOTE: Currently using NVIDIA RTX Virtual Workstation AMI with pre-installed GPU drivers)"
  type        = string
  default     = "NVIDIA RTX Virtual Workstation - WinServer 2022-*"
}

# =============================================================================
# LucidLink Configuration
# =============================================================================

variable "filespace_domain" {
  description = "LucidLink filespace domain (e.g., myspace.lucidlink.com)"
  type        = string
  default     = ""
  sensitive   = false
}

variable "filespace_user" {
  description = "LucidLink username for authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "filespace_password" {
  description = "LucidLink password for authentication"
  type        = string
  default     = ""
  sensitive   = true
}

variable "mount_point" {
  description = "Mount point for LucidLink filespace (Windows drive letter or path)"
  type        = string
  default     = "L:"

  validation {
    condition     = can(regex("^[A-Za-z]:(\\\\.*)?$", var.mount_point))
    error_message = "Mount point must be a Windows drive letter (e.g., L:) or path (e.g., C:\\LucidLink)."
  }
}

variable "lucidlink_installer_url" {
  description = "URL to download LucidLink Windows installer"
  type        = string
  default     = "https://www.lucidlink.com/download/new-ll-latest/win/stable/"
}

# =============================================================================
# Networking Configuration
# =============================================================================

variable "ssh_key_name" {
  description = "Name of the EC2 Key Pair for password retrieval (optional)"
  type        = string
  default     = ""
}

variable "allowed_rdp_cidr_blocks" {
  description = "CIDR blocks allowed for DCV access to Windows instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
