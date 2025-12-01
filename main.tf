# infra/main.tf
module "vpc" {
  source = "./modules/vpc"
  name   = "venturemond"
  cidr   = "10.0.0.0/16"
  public_azs  = ["us-east-1a","us-east-1b"]
  private_azs = ["us-east-1a","us-east-1b"]
  nat_azs     = ["us-east-1a","us-east-1b"]
  
}

resource "aws_ecs_cluster" "this" {
  name = "venturemond-cluster"
}

# IAM role for task execution
resource "aws_iam_role" "ecs_task_exec" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "app" {
  name = "/ecs/venturemond"
  retention_in_days = 14
}

# Task definition (nginx sample)
resource "aws_ecs_task_definition" "app" {
  family = "venturemond-nginx"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.ecs_task_exec.arn

  container_definitions = jsonencode([
  {
    name  = "nginx"
    image = "nginx:stable-alpine"

    portMappings = [
      { containerPort = 80, protocol = "tcp" }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.app.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "nginx"
      }
    }
  }
])
}

# ALB
resource "aws_lb" "alb" {
  name = "venturemond-alb"
  internal = false
  load_balancer_type = "application"
  subnets = module.vpc.public_subnets
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_security_group" "app_sg" {
  name        = "ecs-app-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = module.vpc.vpc_id

  # Allow traffic FROM ALB to app containers
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Allow tasks to access internet via NAT
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecs-app-sg"
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "allow HTTP/HTTPS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "egress all"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-sg"
  }
}


# Target group
resource "aws_lb_target_group" "tg" {
  name = "venturemond-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
    matcher = "200-399"
    interval = 30
  }
}
# Target group for venturemond (ECS)
resource "aws_lb_target_group" "tg_venturemond" {
  name     = "tg-venturemond"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# Target group for sampleclient (if using ECS)
resource "aws_lb_target_group" "tg_sampleclient" {
  name     = "tg-sampleclient"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# Listener rule for venturemond (host-based)
resource "aws_lb_listener_rule" "rule_venturemond" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_venturemond.arn
  }
  condition {
    host_header { values = ["venturemond.com", "www.venturemond.com"] }
  }
}

# Listener rule for sampleclient (host-based)
resource "aws_lb_listener_rule" "rule_sampleclient" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 110
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_sampleclient.arn
  }
  condition {
    host_header { values = ["sampleclient.com", "www.sampleclient.com"] }
  }
}


# Listener (HTTP -> redirect to HTTPS) and HTTPS listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ACM certificate (request) - will require DNS validation
resource "aws_acm_certificate" "cert" {
  domain_name = "sree84s.site"
  validation_method = "DNS"
  subject_alternative_names = ["www.sree84s.site"]
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "cert_validation" {
  for_each = { for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => dvo }
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.cert_validation : r.fqdn]
  depends_on = [aws_route53_record.cert_validation]
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# ECS Service (Fargate)
resource "aws_ecs_service" "app" {
  name = "venturemond-service"
  cluster = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count = 2
  launch_type = "FARGATE"
  network_configuration {
    subnets = module.vpc.private_subnets
    security_groups = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name = "nginx"
    container_port = 80
  }
  depends_on = [aws_lb_listener.https]
}
