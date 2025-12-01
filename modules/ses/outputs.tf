output "domain_verification_status" { value = aws_ses_domain_identity.this.verification_status }
output "dkim_tokens" { value = aws_ses_domain_dkim.dkim_tokens }
