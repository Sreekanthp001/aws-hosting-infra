variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "public_subnet_count" {
  type        = number
  description = "Number of public subnets"
}

variable "private_subnet_count" {
  type        = number
  description = "Number of private subnets"
}

variable "availability_zones" {
  type        = list(string)
  default     = []
  description = "Optional: Specific AZs to place subnets in"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Common tags"
}
