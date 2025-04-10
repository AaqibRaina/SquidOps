output "endpoint" {
  description = "Subsquid GraphQL API endpoint URL"
  value       = var.enable_load_balancer ? "http://${aws_lb.subsquid[0].dns_name}:4350/graphql" : null
}

output "prometheus_endpoint" {
  description = "Prometheus metrics endpoint URL"
  value       = "http://${aws_service_discovery_service.subsquid.name}.${aws_service_discovery_private_dns_namespace.subsquid.name}:3000"
}

output "database_endpoint" {
  description = "Endpoint of the database"
  value       = local.database_host
  sensitive   = true
}

output "database_name" {
  description = "Name of the database"
  value       = var.database_name
}

output "database_username" {
  description = "Username for the database"
  value       = var.database_username
  sensitive   = true
}

output "database_password" {
  description = "Password for the database"
  value       = random_password.db_password.result
  sensitive   = true
}

output "optimization_level" {
  description = "Applied cost optimization level"
  value       = var.cost_optimization_level
}

output "estimated_monthly_savings" {
  description = "Estimated monthly savings compared to Subsquid Cloud"
  value       = {
    basic      = "60-70%"
    balanced   = "85-90%"
    aggressive = "90-95%"
  }[var.cost_optimization_level]
}

output "subsquid_endpoint" {
  description = "Endpoint URL for the Subsquid GraphQL API"
  value       = var.enable_load_balancer ? "http://subsquid.${var.project}.${var.environment}.internal" : null
}

output "load_balancer_dns" {
  description = "DNS name of the load balancer"
  value       = var.enable_load_balancer ? aws_lb.subsquid[0].dns_name : null
}

output "client_security_group_id" {
  description = "ID of the security group for clients accessing Subsquid"
  value       = aws_security_group.client.id
}

output "api_key" {
  description = "API key for the GraphQL API (if enabled)"
  value       = var.enable_api_auth ? random_password.api_key[0].result : null
  sensitive   = true
}

output "cloudwatch_log_group" {
  description = "CloudWatch Log Group for Subsquid logs"
  value       = aws_cloudwatch_log_group.subsquid.name
}

output "efs_id" {
  description = "EFS file system ID"
  value       = aws_efs_file_system.subsquid.id
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.subsquid.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.subsquid.name
}

output "cache_endpoint" {
  description = "Redis cache endpoint"
  value       = var.enable_caching ? aws_elasticache_replication_group.subsquid[0].primary_endpoint_address : null
}

output "cache_enabled" {
  description = "Whether Redis caching is enabled"
  value       = var.enable_caching
}

output "using_spot_instances" {
  description = "Whether Spot instances are being used"
  value       = var.use_spot_instances
}

output "using_graviton" {
  description = "Whether Graviton processors are being used"
  value       = var.use_graviton_processors
}

output "using_serverless_db" {
  description = "Whether serverless database is being used"
  value       = var.database_serverless
}

output "security_group_id" {
  description = "ID of the security group for Subsquid services"
  value       = aws_security_group.subsquid.id
}

output "effective_config" {
  description = "Effective configuration after applying optimization level and overrides"
  value       = local.effective_config
}

output "graphql_endpoint" {
  description = "GraphQL API endpoint"
  value       = var.enable_load_balancer ? "http://${aws_lb.subsquid[0].dns_name}:${var.graphql_port}/graphql" : null
} 