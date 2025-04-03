# -----------------------------------------------------
# EFS resources
# -----------------------------------------------------

resource "aws_efs_file_system" "subsquid" {
  encrypted        = true
  performance_mode = "generalPurpose"
  throughput_mode  = var.efs_throughput_mode
  
  dynamic "lifecycle_policy" {
    for_each = local.effective_config.efs_lifecycle_policy != null ? [1] : []
    content {
      transition_to_ia = local.effective_config.efs_lifecycle_policy
    }
  }
  
  tags = local.tags
}

resource "aws_efs_mount_target" "subsquid" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.subsquid.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "subsquid" {
  file_system_id = aws_efs_file_system.subsquid.id
  
  posix_user {
    gid = 1000
    uid = 1000
  }
  
  root_directory {
    path = "/subsquid"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "755"
    }
  }
  
  tags = local.tags
} 