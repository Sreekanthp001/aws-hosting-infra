
# ECS Cluster

resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

# ECS Task Definitions
resource "aws_ecs_task_definition" "task" {
  for_each = var.services

  family                   = "${each.key}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  #execution_role_arn       = var.iam_task_exec_role_arn
  #task_role_arn            = var.iam_task_role_arn

  container_definitions = jsonencode([{
    name      = each.key
    image     = each.value.image
    essential = true
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
  }])
}

##################################
# Security Group for ECS Tasks
##################################
resource "aws_security_group" "ecs" {
  name        = "ecs-sg-${var.environment}"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################################
# Target Groups
##################################
resource "aws_lb_target_group" "tg" {
  for_each = var.services

  name        = "${each.key}-${var.environment}-tg"
  port        = each.value.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

##################################
# ECS Services
##################################
resource "aws_ecs_service" "svc" {
  for_each        = var.services

  name            = "${each.key}-${var.environment}-svc"
  cluster         = aws_ecs_cluster.this.id
  launch_type     = "FARGATE"
  desired_count   = 2

  task_definition = aws_ecs_task_definition.task[each.key].arn

  network_configuration {
    subnets          = var.private_subnet_ids
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg[each.key].arn
    container_name   = each.key
    container_port   = each.value.port   
  }

  depends_on = [aws_lb_target_group.tg]
}


# CloudWatch Logs
resource "aws_cloudwatch_log_group" "logs" {
  for_each          = var.services
  name              = "/ecs/${each.key}"
  retention_in_days = 14
}