terraform {
  required_providers {
    aws    = { source = "hashicorp/aws" }
    random = { source = "hashicorp/random" }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "random_id" "suffix" {
  byte_length = 4
}

############################################
# LOCALS
############################################

locals {
  ci_passrole_resources = (
    length(var.ci_allowed_pass_role_arns) > 0 ?
    var.ci_allowed_pass_role_arns :
    ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"]
  )
}

############################################
# 1. KMS Key for CloudTrail (REQUIRED POLICY)
############################################

resource "aws_kms_key" "cmk" {
  description             = "CMK for ${var.project}"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "EnableRoot",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        Action   = "kms:*",
        Resource = "*"
      },
      {
        Sid = "AllowCloudTrail",
        Effect = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}

############################################
# 2. CloudTrail Log Bucket
############################################

resource "aws_s3_bucket" "trail_bucket" {
  bucket = "${var.project}-trail-logs-${random_id.suffix.hex}"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    id      = "expire-old"
    enabled = true
    expiration {
      days = 180
    }
  }
}

resource "aws_s3_bucket_policy" "trail_bucket_policy" {
  bucket = aws_s3_bucket.trail_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "CloudTrailAclCheck",
        Effect   = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action   = "s3:GetBucketAcl",
        Resource = aws_s3_bucket.trail_bucket.arn
      },
      {
        Sid      = "CloudTrailWrite",
        Effect   = "Allow",
        Principal = { Service = "cloudtrail.amazonaws.com" },
        Action   = "s3:PutObject",
        Resource = "${aws_s3_bucket.trail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

############################################
# 3. CloudTrail
############################################

resource "aws_cloudtrail" "main" {
  name                          = "${var.project}-trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  kms_key_id                    = aws_kms_key.cmk.arn
  include_global_service_events = true
  is_multi_region_trail         = true
}

############################################
# 4. GuardDuty
############################################

resource "aws_guardduty_detector" "gd" {
  enable = true
}

############################################
# 5. CI IAM Policy (Simplified, Works)
############################################

data "aws_iam_policy_document" "ci" {
  statement {
    sid       = "ECRLogin"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "ECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]
    resources = [
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/*"
    ]
  }

  statement {
    sid    = "ECSUpdate"
    effect = "Allow"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "PassRole"
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = local.ci_passrole_resources
  }
}

resource "aws_iam_policy" "ci_policy" {
  name   = "${var.project}-ci-policy"
  policy = data.aws_iam_policy_document.ci.json
}
