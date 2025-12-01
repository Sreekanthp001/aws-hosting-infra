output "cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "service_names" {
  value = { for k, v in aws_ecs_service.svc : k => v.name }
}
