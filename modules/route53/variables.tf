variable "domain" {
  type = string
}

variable "hosted_zone_id" {
  type = string

  validation {
    condition     = length(var.hosted_zone_id) > 0
    error_message = "hosted_zone_id must not be empty."
  }
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
