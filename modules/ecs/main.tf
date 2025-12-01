##############################
# ECS Cluster
##############################
resource "aws_ecs_cluster" "this" {
  name = var.ecs_cluster_name
}

##############################
# ECS Task Definition
##############################
resource "aws_ecs_task_definition" "task" {
  for_each = var.services

  family                   = "${each.key}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

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

##############################
# ECS Service
##############################
resource "aws_ecs_service" "svc" {
  for_each        = aws_ecs_task_definition.task
  name            = "${each.key}-${var.environment}-svc"
  cluster         = aws_ecs_cluster.this.id
  launch_type     = "FARGATE"
  desired_count   = 2
  task_definition = each.value.arn

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

##############################
# CloudWatch Logs
##############################
resource "aws_cloudwatch_log_group" "logs" {
  for_each          = var.services
  name              = "/ecs/${each.key}"
  retention_in_days = 14
}
