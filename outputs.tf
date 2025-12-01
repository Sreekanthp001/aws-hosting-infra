output "ses_domain_identity_arn" {
  value = module.ses.domain_identity_arn
}

output "ses_domain_verification_token" {
  value = module.ses.domain_verification_token
}

output "ses_dkim_tokens" {
  value = module.ses.dkim_tokens
}
