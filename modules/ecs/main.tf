resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

# -------------------------------------------------
# ECS Execution Role (for pulling images + secrets)
# -------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Allow ECS Execution Role to read SES SMTP secret
resource "aws_iam_policy" "ecs_secrets_access" {
  name   = "ecsSecretsAccessPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:us-east-1:535462128585:secret:ses/email-credentials-tf-2-*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_access_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_access.arn
}

# -------------------------------------------------
# ECS Task Runtime Role (inside container)
# -------------------------------------------------
resource "aws_iam_role" "ecs_task_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Allow app to send via SES
resource "aws_iam_policy" "ecs_ses_policy" {
  name = "ecsSendEmailOnly"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_ses_policy_attach" {
  role       = aws_iam_role.ecs_task_task_role.name
  policy_arn = aws_iam_policy.ecs_ses_policy.arn
}

# -------------------------------------------------
# Security Group for ECS Tasks
# -------------------------------------------------
resource "aws_security_group" "ecs" {
  name        = "ecs-sg-${var.environment}"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --------------------------------
