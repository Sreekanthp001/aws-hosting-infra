output "dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "The hosted zone ID of the ALB"
  value       = aws_lb.this.zone_id
}


output "https_listener_arn" {
  value = aws_lb_listener.https.arn
}

output "target_group_arns" {
  value = { for k, v in aws_lb_target_group.tg : k => v.arn }
}

output "alb_security_group_id" {
  value = var.security_group_id
}
