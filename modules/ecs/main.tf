resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
}

# Example service for each site. Task definitions use placeholders image; pipeline will update image tag.
resource "aws_ecs_task_definition" "task" {
  for_each = { for k in keys(var.alb_target_groups) : k => k }
  family = "${each.key}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "512"
  memory = "1024"
  execution_role_arn = var.iam_task_exec_role_arn
  task_role_arn = var.iam_task_role_arn
  container_definitions = jsonencode([{
    name = each.key
    image = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${each.key}-${var.environment}:latest"
    essential = true
    portMappings = [{ containerPort = 80, protocol = "tcp" }]
    logConfiguration = { logDriver = "awslogs", options = { "awslogs-group" = "/ecs/${each.key}", "awslogs-region" = var.aws_region, "awslogs-stream-prefix" = each.key } }
  }])
}

# ALB Target Groups for Fargate
resource "aws_lb_target_group" "tg" {
  for_each = var.services  # e.g., map of service names

  name        = "${each.key}-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"   # <- THIS IS CRUCIAL for Fargate

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# ECS Service
resource "aws_ecs_service" "svc" {
  for_each        = aws_ecs_task_definition.task
  name            = "${each.key}-${var.environment}-svc"
  cluster         = aws_ecs_cluster.this.id
  launch_type     = "FARGATE"
  desired_count   = 2
  task_definition = each.value.arn

  network_configuration {
    subnets         = var.private_subnet_ids
    assign_public_ip = false
    security_groups  = var.ecs_sg_ids
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg[each.key].arn
    container_name   = each.key
    container_port   = 80
  }

  depends_on = [aws_lb_target_group.tg]
}



resource "aws_cloudwatch_log_group" "logs" {
  for_each = aws_ecs_task_definition.task
  name = "/ecs/${each.key}"
  retention_in_days = 14
}
