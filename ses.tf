# Create SES identity (domain)
resource "aws_ses_domain_identity" "domain" {
  domain = var.domain
}

# DKIM tokens
resource "aws_ses_domain_dkim" "dkim" {
  domain = aws_ses_domain_identity.domain.domain
}

# Route53 TXT record for SES verification
resource "aws_route53_record" "ses_verify" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = 60
  records = [aws_ses_domain_identity.domain.verification_token]
}

# DKIM CNAMEs
resource "aws_route53_record" "ses_dkim" {
  for_each = toset(aws_ses_domain_dkim.dkim.dkim_tokens)
  zone_id = var.route53_zone_id
  name    = "${each.value}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = 300
  records = ["${each.value}.dkim.amazonses.com"]
}

# Optional: DMARC and SPF - add as Route53 records (example values)
resource "aws_route53_record" "spf" {
  zone_id = var.route53_zone_id
  name    = var.domain
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = var.route53_zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  ttl     = 300
  # Example DMARC: quarantine and send aggregate reports to postmaster@domain
  records = ["v=DMARC1; p=quarantine; rua=mailto:postmaster@${var.domain}; pct=100"]
}
