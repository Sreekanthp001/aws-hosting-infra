variable "name" { type = string }
variable "cidr" { type = string }
variable "public_azs" { type = list(string) }
variable "private_azs" { type = list(string) }
variable "nat_azs" { type = list(string) default = [] }
