# -----------------------------------------------------
# Database resources
# -----------------------------------------------------

# Aurora Serverless v2 (if database_serverless = true)
resource "aws_rds_cluster" "subsquid" {
  count                  = local.effective_config.database_serverless ? 1 : 0
  cluster_identifier     = local.name_prefix
  engine                 = "aurora-postgresql"
  engine_mode            = "provisioned"
  engine_version         = "13.9"
  database_name          = var.database_name
  master_username        = var.database_username
  master_password        = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.subsquid.name
  vpc_security_group_ids = [aws_security_group.database.id]
  
  serverlessv2_scaling_configuration {
    min_capacity = var.database_min_capacity
    max_capacity = var.database_max_capacity
  }
  
  skip_final_snapshot = true
  
  tags = local.tags
}

resource "aws_rds_cluster_instance" "subsquid" {
  count               = local.effective_config.database_serverless ? 1 : 0
  identifier          = "${local.name_prefix}-instance-1"
  cluster_identifier  = aws_rds_cluster.subsquid[0].id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.subsquid[0].engine
  engine_version      = aws_rds_cluster.subsquid[0].engine_version
  db_subnet_group_name = aws_db_subnet_group.subsquid.name
  
  tags = local.tags
}

# Standard RDS (if database_serverless = false)
resource "aws_db_instance" "subsquid" {
  count                  = local.effective_config.database_serverless ? 0 : 1
  identifier             = local.name_prefix
  engine                 = "postgres"
  engine_version         = "13"
  instance_class         = var.database_instance_type
  allocated_storage      = var.database_allocated_storage
  max_allocated_storage  = var.database_max_allocated_storage
  storage_type           = "gp3"
  
  db_name                = var.database_name
  username               = var.database_username
  password               = random_password.db_password.result
  
  db_subnet_group_name   = aws_db_subnet_group.subsquid.name
  vpc_security_group_ids = [aws_security_group.database.id]
  parameter_group_name   = aws_db_parameter_group.subsquid.name
  
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"
  
  skip_final_snapshot     = true
  
  tags = local.tags
}

# Subnet group and parameter group
resource "aws_db_subnet_group" "subsquid" {
  name       = local.name_prefix
  subnet_ids = var.subnet_ids
  
  tags = local.tags
}

resource "aws_db_parameter_group" "subsquid" {
  name   = local.name_prefix
  family = "postgres13"
  
  parameter {
    name  = "log_connections"
    value = "1"
  }
  
  tags = local.tags
} 