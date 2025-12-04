output "domain" {
  value = var.domain
}

output "certificate_arn" {
  value       = try(aws_acm_certificate.cert[0].arn, null)
  description = "ACM certificate for this domain"
}

output "ses_identity_arn" {
  value       = try(aws_ses_domain_identity.domain_identity.arn, null)
  description = "SES domain identity ARN"
}

output "ecs_service_name" {
  value       = try(aws_ecs_service.client_service.name, null)
  description = "ECS service created for this client"
}

output "target_group_arn" {
  value       = try(aws_lb_target_group.client_tg.arn, null)
  description = "Target group ARN for host-based routing"
}

output "listener_rule_arn" {
  value       = try(aws_lb_listener_rule.client_rule.arn, null)
  description = "Listener rule that routes domain to ECS service"
}

output "cloudfront_distribution_id" {
  value       = try(aws_cloudfront_distribution.client_cf.id, null)
  description = "CloudFront distribution ID for static site"
}
