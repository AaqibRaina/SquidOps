locals {
  account_id = read_terragrunt_config(find_in_parent_folders(".global.hcl")).locals.account_id
  region = read_terragrunt_config(find_in_parent_folders(".global.hcl")).locals.region
}

# Terragrunt will copy the Terraform configurations specified by the source
# parameter, along with any files in the working directory,
# into a temporary folder, and execute your Terraform commands in that folder.
terraform {
  source = "../../../modules/backend"
}

include {
  path = find_in_parent_folders()
}

inputs = {
  project  = local.account_id
  region   = local.region
}