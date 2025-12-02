variable "domain" {
  type = string
}

variable "hosted_zone_id" {
  description = "Public hosted zone ID for the domain (Route53 zone)"
  type        = string
  default     = ""
}

variable "alb_dns_name" {
  description = "DNS name of the ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Hosted zone ID of the ALB (from aws_lb.this.zone_id)"
  type        = string
}

variable "cloudfront_domain" {
  description = "Domain name of the CloudFront distribution"
  type        = string
}

variable "aws_region" {
  type = string
}
