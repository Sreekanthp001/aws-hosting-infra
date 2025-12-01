locals {
  # ensure hosted zone id is passed
  valid_zone = var.hosted_zone_id != ""
}

assert(
  local.valid_zone,
  "hosted_zone_id must be provided to create DNS records"
)

data "aws_route53_zone" "selected" {
  zone_id = var.hosted_zone_id
}

# Root domain -> ALB
resource "aws_route53_record" "root_alb" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# www subdomain -> ALB
resource "aws_route53_record" "www_alb" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "www.${var.domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# static assets -> CloudFront
resource "aws_route53_record" "static" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "static.${var.domain}"
  type    = "CNAME"
  ttl     = 300
  records = [
    var.cloudfront_domain
  ]
}
