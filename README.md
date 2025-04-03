# AWS Subsquid Indexer Terraform Module

This Terraform module deploys a cost-optimized Subsquid indexer on AWS with minimal configuration, following the [official Subsquid self-hosting guidelines](https://docs.sqd.ai/sdk/resources/self-hosting/).

## Simple Usage

```hcl
module "subsquid" {
  source = "./modules/subsquid"

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
   - Fargate Spot instances (up to 90% savings)
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

| Configuration | Monthly Cost Estimate |
|---------------|------------------------|
| Subsquid Cloud | $10,000+ |
| Basic | $2,500 - $3,500 |
| Balanced | $800 - $1,200 |
| Aggressive | $500 - $800 |

## Outputs

| Name | Description |
|------|-------------|
| endpoint | Subsquid GraphQL API endpoint URL |
| database_endpoint | Database endpoint |
| database_password | Database password (sensitive) |

## Features

- 🚀 Subsquid indexer on ECS Fargate
- 🔒 Private VPC-only access with internal ALB
- 💾 Persistent storage using encrypted EFS
- ⚖️ Load balancing with Application Load Balancer
- 🔐 Secure API access with configurable authentication
- 📊 Monitoring endpoint for metrics (port 9090)
- 🔄 Auto-scaling capabilities
- 📝 CloudWatch logging integration
- 🗄️ PostgreSQL database integration
- 💰 Cost optimization features:
  - Fargate Spot instances (up to 90% cost savings)
  - ARM-based Graviton processors (up to 40% better price/performance)
  - Aurora Serverless v2 (pay only for what you use)
  - Redis caching layer (reduce database load and costs)

## Cost Optimization

This module includes several features to optimize costs while maintaining performance:

### 1. Fargate Spot Instances

By default, the module uses Fargate Spot instances which can provide up to 90% cost savings compared to On-Demand instances. This is ideal for Subsquid workloads that can tolerate occasional interruptions.

### 2. Graviton Processors

The module can use ARM-based Graviton processors which offer up to 40% better price/performance ratio compared to x86-based instances.

### 3. Aurora Serverless v2

Instead of provisioned RDS instances, the module can use Aurora Serverless v2 which automatically scales based on workload and charges only for the resources you use.

### 4. Redis Caching

The module includes an optional Redis caching layer to reduce database load and improve performance, which can lead to lower database costs.

### 5. Storage Optimizations

- EFS Lifecycle policies to move infrequently accessed data to lower-cost storage tiers
- GP3 storage for better performance at lower cost when using provisioned RDS

## Cost Comparison

| Configuration | Monthly Cost Estimate* |
|---------------|------------------------|
| Standard (On-Demand, x86, Provisioned RDS) | $2,500 - $3,500 |
| Cost-Optimized (Spot, Graviton, Serverless) | $800 - $1,200 |

*Estimates based on typical usage patterns. Actual costs may vary.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |
| random | >= 3.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| environment | Environment name (e.g., prod, staging, dev) | `string` | n/a | yes |
| vpc_id | ID of the VPC where Subsquid will be deployed | `string` | n/a | yes |
| subnet_ids | List of subnet IDs where Subsquid nodes will be deployed | `list(string)` | n/a | yes |
| subsquid_cluster_size | Number of Subsquid servers in the cluster | `number` | `2` | no |
| task_cpu | CPU units for the ECS task (1024 = 1 vCPU) | `number` | `2048` | no |
| task_memory | Memory for the ECS task in MiB | `number` | `4096` | no |
| subsquid_version | Version of Subsquid to install | `string` | `latest` | no |
| enable_auto_scaling | Enable auto scaling for Subsquid cluster | `bool` | `true` | no |
| max_cluster_size | Maximum number of Subsquid servers in the cluster | `number` | `4` | no |
| backup_retention_days | Number of days to retain EFS backups | `number` | `30` | no |
| use_spot_instances | Use Spot instances for ECS tasks | `bool` | `true` | no |
| use_graviton_processors | Use ARM-based Graviton processors | `bool` | `true` | no |
| database_serverless | Use Aurora Serverless v2 for the database | `bool` | `true` | no |
| database_min_capacity | Minimum ACU capacity for Aurora Serverless | `number` | `0.5` | no |
| database_max_capacity | Maximum ACU capacity for Aurora Serverless | `number` | `8` | no |
| enable_caching | Enable Redis caching layer | `bool` | `true` | no |
| cache_instance_type | Redis cache instance type | `string` | `cache.t4g.small` | no |
| cache_ttl | Default TTL for cached responses in seconds | `number` | `60` | no |

## Outputs

| Name | Description |
|------|-------------|
| subsquid_endpoint | Subsquid API endpoint URL |
| load_balancer_dns | DNS name of the Subsquid load balancer |
| client_security_group_id | Security group ID for Subsquid clients |
| database_endpoint | PostgreSQL database endpoint |
| database_username | PostgreSQL database username |
| database_password | PostgreSQL database password (sensitive) |
| cloudwatch_log_group | CloudWatch Log Group for Subsquid logs |

## Security Groups

The module creates the following security groups:

1. **Subsquid Server Security Group**
   - Inbound 3000: GraphQL API port (VPC CIDR)
   - Inbound 9090: Monitoring (VPC CIDR)
   - Inbound 2049: EFS access (self)

2. **Subsquid Client Security Group**
   - Inbound: VPC CIDR only
   - Use this for your client applications

3. **EFS Security Group**
   - Inbound 2049: NFS from Subsquid servers

4. **Database Security Group**
   - Inbound 5432: PostgreSQL from Subsquid servers

## Architecture Components

### Compute (ECS Fargate)
- Subsquid containers running on Fargate
- Auto-scaling based on CPU utilization (75% threshold)
- Fargate capacity provider strategy
- Health checks on port 3000

### Storage (EFS)
- Persistent storage for Subsquid data
- Automatic backups enabled
- Encryption at rest with KMS
- IA storage class transition after 30 days

### Database (RDS PostgreSQL)
- Managed PostgreSQL database
- Multi-AZ deployment for high availability
- Automated backups
- Encryption at rest

### Networking
- Internal Application Load Balancer
- Private DNS zone (`{environment}.internal`)
- VPC-only access
- Sticky sessions enabled

## Monitoring

Access the monitoring dashboard at:
```
http://subsquid.{environment}.internal:9090/
```

Available metrics include:
- Query performance
- Indexing statistics
- System metrics

## Logs

Container logs are available in CloudWatch:
```
/ecs/subsquid-{environment}
```

## Usage Across Projects

To use this Subsquid instance across multiple projects:

1. **Network Configuration**:
   - Ensure all projects are in the same VPC or have VPC peering configured
   - Add the client security group to your application's security groups

2. **Connection String**:
   - Use the `subsquid_endpoint` output as your GraphQL API endpoint
   - Format: `http://subsquid.{environment}.internal:3000/graphql`

3. **Authentication**:
   - If enabled, use the API key in your requests:
   ```
   Authorization: Bearer ${api_key}
   ```

4. **Custom Indexers**:
   - To deploy custom indexers, build your own Docker image with your schema
   - Update the `subsquid_image` variable to point to your custom image

## Example Usage with Cost Optimization

```hcl
module "subsquid" {
  source = "./modules/subsquid"

  region      = "us-west-2"
  environment = "prod"
  vpc_id      = "vpc-12345678"
  subnet_ids  = ["subnet-12345678", "subnet-87654321"]

  # Cost optimization settings
  use_spot_instances       = true
  use_graviton_processors  = true
  database_serverless      = true
  database_min_capacity    = 0.5
  database_max_capacity    = 8
  enable_caching           = true
  cache_instance_type      = "cache.t4g.small"
  cache_ttl                = 60
  
  # Subsquid settings
  subsquid_image        = "your-org/custom-subsquid-indexer:latest"
  chain_rpc_endpoint    = "https://your-blockchain-rpc-endpoint"
  
  tags = {
    Project     = "blockchain-data"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

## Self-Hosting Subsquid

This module follows the [official Subsquid self-hosting guidelines](https://docs.sqd.ai/sdk/resources/self-hosting/) but adds enterprise-grade infrastructure and cost optimizations.

The deployment includes:
- Separate processor and API services
- PostgreSQL database for data storage
- Redis cache for query performance
- Prometheus metrics endpoint
- Auto-scaling based on load

## Accessing from Other Services

To allow another service to access the Subsquid GraphQL API:

```hcl
resource "aws_security_group_rule" "app_to_subsquid" {
  type                     = "ingress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = module.your_app.security_group_id
  security_group_id        = module.subsquid.client_security_group_id
  description              = "Allow app to access Subsquid GraphQL API"
}
```

# Advanced Cost Optimization Strategies

## 1. Intelligent Auto-scaling
The module now supports multi-metric auto-scaling based on:
- CPU utilization
- Memory utilization
- Queue depth (for processing workloads)

This ensures you only pay for resources when needed, with fast scale-out and gradual scale-in.

## 2. Storage Tiering
EFS storage automatically transitions infrequently accessed data to lower-cost storage tiers after a configurable period (default: 7 days), reducing storage costs by up to 80%.

## 3. Connection Pooling
Database connection pooling reduces the number of connections needed, improving performance and reducing database resource requirements.

## 4. Query Caching
Two-level caching strategy:
- Redis cache for frequently accessed data
- In-memory GraphQL query result caching

## 5. Response Compression
Automatic compression of API responses reduces bandwidth costs and improves performance.

## 6. Read Replicas for High-Traffic Scenarios
For high-traffic deployments, read replicas can be enabled to offload read queries from the primary database.

## 7. Cost Allocation Tags
Automatic tagging of resources for better cost tracking and allocation.

## Cost Comparison for High-Traffic Scenarios (5M+ queries)

| Configuration | Monthly Cost Estimate |
|---------------|------------------------|
| Subsquid Cloud | $10,000+ |
| Standard AWS (On-Demand) | $2,500 - $3,500 |
| Basic Optimized | $800 - $1,200 |
| Advanced Optimized | $500 - $800 |

## Example Usage with Advanced Optimizations

```hcl
module "subsquid" {
  source = "./modules/subsquid"

  region      = "us-west-2"
  environment = "prod"
  vpc_id      = "vpc-12345678"
  subnet_ids  = ["subnet-12345678", "subnet-87654321"]

  # Cost optimization settings
  use_spot_instances       = true
  use_graviton_processors  = true
  database_serverless      = true
  database_min_capacity    = 0.5
  database_max_capacity    = 8
  enable_caching           = true
  cache_instance_type      = "cache.t4g.small"
  cache_ttl                = 60
  
  # Subsquid settings
  subsquid_image        = "your-org/custom-subsquid-indexer:latest"
  chain_rpc_endpoint    = "https://your-blockchain-rpc-endpoint"
  
  # Advanced optimizations
  enable_auto_scaling    = true
  max_cluster_size       = 4
  backup_retention_days  = 30
  use_spot_instances     = true
  use_graviton_processors = true
  database_serverless    = true
  database_min_capacity  = 0.5
  database_max_capacity  = 8
  enable_caching         = true
  cache_instance_type    = "cache.t4g.small"
  cache_ttl              = 60
  
  tags = {
    Project     = "blockchain-data"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
``` 