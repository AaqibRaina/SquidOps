# Create IAM roles for ECS tasks
resource "aws_iam_role" "ecs_execution" {
  name = "subsquid-ecs-execution-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_execution" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task" {
  name = "subsquid-ecs-task-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Add policy for EFS access
resource "aws_iam_policy" "efs_access" {
  name        = "subsquid-efs-access-${var.environment}"
  description = "Allow Subsquid tasks to access EFS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = aws_efs_file_system.subsquid.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "efs_access" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.efs_access.arn
}

# Add policy for CloudWatch logs
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "subsquid-cloudwatch-logs-${var.environment}"
  description = "Allow Subsquid tasks to write to CloudWatch logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "${aws_cloudwatch_log_group.subsquid.arn}:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
} 