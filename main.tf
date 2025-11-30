provider "aws" {
  region = var.region
}

module "vpc" {
  source   = "./modules/vpc"
  region   = var.region
  prefix   = var.prefix
  vpc_cidr = var.vpc_cidr
  azs      = var.azs
}

output "vpc_id" {
  value = module.vpc.vpc_id
}
output "public_subnets" {
  value = module.vpc.public_subnet_ids
}
output "private_subnets" {
  value = module.vpc.private_subnet_ids
}
