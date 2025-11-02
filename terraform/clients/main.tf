# =============================================================================
# LucidLink Windows Client Module - Main Configuration
# =============================================================================
# This module deploys standalone Windows LucidLink client instances with VPC

terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# =============================================================================
# VPC and Networking Resources
# =============================================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "ll-win-client-vpc"
    Project = "ll-win-client"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "ll-win-client-igw"
    Project = "ll-win-client"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name    = "ll-win-client-public-subnet"
    Project = "ll-win-client"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name    = "ll-win-client-public-rt"
    Project = "ll-win-client"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# =============================================================================
# Common Tags
# =============================================================================

locals {
  common_tags = {
    Project     = "tradeshow-client"
    ManagedBy   = "Terraform"
    Environment = "production"
  }
}
