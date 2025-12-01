variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_account_id" { 
  type    = string
  default = "535462128585"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "domain" {
  description = "Primary domain name (example: sree84s.site)"
  type        = string
  default     = "sree84s.site"
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID for the domain. If empty, Terraform will look it up."
  type        = string
  default     = "Z0602795P0OBBBRHSRWB"
}

variable "vpc_cidr" { 
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_count" { 
  type    = number
  default = 2
}

variable "private_subnet_count" { 
  type    = number
  default = 2
}

variable "azs" { 
  type    = list(string)
  default = []
}

variable "ecs_cluster_name" {
  type    = string
  default = "sree-ecs-cluster"
}


variable "tfstate_s3_bucket" { 
  type    = string
  default = ""
}

variable "tfstate_s3_key" { 
  type    = string
  default = "terraform/state.tfstate"
}

variable "tfstate_lock_table" { 
  type    = string
  default = ""
}

variable "ses_region" { 
  type    = string
  default = "us-east-1"
}
