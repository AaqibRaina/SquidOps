# Aggressive configuration with maximum cost optimizations

region = "us-east-1"
environment = "prod"
project = "example"

# Use dummy values for required variables
vpc_id = "vpc-12345"
subnet_ids = ["subnet-12345", "subnet-67890"]
subsquid_image = "subsquid/evm-processor:latest"

# Aggressive configuration settings
cost_optimization_level = "aggressive"
use_spot_instances = true
use_graviton_processors = true
database_serverless = true
database_min_capacity = 0.5
database_max_capacity = 4
enable_caching = true
cache_instance_type = "cache.t4g.micro"
enable_query_caching = true
query_cache_ttl = 120
enable_connection_pooling = true
connection_pool_size = 20
enable_compression = true
efs_lifecycle_policy = "AFTER_7_DAYS"

# Capacity settings for 500K-1M requests/month
min_capacity = 1
max_capacity = 3 