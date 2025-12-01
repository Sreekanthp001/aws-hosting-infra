provider "aws" {
  alias  = "ses"
  region = var.region
}

resource "aws_ses_domain_identity" "this" {
  provider = aws.ses
  domain = var.domain
}

resource "aws_ses_domain_dkim" "dkim" {
  provider = aws.ses
  domain = aws_ses_domain_identity.this.domain
}

# Create Route53 TXT for verification
resource "aws_route53_record" "ses_verify" {
  zone_id = var.hosted_zone_id
  name = aws_ses_domain_identity.this.domain
  type = "TXT"
  ttl = 600
  records = [aws_ses_domain_identity.this.verification_token]
}

# DKIM CNAME records
resource "aws_route53_record" "dkim" {
  for_each = toset(aws_ses_domain_dkim.dkim_tokens)
  zone_id = var.hosted_zone_id
  name = "${each.value}._domainkey.${var.domain}"
  type = "CNAME"
  ttl = 600
  records = ["${each.value}.dkim.amazonses.com"]
}
