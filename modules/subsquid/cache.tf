# -----------------------------------------------------
# Redis cache resources
# -----------------------------------------------------

resource "aws_elasticache_subnet_group" "subsquid" {
  count      = local.effective_config.enable_caching ? 1 : 0
  name       = local.name_prefix
  subnet_ids = var.subnet_ids
  
  tags = local.tags
}

resource "aws_elasticache_replication_group" "subsquid" {
  count                = local.effective_config.enable_caching ? 1 : 0
  replication_group_id = local.name_prefix
  description          = "Redis cache for Subsquid GraphQL responses"
  node_type            = var.cache_instance_type
  port                 = 6379
  parameter_group_name = "default.redis6.x"
  engine_version       = "6.2"
  subnet_group_name    = aws_elasticache_subnet_group.subsquid[0].name
  security_group_ids   = [aws_security_group.cache[0].id]
  
  automatic_failover_enabled = true
  multi_az_enabled           = true
  
  num_cache_clusters = 2
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token[0].result
  
  tags = local.tags
} 