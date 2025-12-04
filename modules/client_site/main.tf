# ACM cert for domain (DNS validated)
resource "aws_acm_certificate" "cert" {
  count = var.create_ecs || var.create_cloudfront ? 1 : 0
  domain_name = var.domain
  validation_method = "DNS"
  subject_alternative_names = ["www.${var.domain}"]
}

