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
  region      = "us-east-1"
  environment = "prod"
  vpc_id      = dependency.vpc.outputs.vpc_id
  subnet_ids  = dependency.vpc.outputs.private_subnets
  
  # Shiba Inu RPC configuration
  subsquid_image     = "shibaswap/shibrpc-indexer:latest"
  chain_rpc_endpoint = "https://shibrpc.com/"
  
  # Database configuration
  database_name = "shibrpc_mainnet"
  database_serverless = true
  database_min_capacity = 0.5
  database_max_capacity = 8
  
  # Cost optimization
  cost_optimization_level = "balanced"
  use_spot_instances = true
  use_graviton_processors = true
  
  # Performance settings
  enable_caching = true
  cache_instance_type = "cache.t4g.small"
  enable_query_caching = true
  query_cache_ttl = 60
  enable_connection_pooling = true
  connection_pool_size = 20
  enable_compression = true
  
  # Scaling configuration
  min_capacity = 1
  max_capacity = 5
  enable_auto_scaling = true
  
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
    ManagedBy   = "terraform"
  }
} 