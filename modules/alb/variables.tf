variable "vpc_id" {
  type = string
}

variable "domain" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs to attach ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "services" {
  description = "List of service names for target groups and host rules"
  type        = list(string)
}
