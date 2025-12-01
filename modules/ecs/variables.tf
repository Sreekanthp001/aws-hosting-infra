variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_target_groups" {
  description = "Map of service names to ALB target group ARNs"
  type        = map(string)
}

variable "services" {
  description = "Map of ECS services with image and port"
  type = map(object({
    image = string
    port  = number
  }))
}
