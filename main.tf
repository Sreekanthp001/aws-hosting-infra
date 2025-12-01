# Modules wiring
module "vpc" {
  source               = "./modules/vpc"
  vpc_cidr             = var.vpc_cidr
  public_subnet_count  = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  availability_zones   = var.azs
  tags                 = { Environment = var.environment }
}

module "iam" {
  source      = "./modules/iam"
  environment = var.environment
}


module "ecr" {
  source         = "./modules/ecr"
  aws_account_id = var.aws_account_id
  environment    = var.environment
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
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

module "alb" {
  source             = "./modules/alb"
  vpc_id             = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  domain             = var.domain
  hosted_zone_id     = var.hosted_zone_id
  aws_region         = var.aws_region
}

module "ecs" {
  source             = "./modules/ecs"
  ecs_cluster_name   = var.ecs_cluster_name
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  aws_region         = var.aws_region
  environment        = var.environment
  services           = var.services
}



module "s3_cloudfront" {
  source         = "./modules/s3_cloudfront"
  domain         = var.domain
  environment    = var.environment
  hosted_zone_id = var.hosted_zone_id
  aws_region     = var.aws_region
}

module "route53" {
  source            = "./modules/route53"
  domain            = var.domain
  hosted_zone_id    = var.hosted_zone_id
  alb_dns_name      = module.alb.alb_dns_name
  cloudfront_domain = module.s3_cloudfront.cloudfront_domain_name
  aws_region        = var.aws_region
}

module "ses" {
  source          = "./modules/ses"
  domain          = "sree84s.site"
  hosted_zone_id  = "Z0602795P0OBBBRHSRWB"        
  alb_dns_name    = module.alb.dns_name           
  alb_zone_id     = module.alb.zone_id            
}

