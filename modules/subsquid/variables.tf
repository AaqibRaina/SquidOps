variable "region" {}
variable "project" {
  description = "Project name to use in resource naming"
  type        = string
  default     = "default"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where resources will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where resources will be created"
  type        = list(string)
}

variable "alb_ingress_cidr_blocks" {
  description = "CIDR blocks to allow ALB ingress"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "database_instance_type" {
  description = "RDS instance type for the database"
  type        = string
  default     = "db.t4g.medium"
}

variable "database_allocated_storage" {
  description = "Allocated storage for the database (GB)"
  type        = number
  default     = 20
}

variable "database_max_allocated_storage" {
  description = "Maximum allocated storage for the database (GB)"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Name of the database to create"
  type        = string
  default     = "subsquid"
}

variable "container_command" {
  type        = list(string)
  description = "Optional command to run in the container. If not specified, the container's default CMD will be used."
  default     = null
}

variable "database_username" {
  description = "Username for the database"
  type        = string
  default     = "subsquid"
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

variable "use_spot_instances" {
  description = "Whether to use Spot instances for ECS tasks"
  type        = bool
  default     = null
}

variable "use_graviton_processors" {
  description = "Whether to use ARM-based Graviton processors"
  type        = bool
  default     = null
}

variable "database_serverless" {
  description = "Whether to use Aurora Serverless v2"
  type        = bool
  default     = null
}

variable "database_min_capacity" {
  description = "Minimum capacity for Aurora Serverless v2 (ACUs)"
  type        = number
  default     = 0.5
}

variable "database_max_capacity" {
  description = "Maximum capacity for Aurora Serverless v2 (ACUs)"
  type        = number
  default     = 4
}

variable "enable_caching" {
  description = "Whether to enable Redis caching"
  type        = bool
  default     = null
}

variable "cache_instance_type" {
  description = "ElastiCache instance type"
  type        = string
  default     = "cache.t4g.micro"
}

variable "enable_connection_pooling" {
  description = "Whether to enable database connection pooling"
  type        = bool
  default     = null
}

variable "connection_pool_size" {
  description = "Size of the database connection pool"
  type        = number
  default     = 10
}

variable "enable_compression" {
  description = "Whether to enable response compression"
  type        = bool
  default     = null
}

variable "enable_query_caching" {
  description = "Whether to enable query caching"
  type        = bool
  default     = false
}

variable "query_cache_ttl" {
  description = "TTL for cached queries (seconds)"
  type        = number
  default     = 60
}

variable "efs_lifecycle_policy" {
  description = "Lifecycle policy for EFS (e.g., AFTER_7_DAYS, AFTER_14_DAYS, AFTER_30_DAYS, AFTER_60_DAYS, AFTER_90_DAYS)"
  type        = string
  default     = null
}

variable "efs_throughput_mode" {
  description = "Throughput mode for EFS (bursting or provisioned)"
  type        = string
  default     = "bursting"
}

variable "subsquid_image" {
  description = "Docker image for Subsquid"
  type        = string
}

variable "chain_rpc_endpoint" {
  description = "Blockchain RPC endpoint URL"
  type        = string
  default     = ""
}

variable "contract_address" {
  description = "Smart contract address to monitor"
  type        = string
}

variable "archive_endpoint" {
  description = "Subsquid Archive endpoint URL"
  type        = string
  default     = ""
}

variable "enable_api_auth" {
  description = "Whether to enable API key authentication"
  type        = bool
  default     = false
}

variable "custom_environment_variables" {
  description = "Custom environment variables to pass to the container"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_load_balancer" {
  description = "Whether to create a load balancer"
  type        = bool
  default     = true
}

variable "enable_auto_scaling" {
  description = "Whether to enable auto-scaling"
  type        = bool
  default     = true
}

variable "min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 5
}

variable "max_cluster_size" {
  description = "Maximum number of instances in the ECS cluster"
  type        = number
  default     = 10
}

variable "subsquid_cluster_size" {
  description = "Initial number of instances in the ECS cluster"
  type        = number
  default     = 2
}

variable "task_cpu" {
  description = "CPU units for the ECS task (1024 = 1 vCPU)"
  type        = number
  default     = 1024
}

variable "task_memory" {
  description = "Memory for the ECS task in MiB"
  type        = number
  default     = 2048
}

variable "database_multi_az" {
  description = "Whether to enable Multi-AZ deployment for the database"
  type        = bool
  default     = true
}

variable "database_backup_retention_period" {
  description = "Number of days to retain database backups"
  type        = number
  default     = 7
}

variable "enable_performance_insights" {
  description = "Whether to enable Performance Insights for the database"
  type        = bool
  default     = true
}

variable "enable_autoscaling_based_on_queue" {
  description = "Whether to enable auto-scaling based on queue metrics"
  type        = bool
  default     = false
}

variable "enable_read_replicas" {
  description = "Whether to enable read replicas for the database"
  type        = bool
  default     = false
}

variable "read_replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 1
}

variable "database_instance_class" {
  description = "Instance class for the RDS database"
  type        = string
  default     = "db.t3.medium"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 30
}