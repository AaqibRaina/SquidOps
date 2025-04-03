# Balanced configuration for high traffic (5M-10M requests/month)

region = "us-east-1"
environment = "prod"
project = "example"

# Use dummy values for required variables
vpc_id = "vpc-12345"
subnet_ids = ["subnet-12345", "subnet-67890"]
subsquid_image = "subsquid/evm-processor:latest"

# Balanced configuration settings
cost_optimization_level = "balanced"
use_spot_instances = true
use_graviton_processors = true
database_serverless = true
database_min_capacity = 2
database_max_capacity = 16
enable_caching = true
cache_instance_type = "cache.t4g.medium"
enable_query_caching = true
enable_connection_pooling = true

# Capacity settings for 5M-10M requests/month
min_capacity = 4
max_capacity = 8 