# ECS Cluster
variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
}

# Networking
variable "vpc_id" {
  description = "VPC ID where ECS cluster and resources are deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_sg_ids" {
  description = "List of security group IDs to attach to ECS tasks"
  type        = list(string)
}

# IAM roles
variable "iam_task_role_arn" {
  description = "IAM role ARN for ECS tasks"
  type        = string
}

variable "iam_task_exec_role_arn" {
  description = "IAM execution role ARN for ECS tasks"
  type        = string
}

# ALB Target Groups
variable "alb_target_groups" {
  description = "Map of ECS service names to ALB target group ARNs"
  type        = map(string)
}

# Environment info
variable "environment" {
  description = "Environment name (e.g., prod, dev)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

# ECS services
variable "services" {
  description = "Map of ECS service names to configurations"
  type        = map(any)
}
