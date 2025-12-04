variable "project" {
  type = string
  description = "Project name (used for resource names/tags)"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "s3_buckets_to_protect" {
  type        = list(string)
  default     = []
  description = "List of existing S3 bucket names to enable public access block and (optionally) default encryption."
}

variable "ci_allowed_pass_role_arns" {
  type        = list(string)
  default     = []
  description = "List of IAM role ARNs that CI is allowed to pass (used in the CI policy). Keep narrow for least privilege."
}

variable "enable_waf" {
  type    = bool
  default = false
  description = "Whether to create a WAFv2 Web ACL and optionally associate to ALB."
}

variable "alb_arn_to_protect" {
  type        = string
  default     = ""
  description = "If enable_waf=true, this is the ALB ARN the WAF will be associated with. Leave empty to skip association."
}
