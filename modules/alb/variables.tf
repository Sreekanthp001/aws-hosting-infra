variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "security_group_ids" { type = list(string) }
variable "domain" { type = string }
variable "hosted_zone_id" { type = string }
variable "aws_region" { type = string }
