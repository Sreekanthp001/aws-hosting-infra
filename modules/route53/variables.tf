variable "domain" {
  type = string
}

variable "hosted_zone_id" {
  type = string
  description = "Hosted zone ID for the domain"
}

variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

variable "cloudfront_domain" {
  type = string
}
