locals {
  global_vars = read_terragrunt_config(
    find_in_parent_folders(
      ".global.hcl"
    )
  )
  account_id = local.global_vars.locals.account_id
  region     = local.global_vars.locals.region
}

generate "provider" {
  path      = "provider_override.tf"
  if_exists = "overwrite_terragrunt"

  contents = <<EOF
provider "aws" {
  region  = var.region
}
EOF
}


generate "versions" {
  path      = "versions_override.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
  terraform {
    required_providers {
      aws = {
        source  = "hashicorp/aws"
        version = "~> 5.59.0"
      }
    }
    required_version = ">=1.8.0"
  }
EOF
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "${local.account_id}-terraform-squids-state-bucket-${local.region}"

    key            = "${path_relative_to_include()}"
    region         = local.region
    encrypt        = true
    dynamodb_table = "${local.account_id}-terraform-state-lock-${local.region}"
  }
}

inputs = merge (
    local.global_vars.locals
)
