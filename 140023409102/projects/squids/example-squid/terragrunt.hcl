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
  source = "../../../../modules/subsquid"
}

inputs = {
  region      = "us-east-1"
  environment = "prod"
  vpc_id      = dependency.vpc.outputs.vpc_id
  subnet_ids  = dependency.vpc.outputs.private_subnets
  
  # Add project name for DNS namespacing
  project     = "example-squid"
  
  # Use a public image for testing
  subsquid_image     = "nginx:latest"  # Widely available public image
  chain_rpc_endpoint = "https://eth-mainnet.public.blastapi.io"
  contract_address   = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"  # USDC token contract
  
  # Database configuration
  database_name = "example_squid_mainnet"
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
    NETWORK  = "ethereum"
    TOKEN_SYMBOL = "USDC"
  }
  
  tags = {
    Project     = "ExampleSquid"
    Environment = "prod"
    Chain       = "ethereum-mainnet"
    ManagedBy   = "terraform"
  }
} 