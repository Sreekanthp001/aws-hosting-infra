data "aws_route53_zone" "selected" {
  name         = var.domain
  private_zone = false

  # If hosted_zone_id is provided, use that; else lookup by name
  zone_id = var.hosted_zone_id != "" ? var.hosted_zone_id : null
}

# Root -> ALB
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

# www -> ALB
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

# venturemond -> ALB
resource "aws_route53_record" "venturemond_alb" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "venturemond.${var.domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# sampleclient -> ALB
resource "aws_route53_record" "sampleclient_alb" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "sampleclient.${var.domain}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# static -> CloudFront
resource "aws_route53_record" "static" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "static.${var.domain}"
  type    = "CNAME"
  ttl     = 300

  records = [var.cloudfront_domain]
  allow_overwrite = true
}
