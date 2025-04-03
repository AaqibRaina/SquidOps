variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, staging, dev)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where Subsquid will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where Subsquid nodes will be deployed"
  type        = list(string)
}

variable "subsquid_cluster_size" {
  description = "Number of Subsquid servers in the cluster"
  type        = number
  default     = 2
}

variable "subsquid_version" {
  description = "Version of Subsquid to install"
  type        = string
  default     = "latest"
}

variable "subsquid_image" {
  description = "Docker image for Subsquid (use this for custom indexers)"
  type        = string
  default     = "subsquid/subsquid-node:latest"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}

variable "task_cpu" {
  description = "CPU units for the ECS task (1024 = 1 vCPU)"
  type        = number
  default     = 2048
}

variable "task_memory" {
  description = "Memory for the ECS task in MiB"
  type        = number
  default     = 4096
}

variable "enable_auto_scaling" {
  description = "Enable auto scaling for Subsquid cluster"
  type        = bool
  default     = true
}

variable "max_cluster_size" {
  description = "Maximum number of Subsquid servers in the cluster"
  type        = number
  default     = 4
}

variable "backup_retention_days" {
  description = "Number of days to retain EFS backups"
  type        = number
  default     = 30
}

variable "enable_load_balancer" {
  description = "Whether to create an Application Load Balancer"
  type        = bool
  default     = true
}

variable "database_username" {
  description = "Username for the PostgreSQL database"
  type        = string
  default     = "subsquid"
}

variable "database_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "subsquid"
}

variable "database_instance_class" {
  description = "Instance class for the RDS PostgreSQL database"
  type        = string
  default     = "db.t3.medium"
}

variable "database_allocated_storage" {
  description = "Allocated storage for the RDS PostgreSQL database in GB"
  type        = number
  default     = 20
}

variable "database_multi_az" {
  description = "Whether to enable Multi-AZ deployment for the RDS PostgreSQL database"
  type        = bool
  default     = true
}

variable "database_backup_retention_period" {
  description = "Backup retention period for the RDS PostgreSQL database in days"
  type        = number
  default     = 7
}

variable "chain_rpc_endpoint" {
  description = "RPC endpoint for the blockchain to index"
  type        = string
  default     = ""
}

variable "archive_endpoint" {
  description = "Archive endpoint for the blockchain to index (if applicable)"
  type        = string
  default     = ""
}

variable "enable_api_auth" {
  description = "Enable API key authentication for the GraphQL endpoint"
  type        = bool
  default     = false
}

variable "custom_environment_variables" {
  description = "Additional environment variables for the Subsquid container"
  type        = map(string)
  default     = {}
}

variable "use_spot_instances" {
  description = "Use Spot instances for ECS tasks to reduce costs (up to 90% savings)"
  type        = bool
  default     = true
}

variable "use_graviton_processors" {
  description = "Use ARM-based Graviton processors for better price/performance"
  type        = bool
  default     = true
}

variable "database_serverless" {
  description = "Use Aurora Serverless v2 for the database to optimize costs"
  type        = bool
  default     = true
}

variable "database_min_capacity" {
  description = "Minimum ACU capacity for Aurora Serverless"
  type        = number
  default     = 0.5
}

variable "database_max_capacity" {
  description = "Maximum ACU capacity for Aurora Serverless"
  type        = number
  default     = 8
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights for the database"
  type        = bool
  default     = true
}

variable "enable_caching" {
  description = "Enable Redis caching for improved performance"
  type        = bool
  default     = true
}

variable "cache_instance_type" {
  description = "Instance type for Redis cache"
  type        = string
  default     = "cache.t3.small"
}

variable "cache_ttl" {
  description = "Default TTL for cached responses in seconds"
  type        = number
  default     = 60
}

variable "efs_lifecycle_policy" {
  description = "Lifecycle policy for EFS data (AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, or AFTER_90_DAYS)"
  type        = string
  default     = "AFTER_7_DAYS"
}

variable "efs_throughput_mode" {
  description = "Throughput mode for EFS (bursting or provisioned)"
  type        = string
  default     = "bursting"
}

variable "efs_provisioned_throughput" {
  description = "Provisioned throughput in MiB/s (only used when throughput_mode is provisioned)"
  type        = number
  default     = 5
}

variable "enable_autoscaling_based_on_queue" {
  description = "Enable autoscaling based on queue metrics instead of just CPU"
  type        = bool
  default     = true
}

variable "enable_reserved_instances" {
  description = "Use reserved instances for database to get additional discounts"
  type        = bool
  default     = false
}

variable "enable_multi_region" {
  description = "Enable multi-region deployment for disaster recovery"
  type        = bool
  default     = false
}

variable "enable_read_replicas" {
  description = "Enable read replicas for the database to improve query performance"
  type        = bool
  default     = false
}

variable "read_replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 1
}

variable "enable_query_caching" {
  description = "Enable caching of GraphQL query results"
  type        = bool
  default     = false
}

variable "query_cache_ttl" {
  description = "Time-to-live for cached query results in seconds"
  type        = number
  default     = 60
}

variable "enable_compression" {
  description = "Enable compression for API responses"
  type        = bool
  default     = true
}

variable "enable_connection_pooling" {
  description = "Enable database connection pooling"
  type        = bool
  default     = true
}

variable "connection_pool_size" {
  description = "Size of the database connection pool"
  type        = number
  default     = 20
}

variable "enable_cost_allocation_tags" {
  description = "Enable cost allocation tags for better cost tracking"
  type        = bool
  default     = true
}

variable "cost_optimization_level" {
  description = "Level of cost optimization (basic, balanced, aggressive)"
  type        = string
  default     = "balanced"
  validation {
    condition     = contains(["basic", "balanced", "aggressive"], var.cost_optimization_level)
    error_message = "Cost optimization level must be one of: basic, balanced, aggressive."
  }
}

variable "min_capacity" {
  description = "Minimum number of Subsquid servers"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of Subsquid servers"
  type        = number
  default     = 4
} 