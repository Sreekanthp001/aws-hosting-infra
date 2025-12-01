variable "vpc_cidr" {
  type = string
}

variable "public_subnet_count" {
  type = number
}

variable "private_subnet_count" {
  type = number
}

variable "azs" {
  type = list(string)
}

variable "domain" {
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "services" {
  type = map(object({
    image = string
    port  = number
  }))
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "ecs_cluster_name" {
  type = string
}

variable "environment" {
  type = string
}
