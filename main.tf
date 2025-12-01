# Modules wiring
module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  public_subnet_count = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  availability_zones = var.azs
  tags = { Environment = var.environment }
}

module "iam" {
  source      = "./modules/iam"
  environment = var.environment
}


module "ecr" {
  source = "./modules/ecr"
  aws_account_id = var.aws_account_id
  environment = var.environment
}

module "alb" {
  source = "./modules/alb"
  vpc_id = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_group_ids = module.iam.alb_sg_id != null ? [module.iam.alb_sg_id] : []
  domain = var.domain
  hosted_zone_id = var.hosted_zone_id
  aws_region = var.aws_region
}

module "ecs" {
  source = "./modules/ecs"
  cluster_name = var.ecs_cluster_name
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  alb_target_groups = module.alb.tg_map
  iam_task_role_arn = module.iam.ecs_task_role_arn
  iam_task_exec_role_arn = module.iam.ecs_task_exec_role_arn
  environment = var.environment
  aws_region = var.aws_region
  aws_account_id = var.aws_account_id
  services = {
    "venturemond" = {
      container_name = "venturemond"
      container_port = 80
    }
    "sampleclient" = {
      container_name = "sampleclient"
      container_port = 80
    }
  }
}


module "s3_cloudfront" {
  source = "./modules/s3_cloudfront"
  domain = var.domain
  environment = var.environment
  hosted_zone_id = var.hosted_zone_id
  aws_region = var.aws_region
}

module "route53" {
  source = "./modules/route53"
  domain = var.domain
  hosted_zone_id = var.hosted_zone_id
  alb_dns_name = module.alb.alb_dns_name
  cloudfront_domain = module.s3_cloudfront.cloudfront_domain_name
  aws_region = var.aws_region
}

module "ses" {
  source         = "./modules/ses"
  domain         = var.domain
  hosted_zone_id = module.route53.zone_id
}

