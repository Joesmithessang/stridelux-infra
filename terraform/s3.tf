#############################################
# StrideLux — s3.tf
# Private frontend bucket. Static website hosting is DISABLED —
# CloudFront reads via OAC against the S3 REST endpoint.
#############################################

resource "aws_s3_bucket" "frontend" {
  bucket = "stridelux-frontend"
  tags   = local.common_tags
}

# Public access fully blocked
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# SSE-S3 (AWS-managed key) — matches live default encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bucket policy: only the CloudFront distribution (via OAC) may read objects
data "aws_iam_policy_document" "frontend_oac" {
  statement {
    sid       = "AllowCloudFrontServicePrincipalReadOnly"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.frontend.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_oac.json

  depends_on = [aws_s3_bucket_public_access_block.frontend]
}
