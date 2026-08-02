#############################################
# StrideLux — cloudfront.tf
# Single distribution serving customer site + admin dashboard (SPA).
#############################################

# Certificate is managed in route53.tf (aws_acm_certificate.domain).
# To use the pre-existing cert instead, `terraform import` it, or replace
# the managed resource with:
#   data "aws_acm_certificate" "domain" {
#     domain = var.domain_name  statuses = ["ISSUED"]  most_recent = true
#   }

resource "aws_cloudfront_origin_access_control" "frontend" {
  name                              = "stridelux-frontend-oac"
  description                       = "OAC for stridelux-frontend S3 REST endpoint"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = false
  comment             = "StrideLux frontend (customer site + admin dashboard)"
  default_root_object = "index.html"
  price_class         = "PriceClass_All"
  aliases             = [var.domain_name, "www.${var.domain_name}"]
  web_acl_id = "arn:aws:wafv2:us-east-1:254566860404:global/webacl/CreatedByCloudFront-08ca9243/918615cb-75f9-4574-b79f-369b826c432c"
  tags                = local.common_tags

  origin {
    # REST endpoint (bucket_regional_domain_name), NOT the website endpoint
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "s3-stridelux-frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-stridelux-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    # AWS managed CachingOptimized policy
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # SPA routing: send S3 403/404 back as index.html with 200
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.domain.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}
