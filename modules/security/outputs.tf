output "kms_key_arn" {
  value = aws_kms_key.cmk.arn
}

output "kms_key_id" {
  value = aws_kms_key.cmk.key_id
}

output "ci_policy_arn" {
  value = aws_iam_policy.ci_policy.arn
}

output "cloudtrail_bucket" {
  value = aws_s3_bucket.cloudtrail_logs.id
}

output "guardduty_detector_id" {
  value = try(aws_guardduty_detector.gd.id, null)
}
