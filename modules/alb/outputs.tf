output "alb_dns_name" {
  description = "DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Hosted zone ID of the ALB"
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
