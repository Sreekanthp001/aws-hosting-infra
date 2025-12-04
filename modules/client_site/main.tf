# ACM cert for domain (DNS validated)
resource "aws_acm_certificate" "cert" {
  count = var.create_ecs || var.create_cloudfront ? 1 : 0
  domain_name = var.domain
  validation_method = "DNS"
  subject_alternative_names = ["www.${var.domain}"]
}

# create Route53 records for cert validation (need domain zone)
resource "aws_route53_record" "cert_validation" {
  count = length(aws_acm_certificate.cert) > 0 ? length(aws_acm_certificate.cert[0].domain_validation_options) : 0
  zone_id = var.hosted_zone_id
  name    = aws_acm_certificate.cert[0].domain_validation_options[count.index].resource_record_name
  type    = aws_acm_certificate.cert[0].domain_validation_options[count.index].resource_record_type
  records = [aws_acm_certificate.cert[0].domain_validation_options[count.index].resource_record_value]
  ttl     = 60
}
