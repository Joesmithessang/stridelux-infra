#############################################
# StrideLux — ses.tf
# Domain identity + DKIM for order notification emails.
# Sender: orders@strideluxstore.com (used by admin + payments Lambdas).
#############################################

resource "aws_ses_domain_identity" "main" {
  domain = var.domain_name
}

resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# Verification completes once the DKIM CNAMEs in route53.tf resolve
resource "aws_ses_domain_identity_verification" "main" {
  domain     = aws_ses_domain_identity.main.id
  depends_on = [aws_route53_record.ses_dkim]
}

# Specific sender address identity
resource "aws_ses_email_identity" "orders" {
  email = "orders@${var.domain_name}"
}

#############################################
# SSM Parameter Store — sensitive Stripe values
# (Lambda env vars are fed from Terraform variables for parity with the
# live setup; these parameters give a durable, encrypted source of truth
# outside of state-only storage.)
#############################################

resource "aws_ssm_parameter" "stripe_secret_key" {
  name  = "/stridelux/${var.environment}/stripe_secret_key"
  type  = "SecureString"
  value = var.stripe_secret_key
  tags  = local.common_tags
}

resource "aws_ssm_parameter" "stripe_webhook_secret" {
  name  = "/stridelux/${var.environment}/stripe_webhook_secret"
  type  = "SecureString"
  value = var.stripe_webhook_secret
  tags  = local.common_tags
}
