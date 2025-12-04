
# 1. KMS KEY + ALIAS

resource "aws_kms_key" "cmk" {
  description             = "CMK for ${var.project} - encryption for S3, CloudTrail, secrets"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Project = var.project
    Managed = "true"
  }
}

resource "aws_kms_alias" "cmk_alias" {
  name          = "alias/${var.project}-key"
  target_key_id = aws_kms_key.cmk.key_id
}

# 2. S3 PUBLIC ACCESS BLOCK + ENCRYPTION

resource "aws_s3_bucket_public_access_block" "block" {
  for_each = toset(var.s3_buckets_to_protect)

  bucket = each.value

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  for_each = toset(var.s3_buckets_to_protect)

  bucket = each.value

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cmk.arn
    }
  }
}

# 3. CLOUDTRAIL + LOG BUCKET
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "${var.project}-cloudtrail-logs-${random_id.suffix.hex}"
  acl    = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.cmk.arn
      }
    }
  }

  tags = {
    Project = var.project
  }
}

resource "aws_cloudtrail" "trail" {
  name                          = "${var.project}-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.cmk.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  tags = {
    Project = var.project
  }
}

# 4. GUARDDUTY (ACCOUNT-WIDE)

resource "aws_guardduty_detector" "gd" {
  enable = true
}

# 5. CI DEPLOY POLICY (ECR + ECS + S3 + CLOUDFRONT)

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ci" {
  # ECR authentication
  statement {
    sid    = "ECRAuth"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }

  # Push images
  statement {
    sid    = "ECRPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:PutImage",
      "ecr:CreateRepository",
      "ecr:DescribeRepositories",
      "ecr:BatchGetImage"
    ]
    resources = [
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/*"
    ]
  }

  # ECS update service + task definitions
  statement {
    sid    = "ECSUpdate"
    effect = "Allow"
    actions = [
      "ecs:DescribeCluster",
      "ecs:DescribeServices",
      "ecs:ListTasks",
      "ecs:DescribeTasks",
      "ecs:RegisterTaskDefinition",
      "ecs:UpdateService",
      "ecs:CreateService",
      "ecs:DeleteService"
    ]
    resources = ["*"]
  }

  # S3 sync for static deployments
  statement {
    sid    = "S3Sync"
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketLocation"
    ]
    resources = concat(
      [for b in var.s3_buckets_to_protect : "arn:aws:s3:::${b}"],
      [for b in var.s3_buckets_to_protect : "arn:aws:s3:::${b}/*"]
    )
  }

  # CloudFront invalidation
  statement {
    sid    = "CloudFrontInvalidate"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation",
      "cloudfront:GetDistribution",
      "cloudfront:ListDistributions"
    ]
    resources = ["*"]
  }

  # PassRole for ECS tasks
  statement {
    sid    = "PassRole"
    effect = "Allow"
    actions = ["iam:PassRole"]
    resources = var.ci_allowed_pass_role_arns
  }
}

resource "aws_iam_policy" "ci_policy" {
  name        = "${var.project}-ci-policy"
  policy      = data.aws_iam_policy_document.ci.json
  description = "CI/CD policy for ECS, ECR, CloudFront, S3 deployments"

  tags = {
    Project = var.project
  }
}

# 6. OPTIONAL WAF (ALB PROTECTION)

resource "aws_wafv2_web_acl" "web_acl" {
  count = var.enable_waf ? 1 : 0

  name  = "${var.project}-waf"
  scope = "REGIONAL"

  description = "Managed rule WAF for ALB"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      sampled_requests_enabled   = true
      metric_name                = "${var.project}-commonrules"
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
    metric_name                = "${var.project}-waf"
  }

  tags = {
    Project = var.project
  }
}

resource "aws_wafv2_web_acl_association" "assoc" {
  count = (var.enable_waf && var.alb_arn_to_protect != "") ? 1 : 0

  resource_arn = var.alb_arn_to_protect
  web_acl_arn  = aws_wafv2_web_acl.web_acl[0].arn
}
