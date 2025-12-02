resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
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


resource "aws_iam_role" "ecs_task_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_security_group" "ecs" {
  name        = "ecs-sg-${var.environment}"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  # Only ALB can reach ECS tasks
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

resource "aws_ecs_task_definition" "task" {
  for_each = var.services

  family                   = "${each.key}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_task_role.arn

  container_definitions = jsonencode([
  {
    name      = each.key
    image     = each.value.image
    essential = true

    environment = [
      {
        name  = "MAIL_FROM"
        value = "admin@${var.domain}"
      }
    ]

    secrets = [
      {
        name      = "SMTP_USERNAME"
        valueFrom = aws_secretsmanager_secret.ses_creds.arn
      },
      {
        name      = "SMTP_PASSWORD"
        valueFrom = aws_secretsmanager_secret.ses_creds.arn
      }
    ]

    portMappings = [{
      containerPort = each.value.port
      protocol      = "tcp"
    }]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${each.key}"
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = each.key
      }
    }
  }
])


resource "aws_secretsmanager_secret" "ses_creds" {
  name = "ses/email-credentials-tf"
}

resource "aws_secretsmanager_secret_version" "ses_creds" {
  secret_id     = aws_secretsmanager_secret.ses_creds.id
  secret_string = jsonencode({
    SMTP_USERNAME = var.smtp_username
    SMTP_PASSWORD = var.smtp_password
    SMTP_HOST     = "email-smtp.${var.aws_region}.amazonaws.com"
    SMTP_PORT     = "587"
    MAIL_FROM     = "admin@${var.domain}"
  })
}

resource "aws_cloudwatch_log_group" "logs" {
  for_each          = var.services
  name              = "/ecs/${each.key}"
  retention_in_days = 14
}

resource "aws_ecs_service" "svc" {
  for_each = var.services

  name             = "${each.key}-${var.environment}-svc"
  cluster          = aws_ecs_cluster.this.id
  launch_type      = "FARGATE"
  desired_count    = 2
  platform_version = "LATEST"

  task_definition = aws_ecs_task_definition.task[each.key].arn

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arns[each.key]
    container_name   = each.key
    container_port   = each.value.port
  }

  # optional, but good so logs exist before tasks start
  depends_on = [
    aws_cloudwatch_log_group.logs
  ]
}
