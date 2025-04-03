locals {
  # Calculate subnet CIDRs based on the base CIDR block
  private_subnets = [
    cidrsubnet(var.base_cidr_block, 8, 1),
    cidrsubnet(var.base_cidr_block, 8, 2),
    cidrsubnet(var.base_cidr_block, 8, 3)
  ]
  
  public_subnets = [
    cidrsubnet(var.base_cidr_block, 8, 101),
    cidrsubnet(var.base_cidr_block, 8, 102),
    cidrsubnet(var.base_cidr_block, 8, 103)
  ]
  
  # Get availability zones for the current region
  azs = var.azs != null ? var.azs : data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.project}-${var.env}-vpc"
  cidr = var.base_cidr_block

  azs             = slice(local.azs, 0, var.az_count)
  private_subnets = slice(local.private_subnets, 0, var.az_count)
  public_subnets  = slice(local.public_subnets, 0, var.az_count)

  enable_nat_gateway     = var.enable_nat_gateway
  single_nat_gateway     = var.single_nat_gateway
  enable_dns_hostnames   = var.enable_dns_hostnames
  enable_dns_support     = var.enable_dns_support

  # Add tags to all resources
  tags = merge(
    var.tags,
    {
      Environment = var.env
      Project     = var.project
    }
  )

  # Add tags to specific resources
  public_subnet_tags = {
    "Tier" = "Public"
  }

  private_subnet_tags = {
    "Tier" = "Private"
  }
} 