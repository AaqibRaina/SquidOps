# -----------------------------------------------------
# ECS resources
# -----------------------------------------------------

resource "aws_ecs_cluster" "subsquid" {
  name = local.name_prefix
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  
  tags = local.tags
}

resource "aws_ecs_task_definition" "subsquid" {
  family                   = local.name_prefix
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn
  
  container_definitions = jsonencode([
    merge(local.container_definition, {
      command = var.container_command != null ? var.container_command : null,
      image_hash = md5(var.subsquid_image)
    })
  ])
  
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
  
  # Modify the lifecycle block to only ignore specific attributes, not container_definitions
  lifecycle {
    ignore_changes = [
      # Ignore changes to tags
      tags
    ]
  }
  
  tags = local.tags
}

resource "aws_ecs_service" "subsquid" {
  name            = local.name_prefix
  cluster         = aws_ecs_cluster.subsquid.id
  task_definition = aws_ecs_task_definition.subsquid.arn
  desired_count   = var.min_capacity
  
  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.subsquid.id]
    assign_public_ip = false
  }
  
  dynamic "load_balancer" {
    for_each = var.enable_load_balancer ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.subsquid[0].arn
      container_name   = "subsquid"
      container_port   = 4350
    }
  }
  
  capacity_provider_strategy {
    capacity_provider = local.effective_config.use_spot_instances ? "FARGATE_SPOT" : "FARGATE"
    weight            = 1
  }
  
  tags = local.tags
}

# Auto-scaling configuration
resource "aws_appautoscaling_target" "subsquid" {
  count              = var.enable_auto_scaling ? 1 : 0
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.subsquid.name}/${aws_ecs_service.subsquid.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "cpu" {
  count              = var.enable_auto_scaling ? 1 : 0
  name               = "${local.name_prefix}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.subsquid[0].resource_id
  scalable_dimension = aws_appautoscaling_target.subsquid[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.subsquid[0].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count              = var.enable_auto_scaling ? 1 : 0
  name               = "${local.name_prefix}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.subsquid[0].resource_id
  scalable_dimension = aws_appautoscaling_target.subsquid[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.subsquid[0].service_namespace
  
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}