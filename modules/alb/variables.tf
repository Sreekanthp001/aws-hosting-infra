variable "vpc_id" { type = string }
variable "domain" { type = string }
variable "hosted_zone_id" { type = string }
variable "aws_region" { type = string }
variable "subnets" {
  description = "List of subnets to associate with the ALB"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID to associate with the ALB"
  type        = string
}
