# ACM cert for domain (DNS validated)
resource "aws_acm_certificate" "cert" {
  count = var.create_ecs || var.create_cloudfront ? 1 : 0
  domain_name = var.domain
  validation_method = "DNS"
  subject_alternative_names = ["www.${var.domain}"]
}

# create Route53 records for cert validation (need domain zone)
resource "aws_route53_record" "cert_validation" {
  for_each = (
    length(aws_acm_certificate.cert) > 0
    ? {
        for dvo in aws_acm_certificate.cert[0].domain_validation_options :
        dvo.domain_name => {
          name  = dvo.resource_record_name
          type  = dvo.resource_record_type
          value = dvo.resource_record_value
        }
      }
    : {}
  )

  zone_id = var.hosted_zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.value]
  ttl     = 60
}
