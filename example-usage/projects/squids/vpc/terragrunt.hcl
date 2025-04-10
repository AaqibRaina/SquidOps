include {
  path = find_in_parent_folders()
}

locals {
  region = read_terragrunt_config(find_in_parent_folders(".global.hcl")).locals.region
}

terraform {
  source = "../../../../modules/vpc"
}

inputs = {
  project         = "squids"
  env             = "prod"
  base_cidr_block = "10.50.0.0/16"  # Subnets will be automatically calculated
  az_count        = 3               # Use 3 availability zones
  
  tags = {
    Environment = "production"
    Purpose     = "Subsquid"
  }
} 