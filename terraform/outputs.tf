#############################################
# StrideLux — outputs.tf
#############################################

output "site_url" {
  description = "Public site URL"
  value       = "https://${var.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (GitHub Secret: CLOUDFRONT_DISTRIBUTION_ID)"
  value       = aws_cloudfront_distribution.frontend.id
}

output "cloudfront_domain_name" {
  description = "CloudFront domain (dXXXX.cloudfront.net)"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "frontend_bucket_name" {
  description = "Frontend S3 bucket (GitHub Secret: S3_BUCKET_NAME)"
  value       = aws_s3_bucket.frontend.bucket
}

output "api_invoke_url" {
  description = "HTTP API invoke URL (GitHub Secret: REACT_APP_API_GATEWAY_URL)"
  value       = aws_apigatewayv2_stage.prod.invoke_url
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID (GitHub Secret: REACT_APP_COGNITO_USER_POOL_ID)"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  description = "Cognito app client ID (GitHub Secret: REACT_APP_COGNITO_CLIENT_ID)"
  value       = aws_cognito_user_pool_client.web.id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "lambda_function_arns" {
  description = "ARNs of the API-backed Lambda functions"
  value       = { for k, fn in aws_lambda_function.functions : fn.function_name => fn.arn }
}

output "post_confirmation_lambda_arn" {
  description = "ARN of the Cognito trigger Lambda"
  value       = aws_lambda_function.post_confirmation.arn
}

output "dynamodb_table_names" {
  description = "All DynamoDB table names"
  value = [
    aws_dynamodb_table.products.name,
    aws_dynamodb_table.users.name,
    aws_dynamodb_table.orders.name,
    aws_dynamodb_table.coupons.name,
    aws_dynamodb_table.cart_wishlist.name,
  ]
}

output "route53_zone_id" {
  description = "Hosted zone ID for strideluxstore.com"
  value       = data.aws_route53_zone.main.zone_id
}

output "github_actions_access_key_id" {
  description = "Access key ID for github-actions-stridelux (GitHub Secret: AWS_ACCESS_KEY_ID)"
  value       = aws_iam_access_key.github_actions.id
}

output "github_actions_secret_access_key" {
  description = "Secret access key (GitHub Secret: AWS_SECRET_ACCESS_KEY) — sensitive"
  value       = aws_iam_access_key.github_actions.secret
  sensitive   = true
}

output "ses_domain_identity_arn" {
  description = "SES domain identity ARN"
  value       = aws_ses_domain_identity.main.arn
}
