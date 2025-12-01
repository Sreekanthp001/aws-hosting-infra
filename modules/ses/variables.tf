variable "domain" {
  type        = string
  description = "The domain to verify in SES"
}

variable "hosted_zone_id" {
  type        = string
  description = "The Route53 hosted zone ID for the domain"
}
