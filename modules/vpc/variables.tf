variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_count" {
  type = number

  validation {
    condition     = var.public_subnet_count == var.private_subnet_count
    error_message = "public_subnet_count and private_subnet_count must be equal for NAT gateway alignment."
  }
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets"
}

variable "availability_zones" {
  type    = list(string)
  default = []

  validation {
    condition = length(var.availability_zones) == 0 || length(var.availability_zones) >= max(var.public_subnet_count, var.private_subnet_count)
    error_message = "If availability_zones is provided, it must be >= max(public and private subnet counts)."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags"
}
