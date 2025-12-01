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

resource "aws_route53_record" "root_alb" {
  zone_id = "Z01202283P3B2XPK9DBXI"
  name    = "venturemond.site"
  type    = "A"
  alias {
    evaluate_target_health = false
  }
}

# Route53 CNAME records for DKIM
# AWS always returns 3 DKIM tokens, so we can create 3 records safely
resource "aws_route53_record" "dkim" {
  allow_overwrite = true
  count   = 3
  zone_id = var.hosted_zone_id
  name    = "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"]
}
