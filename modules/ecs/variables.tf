variable "ecs_cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_target_groups" {
  type = map(string)
}

variable "iam_task_role_arn" {
  type = string
}

variable "iam_task_exec_role_arn" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "services" {
  description = "Map of ECS services with image and port"
  type = map(object({
    image = string
    port  = number
  }))
}

variable "ecs_sg_ids" {
  description = "List of security group IDs for ECS tasks"
  type        = list(string)
}
