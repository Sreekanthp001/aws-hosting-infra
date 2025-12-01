resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
}

# TXT record for SES verification
resource "aws_route53_record" "verification" {
  zone_id = var.hosted_zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = 600

  records = [
    aws_ses_domain_identity.this.verification_token
  ]
}

# DKIM CNAME records (3 records)
resource "aws_route53_record" "dkim" {
  count           = 3
  allow_overwrite = true

  zone_id = var.hosted_zone_id
  name    = "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = 600

  records = [
    "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"
  ]
}

# SPF record
resource "aws_route53_record" "spf" {
  zone_id = var.hosted_zone_id
  name    = var.domain
  type    = "TXT"
  ttl     = 300

  records = [
    "v=spf1 include:amazonses.com -all"
  ]
}

# DMARC record
resource "aws_route53_record" "dmarc" {
  zone_id = var.hosted_zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  ttl     = 300

  records = [
    "v=DMARC1; p=none; rua=mailto:postmaster@${var.domain}"
  ]
}
