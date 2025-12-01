variable "vpc_cidr" { type = string }
variable "public_subnet_count" { type = number }
variable "private_subnet_count" { type = number }
variable "availability_zones" { 
    type = list(string)
    default = [] 
}
variable "tags" { 
    type = map(string)
    default = {} 
}
