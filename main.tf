#########################################
# VPC
#########################################
module "vpc" {
  source               = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  availability_zones   = var.azs

  tags = {
    Environment = var.environment
  }
}

#########################################
# ALB SG
#########################################
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

#########################################
# ALB
#########################################
module "alb" {
  source = "./modules/alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_id = aws_security_group.alb_sg.id

  domain          = var.domain
  hosted_zone_id  = var.hosted_zone_id
  aws_region      = var.aws_region
  services        = keys(var.services)
}

resource "aws_lb_listener_rule" "sampleclient" {
  listener_arn = module.alb.https_listener_arn
  priority     = 1

  condition {
    host_header {
      values = ["sampleclient.${var.domain}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arns["sampleclient"]
  }
}

resource "aws_lb_listener_rule" "venturemond" {
  listener_arn = module.alb.https_listener_arn
  priority     = 2

  condition {
    host_header {
      values = ["venturemond.${var.domain}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arns["venturemond-web"]
  }
}

resource "aws_lb_listener_rule" "root_domain" {
  listener_arn = module.alb.https_listener_arn
  priority     = 3

  condition {
    host_header {
      values = ["${var.domain}"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = module.alb.target_group_arns["sampleclient"]
  }
}

#########################################
# AWS Account ID
#########################################
data "aws_caller_identity" "current" {}

#########################################
# ECS
#########################################
module "ecs" {
  source = "./modules/ecs"

  ecs_cluster_name       = var.ecs_cluster_name
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  aws_region             = var.aws_region
  aws_account_id         = data.aws_caller_identity.current.account_id
  environment            = var.environment
  alb_security_group_id  = module.alb.alb_security_group_id

  target_group_arns = {
    sampleclient    = module.alb.target_group_arns["sampleclient"]
    venturemond-web = module.alb.target_group_arns["venturemond-web"]
  }

  smtp_username = var.smtp_username
  smtp_password = var.smtp_password
  domain        = var.domain

  services = var.services
}

#########################################
# Alarms & basic monitoring
#########################################
module "alarms" {
  source           = "./modules/alarms"
  ecs_cluster_name = var.ecs_cluster_name
  environment      = var.environment
}

#########################################
# Static assets (images, js, css)
#########################################
module "s3_cloudfront" {
  source = "./modules/s3_cloudfront"

  domain             = var.domain
  environment        = var.environment
  web_hosted_zone_id = var.hosted_zone_id

  tags = {
    Environment = var.environment
  }
}

#########################################
# DNS
#########################################
module "route53" {
  source = "./modules/route53"

  domain            = var.domain
  hosted_zone_id    = var.hosted_zone_id

  alb_dns_name      = module.alb.dns_name
  alb_zone_id       = module.alb.zone_id

  cloudfront_domain = module.s3_cloudfront.cloudfront_domain_name
  aws_region        = var.aws_region
}

#########################################
# SES
#########################################
module "ses" {
  source         = "./modules/ses"
  domain         = var.domain
  hosted_zone_id = var.hosted_zone_id
}
