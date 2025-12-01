resource "aws_s3_bucket" "assets" {
  bucket = "${var.domain}-assets-${var.environment}"
  acl = "private"
  force_destroy = false
  versioning { enabled = true }
  lifecycle_rule { 
    id = "default" 
    enabled = true
    abort_incomplete_multipart_upload_days = 7
    transition { 
        days = 30
        storage_class = "STANDARD_IA" 
    } 
  }
}

resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "${var.domain}-oai"
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.assets.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.assets.arn}/*"]
    principals { 
        type = "AWS" 
        identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn] 
    }
  }
}

# ACM cert for cloudfront must be in us-east-1; this module assumes caller will manage ACM if necessary.
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

  allowed_methods = ["GET", "HEAD"]     # Required
  cached_methods  = ["GET", "HEAD"]     # Required

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
    cloudfront_default_certificate = true
  }
}
