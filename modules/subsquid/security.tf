# -----------------------------------------------------
# Security groups
# -----------------------------------------------------

# Security group for Subsquid services
resource "aws_security_group" "subsquid" {
  name        = "${local.name_prefix}-service"
  description = "Security group for Subsquid services"
  vpc_id      = var.vpc_id
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-service"
    }
  )
}

resource "aws_security_group_rule" "subsquid_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.subsquid.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Security group for database
resource "aws_security_group" "database" {
  name        = "${local.name_prefix}-database"
  description = "Security group for Subsquid database"
  vpc_id      = var.vpc_id
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-database"
    }
  )
}

resource "aws_security_group_rule" "database_ingress" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.database.id
  source_security_group_id = aws_security_group.subsquid.id
  description              = "Allow Subsquid to access database"
}

resource "aws_security_group_rule" "database_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.database.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Security group for ALB
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb"
  description = "Security group for Subsquid ALB"
  vpc_id      = var.vpc_id
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-alb"
    }
  )
}

resource "aws_security_group_rule" "alb_ingress_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = var.alb_ingress_cidr_blocks
  description       = "Allow HTTP traffic to ALB"
}

resource "aws_security_group_rule" "alb_ingress_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = var.alb_ingress_cidr_blocks
  description       = "Allow HTTPS traffic to ALB"
}

resource "aws_security_group_rule" "alb_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Client security group for other services to access Subsquid
resource "aws_security_group" "client" {
  name        = "${local.name_prefix}-client"
  description = "Security group for clients accessing Subsquid"
  vpc_id      = var.vpc_id
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-client"
    }
  )
}

resource "aws_security_group_rule" "subsquid_ingress_from_client" {
  type                     = "ingress"
  from_port                = var.graphql_port
  to_port                  = var.graphql_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.subsquid.id
  source_security_group_id = aws_security_group.client.id
  description              = "Allow clients to access Subsquid GraphQL API"
}

resource "aws_security_group_rule" "subsquid_ingress_from_alb" {
  type                     = "ingress"
  from_port                = var.graphql_port
  to_port                  = var.graphql_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.subsquid.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow ALB to access Subsquid GraphQL API"
}

resource "aws_security_group_rule" "subsquid_ingress_metrics" {
  type                     = "ingress"
  from_port                = var.metrics_port
  to_port                  = var.metrics_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.subsquid.id
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow ALB to access Subsquid metrics"
}

# Security group for EFS
resource "aws_security_group" "efs" {
  name        = "${local.name_prefix}-efs"
  description = "Security group for Subsquid EFS"
  vpc_id      = var.vpc_id
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-efs"
    }
  )
}

resource "aws_security_group_rule" "efs_ingress" {
  type                     = "ingress"
  from_port                = 2049
  to_port                  = 2049
  protocol                 = "tcp"
  security_group_id        = aws_security_group.efs.id
  source_security_group_id = aws_security_group.subsquid.id
  description              = "Allow Subsquid to access EFS"
}

resource "aws_security_group_rule" "efs_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.efs.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Security group for Redis cache
resource "aws_security_group" "cache" {
  count       = local.effective_config.enable_caching ? 1 : 0
  name        = "${local.name_prefix}-cache"
  description = "Security group for Subsquid Redis cache"
  vpc_id      = var.vpc_id
  
  tags = merge(
    local.tags,
    {
      Name = "${local.name_prefix}-cache"
    }
  )
}

resource "aws_security_group_rule" "cache_ingress" {
  count                    = local.effective_config.enable_caching ? 1 : 0
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cache[0].id
  source_security_group_id = aws_security_group.subsquid.id
  description              = "Allow Subsquid to access Redis"
}

resource "aws_security_group_rule" "cache_egress" {
  count             = local.effective_config.enable_caching ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.cache[0].id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

resource "aws_security_group" "subsquid_client" {
  name_prefix = "subsquid-client-"
  vpc_id      = var.vpc_id
  description = "Security group for Subsquid clients"

  # Only allow internal VPC access
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Allow all inbound traffic from VPC"
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
      Name = "subsquid-client-${var.environment}"
    }
  )
}

resource "aws_security_group" "subsquid_monitoring" {
  name_prefix = "subsquid-monitoring-"
  vpc_id      = var.vpc_id
  description = "Security group for Subsquid monitoring"

  ingress {
    from_port   = var.monitoring_port
    to_port     = var.monitoring_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
    description = "Prometheus metrics endpoint"
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
      Name = "subsquid-monitoring-${var.environment}"
    }
  )
} 