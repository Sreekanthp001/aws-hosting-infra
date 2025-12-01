variable "vpc_id" { type = string }
variable "domain" { type = string }
variable "hosted_zone_id" { type = string }
variable "aws_region" { type = string }
variable "subnets" {
  description = "List of subnet IDs for the ALB"
  type        = list(string)
}

variable "security_groups" {
  description = "List of security group IDs to attach to the ALB"
  type        = list(string)
}