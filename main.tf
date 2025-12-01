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
  hosted_zone_id  = var.web_hosted_zone_id
  aws_region      = var.aws_region

  #alb_zone_id     = null # REMOVE if present, only if incorrectly left

  services = keys(var.services)
}


module "ecs" {
  source = "./modules/ecs"

  ecs_cluster_name   = var.ecs_cluster_name
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  aws_region  = var.aws_region
  environment = var.environment

  services = var.services
  alb_security_group_id = aws_security_group.alb_sg.id
  listener_https_arn    = module.alb.listener_https_arn
  target_group_arns     = module.alb.target_group_arns
}

module "s3_cloudfront" {
  source = "./modules/s3_cloudfront"

  domain             = var.domain
  environment        = var.environment
  web_hosted_zone_id = var.web_hosted_zone_id

  tags = {
    Environment = var.environment
  }

  cloudfront_acm_arn = var.cloudfront_acm_arn
}

module "route53" {
  source = "./modules/route53"

  domain            = var.domain
  hosted_zone_id    = var.web_hosted_zone_id

  alb_dns_name      = module.alb.alb_dns_name
  alb_zone_id       = module.alb.alb_zone_id

  cloudfront_domain = module.s3_cloudfront.cloudfront_domain_name
}

module "ses" {
  source         = "./modules/ses"
  domain         = var.domain
  hosted_zone_id = var.web_hosted_zone_id
}
