#############################################
# StrideLux — variables.tf
#############################################

variable "aws_region" {
  description = "Primary AWS region for all resources (CloudFront ACM cert must also be us-east-1)."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment name (used in tags and the API Gateway stage)."
  type        = string
  default     = "prod"
}

variable "domain_name" {
  description = "Apex custom domain served by CloudFront."
  type        = string
  default     = "strideluxstore.com"
}

variable "github_actions_user_name" {
  description = "IAM user name used by the GitHub Actions CI/CD pipeline."
  type        = string
  default     = "github-actions-stridelux"
}

variable "stripe_secret_key" {
  description = "Stripe secret API key (sk_...). Stored in SSM and injected into stridelux-payments-fn."
  type        = string
  sensitive   = true
}

variable "stripe_webhook_secret" {
  description = "Stripe webhook signing secret (whsec_...). Stored in SSM and injected into stridelux-payments-fn."
  type        = string
  sensitive   = true
}

variable "log_retention_days" {
  description = "CloudWatch log retention for Lambda log groups. Live setup is 'never expire'; 30 days recommended."
  type        = number
  default     = 30
}
