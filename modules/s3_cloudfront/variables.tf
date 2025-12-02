variable "domain" {
  type = string
}

variable "environment" {
  type = string
}

variable "web_hosted_zone_id" {
  type = string
}

/* variable "cloudfront_acm_arn" {
  type        = string
  description = "ACM cert ARN for CloudFront (must be in us-east-1)"
} */

variable "tags" {
  type    = map(string)
  default = {}
}
