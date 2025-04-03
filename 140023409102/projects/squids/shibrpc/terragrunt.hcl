include {
  path = find_in_parent_folders()
}

dependencies {
  paths = ["../vpc"]
}

dependency "vpc" {
  config_path = "../vpc"
}

terraform {
  source = "../../../modules/subsquid"
}

inputs = {
  environment = "prod"
  vpc_id      = dependency.vpc.outputs.vpc_id
  subnet_ids  = dependency.vpc.outputs.private_subnets
  
  # Shiba Inu RPC configuration
  subsquid_image     = "shibaswap/shibrpc-indexer:latest"
  chain_rpc_endpoint = "https://shibrpc.com/"
  
  # Database configuration
  database_name = "shibrpc_mainnet"
  
  # Cost optimization
  cost_optimization_level = "balanced"
  min_capacity = 1
  max_capacity = 5
  
  # Custom environment variables
  custom_environment_variables = {
    CHAIN_ID = "1"
    NETWORK  = "shiba"
    TOKEN_SYMBOL = "SHIB"
  }
  
  tags = {
    Project     = "ShibaSwap"
    Environment = "prod"
    Chain       = "shiba-mainnet"
  }
} 