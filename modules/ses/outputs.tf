# SES Domain Identity ARN
output "domain_identity_arn" {
  value = aws_ses_domain_identity.this.arn
}

# SES Domain verification token
output "domain_verification_token" {
  value = aws_ses_domain_identity.this.verification_token
}

# SES DKIM tokens
output "dkim_tokens" {
  value = aws_ses_domain_dkim.this.dkim_tokens
}
