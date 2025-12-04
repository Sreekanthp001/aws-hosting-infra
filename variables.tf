variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets"
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets"
}

variable "azs" {
  type        = list(string)
  description = "List of availability zones"
}

variable "domain" {
  type        = string
  description = "Primary application domain for websites"
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID for the domain"
  type        = string
}

variable "services" {
  type = map(object({
    image = string
    port  = number
  }))
  description = "Service definitions for ECS apps"
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID for ECR paths"
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name"
}

variable "environment" {
  type        = string
  description = "Environment name (prod, staging, dev, etc.)"
}

variable "smtp_username" {
  type = string
}

variable "smtp_password" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "tags" {
  type = map(string)
  default = {}
}
variable "cluster_arn" {
  type = string
}


variable "alb_listener_arn" {
  type = string
}

variable "ecr_image" {
  type = string
}

