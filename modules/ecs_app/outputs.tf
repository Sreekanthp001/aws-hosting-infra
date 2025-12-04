output "ecs_service_name" {
  value = aws_ecs_service.svc.name
}

output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}

output "listener_rule_arn" {
  value = aws_lb_listener_rule.host_route.arn
}
