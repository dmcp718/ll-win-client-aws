# S3 bucket for storing Windows userdata scripts (no size limits)
resource "aws_s3_bucket" "userdata_scripts" {
  bucket_prefix = "ll-win-client-userdata-"

  tags = merge(
    local.common_tags,
    {
      Name = "ll-win-client-userdata"
    }
  )
}

# Enable versioning for script history
resource "aws_s3_bucket_versioning" "userdata_scripts" {
  bucket = aws_s3_bucket.userdata_scripts.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "userdata_scripts" {
  bucket = aws_s3_bucket.userdata_scripts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "userdata_scripts" {
  bucket = aws_s3_bucket.userdata_scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Upload the full Windows userdata script to S3
resource "aws_s3_object" "windows_setup_script" {
  bucket = aws_s3_bucket.userdata_scripts.id
  key    = "windows-setup.ps1"

  # Use the FULL version with comments (no size limit in S3)
  content = templatefile("${path.module}/templates/windows-userdata.ps1", {
    filespace_domain   = var.filespace_domain
    filespace_user     = var.filespace_user
    filespace_password = var.filespace_password
    mount_point        = var.mount_point
    aws_region         = var.aws_region
    installer_url      = var.lucidlink_installer_url
    secret_arn         = var.filespace_domain != "" ? aws_secretsmanager_secret.lucidlink_credentials[0].arn : ""
  })

  # Update script on changes
  etag = md5(templatefile("${path.module}/templates/windows-userdata.ps1", {
    filespace_domain   = var.filespace_domain
    filespace_user     = var.filespace_user
    filespace_password = var.filespace_password
    mount_point        = var.mount_point
    aws_region         = var.aws_region
    installer_url      = var.lucidlink_installer_url
    secret_arn         = var.filespace_domain != "" ? aws_secretsmanager_secret.lucidlink_credentials[0].arn : ""
  }))

  tags = local.common_tags
}
