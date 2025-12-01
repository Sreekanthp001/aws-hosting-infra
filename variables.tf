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

variable "web_hosted_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for main web domain"
}

variable "ses_domain" {
  type        = string
  description = "Domain used for SES email (can be same as website domain)"
}

variable "ses_hosted_zone_id" {
  type        = string
  description = "Hosted zone ID for SES email domain"
}

variable "cloudfront_acm_arn" {
  type        = string
  description = "ACM cert ARN for CloudFront (must be in us-east-1)"
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
  description = "Environment name (prod, stage, dev)"
}
