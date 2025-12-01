# ses_inbound.tf
variable "domain" { type = string }
variable "route53_zone_id" { type = string }
variable "inbound_bucket_name" { type = string } # unique bucket name

resource "aws_s3_bucket" "inbound" {
  bucket = var.inbound_bucket_name
  acl    = "private"

  versioning { enabled = true }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Allow SES to put objects into S3 bucket
resource "aws_iam_role" "ses_s3_role" {
  name = "${var.domain}-ses-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ses.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ses_put_object" {
  name = "${var.domain}-ses-put-object"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["s3:PutObject","s3:PutObjectAcl","s3:PutObjectTagging"],
      Resource = ["${aws_s3_bucket.inbound.arn}/*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ses_s3_role.name
  policy_arn = aws_iam_policy.ses_put_object.arn
}

# SES receipt rule set & rule
resource "aws_ses_receipt_rule_set" "rule_set" {
  rule_set_name = "${var.domain}-rule-set"
}

resource "aws_ses_receipt_rule" "store_to_s3" {
  name          = "${var.domain}-store-to-s3"
  rule_set_name = aws_ses_receipt_rule_set.rule_set.rule_set_name
  enabled       = true
  recipients    = [var.domain]

  scan_enabled = true
  tls_policy   = "Optional"

  s3_action {
    position          = 1
    bucket_name       = aws_s3_bucket.inbound.bucket
    object_key_prefix = "emails/${var.domain}/"
    topic_arn         = ""  # optional SNS topic for notifications
    kms_key_arn       = ""  # if using KMS
  }

  # Optionally also add SNS or Lambda actions
}
