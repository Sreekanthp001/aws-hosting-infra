resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

# -------------------------------------------------
# ECS Execution Role (pull images + read secrets)
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

resource "aws_iam_policy" "ecs_secrets_access" {
  name   = "ecsSecretsAccessPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = "arn:aws:secretsmanager:us-east-1:${var.aws_account_id}:secret:ses/email-credentials-tf-2-*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_secrets_access_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_secrets_access.arn
}

# -------------------------------------------------
# ECS Task Runtime Role (inside the container)
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
# ECS Security Group
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

# -------------------------------------------------
# SES SMTP Credentials Secret
# -------------------------------------------------
resource "aws_secretsmanager_secret" "ses_creds" {
  name = "ses/email-credentials-tf-2"
}

resource "aws_secretsmanager_secret_version" "ses_creds_version" {
  secret_id = aws_secretsmanager_secret.ses_creds.id

  secret_string = jsonencode({
    SMTP_USERNAME = var.smtp_username
    SMTP_PASSWORD = var.smtp_password
    SMTP_HOST     = "email-smtp.${var.aws_region}.amazonaws.com"
    SMTP_PORT     = "587"
    MAIL_FROM     = "admin@${var.domain}"
  })
}

# -------------------------------------------------
# CloudWatch Logs for each service
# ------------------------------------------
