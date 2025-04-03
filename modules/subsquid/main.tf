# Create ALB for Subsquid cluster
resource "aws_lb" "subsquid" {
  count              = var.enable_load_balancer ? 1 : 0
  name               = "subsquid-${var.environment}"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.subsquid.id]
  subnets            = var.subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "subsquid-${var.environment}"
    }
  )
}

resource "aws_lb_listener" "subsquid" {
  load_balancer_arn = aws_lb.subsquid.arn
  port              = "4350"  # GraphQL port as per official docs
  protocol          = "HTTP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.subsquid.arn
  }
}

resource "aws_lb_target_group" "subsquid" {
  name        = "subsquid-${var.environment}"
  port        = 4350  # GraphQL port as per official docs
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  
  health_check {
    protocol            = "HTTP"
    path                = "/health"
    port                = 4350
    interval            = 30
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    matcher             = "200"
  }
  
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 86400
    enabled         = true
  }
  
  tags = var.tags
}

# Route53 DNS record for Subsquid cluster
resource "aws_route53_record" "subsquid" {
  count = length(aws_lb.subsquid) > 0 ? 1 : 0
  
  zone_id = aws_route53_zone.private.zone_id
  name    = "subsquid.${var.environment}.internal"
  type    = "A"

  alias {
    name                   = aws_lb.subsquid[0].dns_name
    zone_id                = aws_lb.subsquid[0].zone_id
    evaluate_target_health = true
  }
}

# Private DNS zone
resource "aws_route53_zone" "private" {
  name = "${var.environment}.internal"
  
  vpc {
    vpc_id = var.vpc_id
  }
  
  tags = var.tags
}

# Use locals to set configuration based on optimization level
locals {
  # Set configurations based on optimization level
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
  
  # Get configuration for the selected optimization level
  selected_config = local.config[var.cost_optimization_level]
  
  # Database configuration
  database_host = local.selected_config.database_serverless ? aws_rds_cluster.subsquid[0].endpoint : aws_db_instance.subsquid.address
  database_port = local.selected_config.database_serverless ? aws_rds_cluster.subsquid[0].port : aws_db_instance.subsquid.port
  
  # Environment variables
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
      value = "subsquid"
    },
    {
      name  = "DB_USER"
      value = "subsquid"
    },
    {
      name  = "DB_PASS"
      value = random_password.db_password.result
    },
    {
      name  = "NODE_ENV"
      value = "production"
    }
  ]
  
  # Redis environment variables (if caching is enabled)
  redis_environment = local.selected_config.enable_caching ? [
    {
      name  = "REDIS_URL"
      value = "redis://${aws_elasticache_replication_group.subsquid[0].primary_endpoint_address}:6379"
    }
  ] : []
  
  # Connection pooling environment variables
  connection_pooling_env = local.selected_config.enable_connection_pooling ? [
    {
      name  = "DB_POOL_SIZE"
      value = "20"
    }
  ] : []
  
  # Compression environment variables
  compression_env = local.selected_config.enable_compression ? [
    {
      name  = "ENABLE_COMPRESSION"
      value = "true"
    }
  ] : []
  
  # Combine all environment variables
  combined_environment = concat(
    local.base_environment,
    local.redis_environment,
    local.connection_pooling_env,
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
    [for k, v in var.custom_environment_variables : {
      name  = k
      value = v
    }]
  )
  
  # Default tags
  default_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Service     = "subsquid"
  }
  
  # Combined tags
  tags = merge(local.default_tags, var.tags)

  # Container definition based on official Subsquid self-hosting guidelines
  container_definition = {
    name      = "subsquid"
    image     = var.subsquid_image
    essential = true
    
    # Port mappings for GraphQL API and Prometheus metrics
    portMappings = [
      {
        containerPort = 4350  # GraphQL endpoint (as per official docs)
        hostPort      = 4350
        protocol      = "tcp"
      },
      {
        containerPort = 3000  # Prometheus metrics (as per official docs)
        hostPort      = 3000
        protocol      = "tcp"
      }
    ]
    
    # Mount points for EFS
    mountPoints = [
      {
        sourceVolume  = "subsquid-data"
        containerPath = "/squid"
        readOnly      = false
      }
    ]
    
    # Environment variables based on official Subsquid requirements
    environment = concat(
      [
        {
          name  = "DB_NAME"
          value = var.database_name
        },
        {
          name  = "DB_PORT"
          value = tostring(local.database_port)
        },
        {
          name  = "DB_HOST"
          value = local.database_host
        },
        {
          name  = "DB_PASS"
          value = random_password.db_password.result
        },
        {
          name  = "GQL_PORT"
          value = "4350"  # GraphQL port as per official docs
        },
        {
          name  = "PROCESSOR_PROMETHEUS_PORT"
          value = "3000"  # Prometheus port as per official docs
        }
      ],
      # Add custom environment variables
      [for k, v in var.custom_environment_variables : {
        name  = k
        value = v
      }]
    )
    
    # Logging configuration
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.subsquid.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "subsquid"
      }
    }
    
    # Health check
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:4350/health || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 60
    }
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "subsquid" {
  name = "subsquid-${var.environment}"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = local.tags
}

# Generate secure password for PostgreSQL database
resource "random_password" "db_password" {
  length  = 16
  special = false
}

# Generate API key if authentication is enabled
resource "random_password" "api_key" {
  count   = var.enable_api_auth ? 1 : 0
  length  = 32
  special = false
}

# Create separate task definitions for API and processor services
resource "aws_ecs_task_definition" "subsquid_api" {
  family                   = "subsquid-api-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  
  # Use ARM architecture if Graviton is enabled
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = local.selected_config.use_graviton ? "ARM64" : "X86_64"
  }
  
  # Mount EFS volume
  volume {
    name = "subsquid-data"
    
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.subsquid.id
      transit_encryption = "ENABLED"
      
      authorization_config {
        access_point_id = aws_efs_access_point.subsquid.id
        iam             = "ENABLED"
      }
    }
  }
  
  # Container definition with command override for API service
  container_definitions = jsonencode([
    merge(local.container_definition, {
      command = ["sqd", "serve:prod"]  # API service command as per official docs
    })
  ])
  
  tags = var.tags
}

resource "aws_ecs_task_definition" "subsquid_processor" {
  family                   = "subsquid-processor-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  
  # Use ARM architecture if Graviton is enabled
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = local.selected_config.use_graviton ? "ARM64" : "X86_64"
  }
  
  # Mount EFS volume
  volume {
    name = "subsquid-data"
    
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.subsquid.id
      transit_encryption = "ENABLED"
      
      authorization_config {
        access_point_id = aws_efs_access_point.subsquid.id
        iam             = "ENABLED"
      }
    }
  }
  
  # Container definition with command override for processor service
  container_definitions = jsonencode([
    merge(local.container_definition, {
      command = ["sqd", "process:prod"]  # Processor service command as per official docs
    })
  ])
  
  tags = var.tags
}

# Create separate ECS services for API and processor
resource "aws_ecs_service" "subsquid_api" {
  name            = "subsquid-api-${var.environment}"
  cluster         = aws_ecs_cluster.subsquid.id
  task_definition = aws_ecs_task_definition.subsquid_api.arn
  desired_count   = var.min_capacity
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.subsquid.id]
    assign_public_ip = false
  }
  
  # Load balancer configuration
  load_balancer {
    target_group_arn = aws_lb_target_group.subsquid.arn
    container_name   = "subsquid"
    container_port   = 4350  # GraphQL port as per official docs
  }
  
  # Enable capacity provider strategy for Spot instances
  capacity_provider_strategy {
    capacity_provider = local.selected_config.use_spot_instances ? "FARGATE_SPOT" : "FARGATE"
    weight            = 1
    base              = 1
  }
  
  # Service discovery for internal DNS
  service_registries {
    registry_arn = aws_service_discovery_service.subsquid_api.arn
  }
  
  # Enable circuit breaker
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  
  # Ignore changes to desired count for auto-scaling
  lifecycle {
    ignore_changes = [desired_count]
  }
  
  tags = var.tags
}

resource "aws_ecs_service" "subsquid_processor" {
  name            = "subsquid-processor-${var.environment}"
  cluster         = aws_ecs_cluster.subsquid.id
  task_definition = aws_ecs_task_definition.subsquid_processor.arn
  desired_count   = var.min_capacity
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.subsquid.id]
    assign_public_ip = false
  }
  
  # Enable capacity provider strategy for Spot instances
  capacity_provider_strategy {
    capacity_provider = local.selected_config.use_spot_instances ? "FARGATE_SPOT" : "FARGATE"
    weight            = 1
    base              = 1
  }
  
  # Service discovery for internal DNS
  service_registries {
    registry_arn = aws_service_discovery_service.subsquid_processor.arn
  }
  
  # Enable circuit breaker
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  
  # Ignore changes to desired count for auto-scaling
  lifecycle {
    ignore_changes = [desired_count]
  }
  
  tags = var.tags
}

# Auto-scaling
resource "aws_appautoscaling_target" "subsquid" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.subsquid.name}/${aws_ecs_service.subsquid.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  name               = "subsquid-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.subsquid.resource_id
  scalable_dimension = aws_appautoscaling_target.subsquid.scalable_dimension
  service_namespace  = aws_appautoscaling_target.subsquid.service_namespace
  
  target_tracking_scaling_policy_configuration {
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
    
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# Database - either serverless or standard based on optimization level
resource "aws_rds_cluster" "subsquid" {
  count                  = local.selected_config.database_serverless ? 1 : 0
  cluster_identifier     = "subsquid-${var.environment}"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "13.9"
  database_name          = "subsquid"
  master_username        = "subsquid"
  master_password        = random_password.db_password.result
  backup_retention_period = 7
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  db_subnet_group_name   = aws_db_subnet_group.subsquid.name
  vpc_security_group_ids = [aws_security_group.database.id]
  storage_encrypted      = true
  skip_final_snapshot    = true
  
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 4.0
  }
  
  tags = local.tags
}

resource "aws_rds_cluster_instance" "subsquid" {
  count                = local.selected_config.database_serverless ? 1 : 0
  identifier           = "subsquid-${var.environment}-0"
  cluster_identifier   = aws_rds_cluster.subsquid[0].id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.subsquid[0].engine
  engine_version       = aws_rds_cluster.subsquid[0].engine_version
  db_subnet_group_name = aws_db_subnet_group.subsquid.name
  
  tags = local.tags
}

# Standard RDS instance when serverless is not enabled
resource "aws_db_instance" "subsquid" {
  count                  = local.selected_config.database_serverless ? 0 : 1
  identifier             = "subsquid-${var.environment}"
  engine                 = "postgres"
  engine_version         = "13"
  instance_class         = local.selected_config.use_graviton ? "db.t4g.medium" : "db.t3.medium"
  allocated_storage      = 20
  storage_type           = "gp3"
  storage_encrypted      = true
  db_name                = "subsquid"
  username               = "subsquid"
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.subsquid.name
  vpc_security_group_ids = [aws_security_group.database.id]
  backup_retention_period = 7
  skip_final_snapshot    = true
  
  tags = local.tags
}

# Redis cache if enabled
resource "aws_elasticache_replication_group" "subsquid" {
  count                = local.selected_config.enable_caching ? 1 : 0
  replication_group_id = "subsquid-${var.environment}"
  description          = "Redis cache for Subsquid"
  node_type            = local.selected_config.use_graviton ? "cache.t4g.small" : "cache.t3.small"
  port                 = 6379
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.2"
  subnet_group_name    = aws_elasticache_subnet_group.subsquid[0].name
  security_group_ids   = [aws_security_group.cache[0].id]
  
  automatic_failover_enabled = true
  num_cache_clusters         = 2
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  tags = local.tags
}

# EFS for persistent storage
resource "aws_efs_file_system" "subsquid" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  
  dynamic "lifecycle_policy" {
    for_each = local.selected_config.efs_lifecycle_policy != null ? [1] : []
    content {
      transition_to_ia = local.selected_config.efs_lifecycle_policy
    }
  }
  
  tags = local.tags
}

# Add Redis cache for GraphQL responses
resource "aws_elasticache_subnet_group" "subsquid" {
  count      = var.enable_caching ? 1 : 0
  name       = "subsquid-cache-${var.environment}"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "subsquid" {
  count                = var.enable_caching ? 1 : 0
  replication_group_id = "subsquid-cache-${var.environment}"
  description          = "Redis cache for Subsquid GraphQL responses"
  node_type            = var.cache_instance_type
  port                 = 6379
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.2"
  subnet_group_name    = aws_elasticache_subnet_group.subsquid[0].name
  security_group_ids   = [aws_security_group.cache.id]
  
  automatic_failover_enabled = true
  multi_az_enabled           = true
  
  num_cache_clusters = 2
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  tags = merge(
    var.tags,
    {
      Name = "subsquid-cache-${var.environment}"
    }
  )
}

# Add security group for Redis cache
resource "aws_security_group" "cache" {
  count       = var.enable_caching ? 1 : 0
  name_prefix = "subsquid-cache-"
  vpc_id      = var.vpc_id
  description = "Security group for Subsquid Redis cache"

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.subsquid.id]
    description     = "Redis access from Subsquid servers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "subsquid-cache-${var.environment}"
    }
  )
}

# Standard RDS instance when serverless is not enabled
resource "aws_db_instance" "subsquid" {
  count                = var.database_serverless ? 0 : 1
  identifier           = "subsquid-${var.environment}"
  engine               = "postgres"
  engine_version       = "13.7"
  instance_class       = var.use_graviton_processors ? replace(var.database_instance_class, "db.t3", "db.t4g") : var.database_instance_class
  allocated_storage    = var.database_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.subsquid_db.arn
  db_name              = "subsquid"
  username             = "subsquid"
  password             = random_password.db_password.result
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name = aws_db_subnet_group.subsquid.name
  parameter_group_name = aws_db_parameter_group.subsquid.name
  multi_az             = var.database_multi_az
  backup_retention_period = var.database_backup_retention_period
  skip_final_snapshot  = true
  deletion_protection  = true
  
  performance_insights_enabled = var.enable_performance_insights
  
  tags = merge(
    var.tags,
    {
      Name = "subsquid-${var.environment}"
    }
  )
}

resource "aws_db_subnet_group" "subsquid" {
  name       = "subsquid-${var.environment}"
  subnet_ids = var.subnet_ids
  
  tags = var.tags
}

resource "aws_db_parameter_group" "subsquid" {
  name   = "subsquid-${var.environment}"
  family = "postgres13"
  
  parameter {
    name  = "log_connections"
    value = "1"
  }
  
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
  
  tags = var.tags
}

# Current region data source
data "aws_region" "current" {}

# VPC data source
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Auto-scaling configuration
resource "aws_appautoscaling_target" "subsquid" {
  count              = var.enable_auto_scaling ? 1 : 0
  max_capacity       = var.max_cluster_size
  min_capacity       = var.subsquid_cluster_size
  resource_id        = "service/${aws_ecs_cluster.subsquid.name}/${aws_ecs_service.subsquid.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU-based scaling
resource "aws_appautoscaling_policy" "cpu" {
  count              = var.enable_auto_scaling ? 1 : 0
  name               = "subsquid-cpu-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.subsquid[0].resource_id
  scalable_dimension = aws_appautoscaling_target.subsquid[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.subsquid[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# Memory-based scaling
resource "aws_appautoscaling_policy" "memory" {
  count              = var.enable_auto_scaling ? 1 : 0
  name               = "subsquid-memory-scaling-${var.environment}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.subsquid[0].resource_id
  scalable_dimension = aws_appautoscaling_target.subsquid[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.subsquid[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

# Queue-based scaling (custom metric)
resource "aws_appautoscaling_policy" "queue" {
  count              = var.enable_auto_scaling && var.enable_autoscaling_based_on_queue ? 1 : 0
  name               = "subsquid-queue-scaling-${var.environment}"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.subsquid[0].resource_id
  scalable_dimension = aws_appautoscaling_target.subsquid[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.subsquid[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 10
      scaling_adjustment          = 1
    }
    
    step_adjustment {
      metric_interval_lower_bound = 20
      scaling_adjustment          = 2
    }
  }
}

# KMS key for EFS encryption
resource "aws_kms_key" "subsquid_efs" {
  description             = "KMS key for Subsquid EFS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# KMS key for RDS encryption
resource "aws_kms_key" "subsquid_db" {
  description             = "KMS key for Subsquid RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "subsquid" {
  name              = "/ecs/subsquid-${var.environment}"
  retention_in_days = 30
  tags              = var.tags
}

# PostgreSQL Database
resource "aws_rds_cluster" "subsquid" {
  count                  = var.database_serverless ? 1 : 0
  cluster_identifier     = "subsquid-${var.environment}"
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "13.9"
  database_name          = var.database_name
  master_username        = var.database_username
  master_password        = random_password.db_password.result
  backup_retention_period = var.database_backup_retention_period
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  db_subnet_group_name   = aws_db_subnet_group.subsquid.name
  vpc_security_group_ids = [aws_security_group.database.id]
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.subsquid_db.arn
  skip_final_snapshot    = true
  deletion_protection    = true
  
  serverlessv2_scaling_configuration {
    min_capacity = var.database_min_capacity
    max_capacity = var.database_max_capacity
  }
  
  tags = merge(
    var.tags,
    {
      Name = "subsquid-${var.environment}"
    }
  )
}

resource "aws_rds_cluster_instance" "subsquid" {
  count                = var.database_serverless ? 2 : 0
  identifier           = "subsquid-${var.environment}-${count.index}"
  cluster_identifier   = aws_rds_cluster.subsquid[0].id
  instance_class       = var.use_graviton_processors ? "db.serverless" : "db.serverless"
  engine               = aws_rds_cluster.subsquid[0].engine
  engine_version       = aws_rds_cluster.subsquid[0].engine_version
  db_subnet_group_name = aws_db_subnet_group.subsquid.name
  
  performance_insights_enabled = var.enable_performance_insights
  
  tags = merge(
    var.tags,
    {
      Name = "subsquid-${var.environment}-${count.index}"
    }
  )
}

# Add read replicas for high-traffic scenarios
resource "aws_rds_cluster_instance" "read_replica" {
  count                = var.database_serverless && var.enable_read_replicas ? var.read_replica_count : 0
  identifier           = "subsquid-${var.environment}-readonly-${count.index}"
  cluster_identifier   = aws_rds_cluster.subsquid[0].id
  instance_class       = var.use_graviton_processors ? "db.serverless" : "db.serverless"
  engine               = aws_rds_cluster.subsquid[0].engine
  engine_version       = aws_rds_cluster.subsquid[0].engine_version
  db_subnet_group_name = aws_db_subnet_group.subsquid.name
  
  performance_insights_enabled = var.enable_performance_insights
  
  tags = merge(
    var.tags,
    {
      Name = "subsquid-${var.environment}-readonly-${count.index}"
    }
  )
}

# Add read replicas for non-serverless database
resource "aws_db_instance" "read_replica" {
  count                  = !var.database_serverless && var.enable_read_replicas ? var.read_replica_count : 0
  identifier             = "subsquid-${var.environment}-readonly-${count.index}"
  replicate_source_db    = aws_db_instance.subsquid[0].id
  instance_class         = var.use_graviton_processors ? replace(var.database_instance_class, "db.t3", "db.t4g") : var.database_instance_class
  storage_type           = "gp3"
  vpc_security_group_ids = [aws_security_group.database.id]
  
  performance_insights_enabled = var.enable_performance_insights
  
  tags = merge(
    var.tags,
    {
      Name = "subsquid-${var.environment}-readonly-${count.index}"
    }
  )
}

# Standard RDS instance when serverless is not enabled
resource "aws_db_instance" "subsquid" {
  count                = var.database_serverless ? 0 : 1
  identifier           = "subsquid-${var.environment}"
  engine               = "postgres"
  engine_version       = "13.7"
  instance_class       = var.use_graviton_processors ? replace(var.database_instance_class, "db.t3", "db.t4g") : var.database_instance_class
  allocated_storage    = var.database_allocated_storage
  storage_type         = "gp3"
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.subsquid_db.arn
  db_name              = var.database_name
  username             = var.database_username
  password             = random_password.db_password.result
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name = aws_db_subnet_group.subsquid.name
  parameter_group_name = aws_db_parameter_group.subsquid.name
  multi_az             = var.database_multi_az
  backup_retention_period = var.database_backup_retention_period
  skip_final_snapshot  = true
  deletion_protection  = true
  
  performance_insights_enabled = var.enable_performance_insights
  
  tags = merge(
    var.tags,
    {
      Name = "subsquid-${var.environment}"
    }
  )
}

resource "aws_db_subnet_group" "subsquid" {
  name       = "subsquid-${var.environment}"
  subnet_ids = var.subnet_ids
  
  tags = var.tags
}

resource "aws_db_parameter_group" "subsquid" {
  name   = "subsquid-${var.environment}"
  family = "postgres13"
  
  parameter {
    name  = "log_connections"
    value = "1"
  }
  
  parameter {
    name  = "log_disconnections"
    value = "1"
  }
  
  tags = var.tags
}

# Add Redis cache for GraphQL responses
resource "aws_elasticache_subnet_group" "subsquid" {
  count      = var.enable_caching ? 1 : 0
  name       = "subsquid-cache-${var.environment}"
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_replication_group" "subsquid" {
  count                = var.enable_caching ? 1 : 0
  replication_group_id = "subsquid-cache-${var.environment}"
  description          = "Redis cache for Subsquid GraphQL responses"
  node_type            = var.cache_instance_type
  port                 = 6379
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.2"
  subnet_group_name    = aws_elasticache_subnet_group.subsquid[0].name
  security_group_ids   = [aws_security_group.cache.id]
  
  automatic_failover_enabled = true
  multi_az_enabled           = true
  
  num_cache_clusters = 2
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  tags = merge(
    var.tags,
    {
      Name = "subsquid-cache-${var.environment}"
    }
  )
}

# Add security group for Redis cache
resource "aws_security_group" "cache" {
  count       = var.enable_caching ? 1 : 0
  name_prefix = "subsquid-cache-"
  vpc_id      = var.vpc_id
  description = "Security group for Subsquid Redis cache"

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.subsquid.id]
    description     = "Redis access from Subsquid servers"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(
    var.tags,
    {
      Name = "subsquid-cache-${var.environment}"
    }
  )
}

# Update container definition with optimizations
locals {
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
  
  # Add connection pooling if enabled
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
  
  # Add query caching if enabled
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
  
  # Add compression if enabled
  compression_env = var.enable_compression ? [
    {
      name  = "ENABLE_COMPRESSION"
      value = "true"
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
}

# Update security group to include the correct ports
resource "aws_security_group" "subsquid" {
  name_prefix = "subsquid-server-"
  vpc_id      = var.vpc_id
  description = "Security group for Subsquid server tasks"
  
  # Subsquid GraphQL API port
  ingress {
    from_port       = 4350  # GraphQL port as per official docs
    to_port         = 4350
    protocol        = "tcp"
    cidr_blocks     = [data.aws_vpc.selected.cidr_block]
    description     = "Subsquid GraphQL API port - VPC internal access only"
  }
  
  # Subsquid Prometheus metrics port
  ingress {
    from_port       = 3000  # Prometheus port as per official docs
    to_port         = 3000
    protocol        = "tcp"
    cidr_blocks     = [data.aws_vpc.selected.cidr_block]
    description     = "Prometheus metrics endpoint"
  }
  
  # EFS access
  ingress {
    from_port = 2049
    to_port   = 2049
    protocol  = "tcp"
    self      = true
    description = "EFS access"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }
  
  tags = merge(
    var.tags,
    {
      Name = "subsquid-server-${var.environment}"
    }
  )
} 