output "ses_identity_arn" {
  value = var.enable_ses ? aws_ses_domain_identity.domain_identity[0].arn : null
}

output "ecs_service_name" {
  value = var.create_ecs ? aws_ecs_service.client_service[0].name : null
}

output "target_group_arn" {
  value = var.create_ecs ? aws_lb_target_group.client_tg[0].arn : null
}

output "listener_rule_arn" {
  value = var.create_ecs ? aws_lb_listener_rule.client_rule[0].arn : null
}

output "cloudfront_distribution_id" {
  value = var.create_cloudfront ? aws_cloudfront_distribution.client_cf[0].id : null
}
