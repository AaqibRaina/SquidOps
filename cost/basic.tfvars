# Basic configuration with minimal cost optimizations

region = "us-east-1"
environment = "prod"
project = "example"

# Use dummy values for required variables
vpc_id = "vpc-12345"
subnet_ids = ["subnet-12345", "subnet-67890"]
subsquid_image = "subsquid/evm-processor:latest"

# Basic configuration settings
cost_optimization_level = "basic"
use_spot_instances = false
use_graviton_processors = false
database_serverless = false
enable_caching = false
enable_query_caching = false
enable_connection_pooling = false

# Capacity settings for 500K-1M requests/month
min_capacity = 2
max_capacity = 4
database_allocated_storage = 20
database_max_allocated_storage = 100
database_instance_type = "db.t3.medium" 