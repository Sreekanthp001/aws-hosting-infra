variable "aws_account_id" { type = string }
variable "environment" { type = string }
variable "repos" { type = list(string); default = ["venturemond", "sampleclient"] }
