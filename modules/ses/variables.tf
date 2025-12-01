variable "domain" {
  description = "Domain name to configure SES identity, DKIM, SPF and DMARC"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID for the given SES domain"
  type        = string
}
