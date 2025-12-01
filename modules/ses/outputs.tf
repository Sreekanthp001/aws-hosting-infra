# Outputs for SES
output "domain_identity_arn" {
  value = aws_ses_domain_identity.this.arn
}

output "domain_verification_token" {
  value = aws_ses_domain_identity.this.verification_token
}

output "dkim_tokens" {
  value = aws_ses_domain_dkim.dkim.dkim_tokens
}
