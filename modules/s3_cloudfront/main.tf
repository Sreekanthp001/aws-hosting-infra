resource "aws_s3_bucket" "assets" {
  bucket = "${var.domain}-assets-${var.environment}"

  force_destroy = false

  tags = merge(
    {
      Name        = "${var.domain}-assets"
      Environment = var.environment
    },
    var.tags
  )
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.assets.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.assets.bucket

  rule {
    id     = "default"
    status = "Enabled"

    # REQUIRED: filter or prefix
    filter {
      prefix = ""
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}


resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "${var.domain}-oai"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid = "AllowCloudFrontAccess"

    actions = ["s3:GetObject"]

    resources = [
      "${aws_s3_bucket.assets.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

resource "aws_cloudfront_distribution" "cf" {
  enabled = true
  comment = "CF for ${var.domain}"

  origin {
    origin_id   = "s3-${aws_s3_bucket.assets.id}"
    domain_name = aws_s3_bucket.assets.bucket_regional_domain_name

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-${aws_s3_bucket.assets.id}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.cloudfront_acm_arn   # ← FIXED
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_route53_record" "static_assets" {
  zone_id = var.web_hosted_zone_id
  name    = "static.${var.domain}"
  type    = "CNAME"
  ttl     = 300

  allow_overwrite = true

  records = [
    aws_cloudfront_distribution.cf.domain_name
  ]
}

