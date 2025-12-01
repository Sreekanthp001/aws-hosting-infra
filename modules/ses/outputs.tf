output "domain_identity_arn" {
  description = "ARN of the SES domain identity resource"
  value       = aws_ses_domain_identity.this.arn
}

output "domain_verification_token" {
  description = "Verification token for SES TXT record"
  value       = aws_ses_domain_identity.this.verification_token
}

output "dkim_tokens" {
  description = "DKIM tokens for CNAME DKIM record creation"
  value       = aws_ses_domain_dkim.this.dkim_tokens
}
