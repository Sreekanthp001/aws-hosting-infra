output "service_names" {
  description = "ECS Service Names"
  value       = { for k, v in aws_ecs_service.svc : k => v.name }
}

output "service_arns" {
  description = "ECS Service ARNs"
  value       = { for k, v in aws_ecs_service.svc : k => v.id }
}

output "task_definition_arns" {
  description = "Task Definition ARNs"
  value       = { for k, v in aws_ecs_task_definition.task : k => v.arn }
}
