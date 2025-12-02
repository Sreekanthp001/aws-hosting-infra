output "dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "The hosted zone ID of the ALB"
  value       = aws_lb.this.zone_id
}


output "listener_https_arn" {
  description = "ARN of the HTTPS listener on the ALB"
  value       = aws_lb_listener.https.arn
}

output "target_group_arns" {
  description = "Map of service name to target group ARN"
  value       = {
    for k, v in aws_lb_target_group.tg :
    k => v.arn
  }
}
