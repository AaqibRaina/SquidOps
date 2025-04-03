output "endpoint" {
  description = "Subsquid GraphQL API endpoint URL"
  value       = "http://${aws_lb.subsquid.dns_name}:4350/graphql"
}

output "prometheus_endpoint" {
  description = "Prometheus metrics endpoint URL"
  value       = "http://${aws_service_discovery_service.subsquid_processor.name}.${aws_service_discovery_private_dns_namespace.subsquid.name}:3000"
}

output "database_endpoint" {
  description = "Database endpoint"
  value       = local.database_host
}

output "database_password" {
  description = "Database password"
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
  description = "Subsquid API endpoint URL"
  value       = var.enable_load_balancer ? "http://subsquid.${var.environment}.internal:3000/graphql" : "http://${aws_service_discovery_service.subsquid.name}.${aws_service_discovery_private_dns_namespace.subsquid.name}:3000/graphql"
}

output "load_balancer_dns" {
  description = "DNS name of the Subsquid load balancer"
  value       = var.enable_load_balancer ? aws_lb.subsquid[0].dns_name : null
}

output "client_security_group_id" {
  description = "Security group ID for Subsquid clients"
  value       = aws_security_group.subsquid_client.id
}

output "database_username" {
  description = "PostgreSQL database username"
  value       = var.database_username
}

output "api_key" {
  description = "API key for Subsquid GraphQL endpoint (if authentication is enabled)"
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
  description = "ECS cluster name"
  value       = aws_ecs_cluster.subsquid.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.subsquid.name
}

output "cache_endpoint" {
  description = "Redis cache endpoint"
  value       = var.enable_caching ? aws_elasticache_replication_group.subsquid[0].primary_endpoint_address : null
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