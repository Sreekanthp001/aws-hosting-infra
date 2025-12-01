output "alb_arn" { value = aws_lb.alb.arn }
output "alb_dns_name" { value = aws_lb.alb.dns_name }
output "tg_map" { value = { for k, v in aws_lb_target_group.tg : k => v.arn } }
output "cert_arn" { value = aws_acm_certificate.cert.arn }
