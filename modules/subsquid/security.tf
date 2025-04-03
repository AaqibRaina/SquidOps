resource "aws_security_group" "subsquid" {
  name_prefix = "subsquid-server-"
  vpc_id      = var.vpc_id

  # Add description for better documentation
  description = "Security group for Subsquid server tasks"

  # Subsquid GraphQL API port - only allow internal VPC CIDR
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    cidr_blocks     = [data.aws_vpc.selected.cidr_block]
    description     = "Subsquid GraphQL API port - VPC internal access only"
  }

  # Add explicit deny for public access
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Explicitly deny public access"
  }

  # Subsquid monitoring - restrict to internal monitoring systems
  ingress {
    from_port       = 9090
    to_port         = 9090
    protocol        = "tcp"
    cidr_blocks     = [data.aws_vpc.selected.cidr_block]
    description     = "Prometheus metrics endpoint"
  }

  # EFS access - only from Subsquid tasks
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
    from_port   = 9090
    to_port     = 9090
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

resource "aws_security_group" "efs" {
  name_prefix = "subsquid-efs-"
  vpc_id      = var.vpc_id
  description = "Security group for Subsquid EFS"

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.subsquid.id]
    description     = "NFS access from Subsquid servers"
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
      Name = "subsquid-efs-${var.environment}"
    }
  )
}

resource "aws_security_group" "database" {
  name_prefix = "subsquid-database-"
  vpc_id      = var.vpc_id
  description = "Security group for Subsquid database"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.subsquid.id]
    description     = "PostgreSQL access from Subsquid servers"
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
      Name = "subsquid-database-${var.environment}"
    }
  )
} 