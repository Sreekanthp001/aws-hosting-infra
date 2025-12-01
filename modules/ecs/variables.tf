variable "ecs_cluster_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "services" {
  type = map(object({
    image = string
    port  = number
  }))
}

variable "alb_security_group_id" {
  type = string
}

variable "target_group_arns" {
  type = map(string)
}

variable "listener_https_arn" {
  type = string
}
