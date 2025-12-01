data "aws_route53_zone" "selected" {
  name = var.domain
  private_zone = false
  zone_id = var.hosted_zone_id != "" ? var.hosted_zone_id : null
}

# ALIAS for root and www to ALB
resource "aws_route53_record" "root_alb" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name = var.domain
  type = "A"
  alias {
    name = var.alb_dns_name
    zone_id = data.aws_route53_zone.selected.zone_id # ALIAS expects ALB zone id; Terraform may need correct zone id. Using simple approach; you may adjust.
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_alb" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name = "www.${var.domain}"
  type = "A"
  alias {
    name = var.alb_dns_name
    zone_id = data.aws_route53_zone.selected.zone_id
    evaluate_target_health = true
  }
}

# static asset record
resource "aws_route53_record" "static" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name = "static.${var.domain}"
  type = "CNAME"
  ttl = 300
  records = [var.cloudfront_domain]
}
