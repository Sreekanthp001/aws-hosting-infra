output "dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "zone_id" {
  description = "The hosted zone ID of the ALB"
  value       = aws_lb.this.zone_id
}
