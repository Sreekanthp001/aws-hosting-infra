output "domain" {
  value = var.domain
}

output "certificate_arn" {
  value = try(aws_acm_certificate.cert[0].arn, null)
}
