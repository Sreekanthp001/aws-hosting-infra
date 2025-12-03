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

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

module "alb" {
  source = "./modules/alb"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  security_group_id = aws_security_group.alb_sg.id

  domain          = var.domain
  hosted_zone_id  = var.hosted_zone_id
  aws_region      = var.aws_region

  #alb_zone_id     = null # REMOVE if present, only if incorrectly left

  services = keys(var.services)
}


data "aws_caller_identity" "current" {}

module "ecs" {
  source = "./modules/ecs"

  ecs_cluster_name       = "your-cluster-name"
  vpc_id                 = module.vpc.vpc_id
  private_subnet_ids     = module.vpc.private_subnet_ids
  aws_region             = var.aws_region
  aws_account_id         = data.aws_caller_identity.current.account_id
  environment            = var.environment
  alb_security_group_id  = module.alb.alb_security_group_id
  target_group_arns      = module.alb.target_group_arns
  smtp_username          = var.smtp_username
  smtp_password          = var.smtp_password
  domain                 = var.domain

  services = {
    sampleclient = {
      image = "your-image"
      port  = 80
    }
    venturemond-web = {
      image = "your-image"
      port  = 80
    }
  }
}

module "alarms" {
  source           = "./modules/alarms"
  ecs_cluster_name = var.ecs_cluster_name
  environment      = var.environment
}




module "s3_cloudfront" {
  source = "./modules/s3_cloudfront"

  domain             = var.domain
  environment        = var.environment
  web_hosted_zone_id = var.hosted_zone_id

  tags = {
    Environment = var.environment
  }

  #cloudfront_acm_arn = var.cloudfront_acm_arn
}

module "route53" {
  source = "./modules/route53"

  domain            = var.domain
  hosted_zone_id    = var.hosted_zone_id

  alb_dns_name      = module.alb.dns_name
  alb_zone_id       = module.alb.zone_id

  cloudfront_domain = module.s3_cloudfront.cloudfront_domain_name
  aws_region        = var.aws_region
}

module "ses" {
  source         = "./modules/ses"
  domain         = var.domain
  hosted_zone_id = var.hosted_zone_id
}
