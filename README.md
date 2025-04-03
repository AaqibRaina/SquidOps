# Subsquid Terraform Module

This module deploys a production-ready Subsquid indexer infrastructure on AWS with comprehensive cost optimization features.

## Usage

```hcl
module "subsquid" {
  source = "./modules/subsquid"

  region      = "us-west-2"
  environment = "prod"
  vpc_id      = "vpc-12345678"
  subnet_ids  = ["subnet-12345678", "subnet-87654321"]
  
  # Optional: Set cost optimization level
  cost_optimization_level = "balanced"  # Options: basic, balanced, aggressive
  
  # Optional: Subsquid configuration
  subsquid_image     = "your-org/custom-subsquid-indexer:latest"
  chain_rpc_endpoint = "https://your-blockchain-rpc-endpoint"
  
  # Optional: Scaling configuration
  min_capacity = 1
  max_capacity = 4
}
```

## Subsquid Self-Hosting Compliance

This module implements the official Subsquid self-hosting architecture as described in the [Subsquid documentation](https://docs.sqd.ai/sdk/resources/self-hosting/):

1. **Separate Services**: Deploys both `api` and `processor` services as separate ECS tasks
2. **Correct Commands**: Uses `sqd serve:prod` and `sqd process:prod` commands
3. **Proper Port Configuration**: 
   - GraphQL API on port 4350
   - Prometheus metrics on port 3000
4. **Shared Database**: PostgreSQL database shared between services
5. **Persistent Storage**: EFS for shared storage between services

## Architecture

The module deploys:

1. **API Service**: Serves the GraphQL API on port 4350
2. **Processor Service**: Handles blockchain data indexing
3. **PostgreSQL Database**: Stores indexed data
4. **EFS Storage**: Provides persistent storage for both services
5. **Load Balancer**: Routes traffic to the API service
6. **Auto-scaling**: Scales services based on load

## Cost Optimization Levels

The module provides three simple optimization levels:

1. **Basic** - Standard deployment with no cost optimizations
   - On-demand Fargate instances
   - Standard RDS PostgreSQL
   - No caching layer

2. **Balanced** (Default) - Recommended for most workloads
   - Fargate Spot instances (up to 70% savings)
   - Aurora Serverless v2 database
   - Redis caching
   - Connection pooling
   - Response compression
   - EFS lifecycle policy (30 days)

3. **Aggressive** - Maximum cost savings
   - All balanced optimizations
   - More aggressive EFS lifecycle policy (7 days)
   - Smaller database instances
   - More aggressive scaling policies

## Cost Comparison

### Standard Traffic (Up to 500K daily queries per squid)

| Configuration | Monthly Cost Estimate (Per Squid) | Monthly Cost for 5 Squids |
|---------------|-----------------------------------|---------------------------|
| Subsquid Cloud | $2,000+ | $10,000+ |
| Basic | $300 - $350 | $1,500 - $1,750 |
| Balanced | $180 - $220 | $900 - $1,100 |
| Aggressive | $100 - $140 | $500 - $700 |

This represents potential savings of:
- **Basic**: 82-85% savings compared to Subsquid Cloud
- **Balanced**: 89-91% savings compared to Subsquid Cloud
- **Aggressive**: 93-95% savings compared to Subsquid Cloud

### High Traffic (5M+ daily queries per squid)

| Configuration | Monthly Cost Estimate (Per Squid) | Monthly Cost for 5 Squids |
|---------------|-----------------------------------|---------------------------|
| Subsquid Cloud | $15,800 - $16,000 | $79,000 - $80,000 |
| Basic | $500 - $600 | $2,500 - $3,000 |
| Balanced | $350 - $450 | $1,750 - $2,250 |
| Aggressive | $250 - $350 | $1,250 - $1,750 |

For high-traffic scenarios, the savings are even more dramatic:
- **Basic**: 96-97% savings compared to Subsquid Cloud
- **Balanced**: 97-98% savings compared to Subsquid Cloud
- **Aggressive**: 98% savings compared to Subsquid Cloud

*Note: Subsquid Cloud pricing is based on their published rates for query volume, archive access, and base subscription costs. Self-hosted costs include all AWS infrastructure components.*

## Outputs

| Name | Description |
|------|-------------|
| endpoint | Subsquid GraphQL API endpoint URL |
| database_endpoint | Database endpoint |
| database_password | Database password (sensitive) |
| cache_endpoint | Redis cache endpoint (if enabled) |
| cache_enabled | Whether Redis caching is enabled |
| using_spot_instances | Whether Spot instances are being used |
| using_graviton | Whether Graviton processors are being used |
| using_serverless_db | Whether serverless database is being used |

## Features

- 🚀 Subsquid indexer on ECS Fargate
- 🔒 Private VPC-only access with internal ALB
- 💾 Persistent storage using encrypted EFS
- ⚖️ Load balancing with Application Load Balancer
- 🔐 Secure API access with configurable authentication
- 📊 Monitoring endpoint for metrics (port 3000)
- 🔄 Auto-scaling capabilities
- 📝 CloudWatch logging integration
- 🗄️ PostgreSQL database integration
- 💰 Cost optimization features:
  - Fargate Spot instances (up to 70% cost savings)
  - ARM-based Graviton processors (up to 40% better price/performance)
  - Aurora Serverless v2 (pay only for what you use)
  - Redis caching layer (reduce database load and costs)

## Cost Optimization

This module includes several features to optimize costs while maintaining performance:

### 1. Fargate Spot Instances

By default, the module uses Fargate Spot instances which can provide up to 70% cost savings compared to On-Demand instances. This is ideal for Subsquid workloads that can tolerate occasional interruptions.

### 2. Graviton Processors

The module can use ARM-based Graviton processors which offer up to 40% better price/performance ratio compared to x86-based instances.

### 3. Aurora Serverless v2

Instead of provisioned RDS instances, the module can use Aurora Serverless v2 which automatically scales based on workload and charges only for the resources you use.

### 4. Redis Caching

The module includes an optional Redis caching layer to reduce database load and improve performance, which can lead to lower database costs.

### 5. Storage Optimizations

- EFS Lifecycle policies to move infrequently accessed data to lower-cost storage tiers
- GP3 storage for better performance at lower cost when using provisioned RDS

## Resource Sizing Recommendations

| Workload Type | task_cpu | task_memory | database_max_capacity | min_capacity | max_capacity |
|---------------|----------|-------------|------------------------|--------------|--------------|
| Small Chain | 512 | 1024 | 2 | 1 | 2 |
| Medium Chain | 1024 | 2048 | 4 | 1 | 3 |
| Large Chain | 2048 | 4096 | 8 | 2 | 4 |

## Example: Cost-Optimized Configuration

```hcl
module "subsquid" {
  source = "./modules/subsquid"

  region      = "us-west-2"
  environment = "prod"
  vpc_id      = "vpc-12345678"
  subnet_ids  = ["subnet-12345678", "subnet-87654321"]

  # Database configuration
  database_name              = "my_chain_indexer"
  database_serverless        = true
  database_min_capacity      = 0.5
  database_max_capacity      = 4
  
  # Resource optimization
  task_cpu                   = 1024  # 1 vCPU
  task_memory                = 2048  # 2GB RAM
  
  # Cost optimization
  cost_optimization_level    = "aggressive"
  use_spot_instances         = true
  use_graviton_processors    = true
  
  # Performance settings
  enable_caching             = true
  cache_instance_type        = "cache.t4g.micro"
  enable_query_caching       = true
  query_cache_ttl            = 60
  enable_connection_pooling  = true
  enable_compression         = true
  
  # Scaling configuration
  min_capacity               = 1
  max_capacity               = 3
  enable_auto_scaling        = true
  
  # Storage optimization
  efs_lifecycle_policy       = "AFTER_7_DAYS"
  efs_throughput_mode        = "bursting"
  
  # Subsquid settings
  subsquid_image             = "your-org/custom-subsquid-indexer:latest"
  chain_rpc_endpoint         = "https://your-blockchain-rpc-endpoint"
  
  tags = {
    Project     = "blockchain-data"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

## Official Subsquid Images for Testing

You can use these official Subsquid images for testing:

- `subsquid/node:latest` - Base image for running Subsquid nodes
- `subsquid/graphql-server:latest` - GraphQL API server component
- `subsquid/substrate-processor:latest` - For Substrate-based blockchains
- `subsquid/eth-processor:latest` - For Ethereum-based blockchains
- `subsquid/near-processor:latest` - For NEAR Protocol

## Accessing from Other Services

To allow another service to access the Subsquid GraphQL API:

```hcl
resource "aws_security_group_rule" "app_to_subsquid" {
  type                     = "ingress"
  from_port                = 4350
  to_port                  = 4350
  protocol                 = "tcp"
  source_security_group_id = module.your_app.security_group_id
  security_group_id        = module.subsquid.client_security_group_id
  description              = "Allow app to access Subsquid GraphQL API"
}
```

## Security Features

- Private VPC deployment with security groups
- Encryption at rest for all data stores
- Encryption in transit for all communications
- IAM roles with least privilege
- API authentication options

## Operational Excellence

- Auto-scaling based on multiple metrics
- Health checks and automatic recovery
- CloudWatch logging for monitoring
- Backup and disaster recovery 