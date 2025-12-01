variable "vpc_id" { type = string }
variable "domain" { type = string }
variable "hosted_zone_id" { type = string }
variable "aws_region" { type = string }
output "public_subnets" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public_subnets[*].id  
}

variable "security_group_id" {
  description = "Security group for the ALB"
  type        = string
}
