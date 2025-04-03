# -----------------------------------------------------
# 1. Data sources
# -----------------------------------------------------

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_region" "current" {}

# -----------------------------------------------------
# 2. Random resources
# -----------------------------------------------------

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_password" "api_key" {
  count            = var.enable_api_auth ? 1 : 0
  length           = 32
  special          = false
}

# -----------------------------------------------------
# 3. Local variables
# -----------------------------------------------------

locals {
  name_prefix = "${var.project}-${var.environment}-subsquid"
  
  # Base configurations for different optimization levels
  config = {
    basic = {
      use_spot_instances       = false
      use_graviton             = false
      database_serverless      = false
      enable_caching           = false
      efs_lifecycle_policy     = null
      enable_connection_pooling = false
      enable_compression       = false
    }
    balanced = {
      use_spot_instances       = true
      use_graviton             = true
      database_serverless      = true
      enable_caching           = true
      efs_lifecycle_policy     = "AFTER_30_DAYS"
      enable_connection_pooling = true
      enable_compression       = true
    }
    aggressive = {
      use_spot_instances       = true
      use_graviton             = true
      database_serverless      = true
      enable_caching           = true
      efs_lifecycle_policy     = "AFTER_7_DAYS"
      enable_connection_pooling = true
      enable_compression       = true
    }
  }
  
  # Get the base config for the selected optimization level
  base_config = local.config[var.cost_optimization_level]
  
  # Override with explicit settings if provided
  effective_config = {
    use_spot_instances = var.use_spot_instances != null ? var.use_spot_instances : local.base_config.use_spot_instances
    use_graviton = var.use_graviton_processors != null ? var.use_graviton_processors : local.base_config.use_graviton
    database_serverless = var.database_serverless != null ? var.database_serverless : local.base_config.database_serverless
    enable_caching = var.enable_caching != null ? var.enable_caching : local.base_config.enable_caching
    efs_lifecycle_policy = var.efs_lifecycle_policy != null ? var.efs_lifecycle_policy : local.base_config.efs_lifecycle_policy
    enable_connection_pooling = var.enable_connection_pooling != null ? var.enable_connection_pooling : local.base_config.enable_connection_pooling
    enable_compression = var.enable_compression != null ? var.enable_compression : local.base_config.enable_compression
  }
  
  # Database configuration
  database_host = local.effective_config.database_serverless ? aws_rds_cluster.subsquid[0].endpoint : aws_db_instance.subsquid[0].address
  database_port = local.effective_config.database_serverless ? aws_rds_cluster.subsquid[0].port : aws_db_instance.subsquid[0].port
  
  # Redis configuration
  redis_environment = local.effective_config.enable_caching ? [
    {
      name  = "REDIS_HOST"
      value = aws_elasticache_replication_group.subsquid[0].primary_endpoint_address
    },
    {
      name  = "REDIS_PORT"
      value = "6379"
    },
    {
      name  = "REDIS_PASSWORD"
      value = random_password.redis_auth_token[0].result
    }
  ] : []
  
  # Base environment variables
  base_environment = [
    {
      name  = "DB_HOST"
      value = local.database_host
    },
    {
      name  = "DB_PORT"
      value = tostring(local.database_port)
    },
    {
      name  = "DB_NAME"
      value = var.database_name
    },
    {
      name  = "DB_USER"
      value = var.database_username
    },
    {
      name  = "DB_PASS"
      value = random_password.db_password.result
    },
    {
      name  = "NODE_ENV"
      value = "production"
    },
    {
      name  = "PROMETHEUS_PORT"
      value = "9090"
    }
  ]
  
  # Connection pooling environment variables
  connection_pooling_env = var.enable_connection_pooling ? [
    {
      name  = "DB_POOL_SIZE"
      value = tostring(var.connection_pool_size)
    },
    {
      name  = "DB_POOL_CLIENT"
      value = "pg"
    }
  ] : []
  
  # Add compression if enabled
  compression_env = var.enable_compression ? [
    {
      name  = "ENABLE_COMPRESSION"
      value = "true"
    }
  ] : []
  
  # Query caching environment variables
  query_caching_env = var.enable_query_caching ? [
    {
      name  = "QUERY_CACHE_ENABLED"
      value = "true"
    },
    {
      name  = "QUERY_CACHE_TTL"
      value = tostring(var.query_cache_ttl)
    }
  ] : []
  
  # Combine all environment variables
  combined_environment = concat(
    local.base_environment,
    local.redis_environment,
    local.connection_pooling_env,
    local.query_caching_env,
    local.compression_env,
    var.chain_rpc_endpoint != "" ? [
      {
        name  = "CHAIN_RPC"
        value = var.chain_rpc_endpoint
      }
    ] : [],
    var.archive_endpoint != "" ? [
      {
        name  = "ARCHIVE_ENDPOINT"
        value = var.archive_endpoint
      }
    ] : [],
    var.enable_api_auth ? [
      {
        name  = "API_KEY"
        value = random_password.api_key[0].result
      }
    ] : [],
    [for k, v in var.custom_environment_variables : {
      name  = k
      value = v
    }]
  )
  
  # Container definition with non-sensitive environment variables
  container_definition = {
    name      = "subsquid"
    image     = var.subsquid_image
    essential = true
    
    portMappings = [
      {
        containerPort = 4350
        hostPort      = 4350
        protocol      = "tcp"
      },
      {
        containerPort = 3000
        hostPort      = 3000
        protocol      = "tcp"
      }
    ]
    
    environment = local.combined_environment
    
    mountPoints = [
      {
        sourceVolume  = "subsquid-data"
        containerPath = "/app/.sqd"
        readOnly      = false
      }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.subsquid.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "subsquid"
      }
    }
    
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:4350/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }
  
  # Common tags
  tags = merge(
    var.tags,
    {
      Name        = local.name_prefix
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# -----------------------------------------------------
# 4. CloudWatch resources
# -----------------------------------------------------

resource "aws_cloudwatch_log_group" "subsquid" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  
  tags = local.tags
}

# -----------------------------------------------------
# 5. Load Balancer resources
# -----------------------------------------------------

resource "aws_lb" "subsquid" {
  count              = var.enable_load_balancer ? 1 : 0
  name               = local.name_prefix
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids
  
  tags = local.tags
}

resource "aws_lb_target_group" "subsquid" {
  count       = var.enable_load_balancer ? 1 : 0
  name        = local.name_prefix
  port        = 4350
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200"
  }
  
  tags = local.tags
}

resource "aws_lb_listener" "subsquid" {
  count             = var.enable_load_balancer ? 1 : 0
  load_balancer_arn = aws_lb.subsquid[0].arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.subsquid[0].arn
  }
}

# -----------------------------------------------------
# 6. Route53 resources
# -----------------------------------------------------

resource "aws_route53_zone" "private" {
  name = "${var.project}.${var.environment}.internal"
  
  vpc {
    vpc_id = var.vpc_id
  }
  
  tags = local.tags
}

resource "aws_route53_record" "subsquid" {
  count   = var.enable_load_balancer ? 1 : 0
  zone_id = aws_route53_zone.private.zone_id
  name    = "subsquid.${var.project}.${var.environment}.internal"
  type    = "A"
  
  alias {
    name                   = aws_lb.subsquid[0].dns_name
    zone_id                = aws_lb.subsquid[0].zone_id
    evaluate_target_health = true
  }
}

# -----------------------------------------------------
# 7. Service Discovery resources
# -----------------------------------------------------

resource "aws_service_discovery_private_dns_namespace" "subsquid" {
  name        = "${var.project}.${var.environment}.subsquid.internal"
  description = "Private DNS namespace for ${var.project} Subsquid services"
  vpc         = var.vpc_id
  
  tags = local.tags
}

resource "aws_service_discovery_service" "subsquid" {
  name = "api"
  
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.subsquid.id
    
    dns_records {
      ttl  = 10
      type = "A"
    }
    
    routing_policy = "MULTIVALUE"
  }
  
  health_check_custom_config {
    failure_threshold = 1
  }
  
  tags = local.tags
}

# Generate Redis authentication token
resource "random_password" "redis_auth_token" {
  count            = local.effective_config.enable_caching ? 1 : 0
  length           = 32
  special          = false
} 