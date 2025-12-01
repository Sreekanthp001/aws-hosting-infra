# SES Domain Identity
resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

# SES DKIM
resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

# Route53 TXT record for domain verification
resource "aws_route53_record" "verification" {
  zone_id = var.hosted_zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.this.verification_token]
}

# Route53 CNAME records for DKIM
resource "aws_route53_record" "dkim" {
  for_each = { for t in aws_ses_domain_dkim.this.dkim_tokens : t => t }
  zone_id  = var.hosted_zone_id
  name     = "${each.value}._domainkey.${var.domain}"
  type     = "CNAME"
  ttl      = 600
  records  = ["${each.value}.dkim.amazonses.com"]
}
