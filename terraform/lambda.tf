#############################################
# StrideLux — lambda.tf
# All 7 functions: Node.js 22.x, x86_64, index.handler, 29s timeout.
#
# Code deployment is owned by GitHub Actions. Terraform creates each
# function with a placeholder ZIP, then ignores filename/source_code_hash
# so the pipeline and Terraform never fight over the package.
# Real packages (payments/admin bundle Stripe + @aws-sdk/client-sesv2
# directly in node_modules — no layers) are pushed by CI.
#############################################

# Placeholder package used only at first create
data "archive_file" "placeholder" {
  type        = "zip"
  source_file = "${path.module}/lambda-placeholder/index.js"
  output_path = "${path.module}/lambda-placeholder/placeholder.zip"
}

locals {
  lambda_config = {
    "products" = {
      role_arn = aws_iam_role.products.arn
      env      = null
    }
    "orders" = {
      role_arn = aws_iam_role.orders.arn
      env      = null
    }
    "admin" = {
      role_arn = aws_iam_role.admin.arn
      env = {
        COGNITO_USER_POOL_ID = aws_cognito_user_pool.main.id
        FRONTEND_URL         = "https://${var.domain_name}"
        SES_FROM_ADDRESS     = "orders@${var.domain_name}"
      }
    }
    "users" = {
      role_arn = aws_iam_role.users.arn
      env      = null
    }
    "payments" = {
      role_arn = aws_iam_role.payments.arn
      env = {
        STRIPE_SECRET_KEY     = var.stripe_secret_key
        STRIPE_WEBHOOK_SECRET = var.stripe_webhook_secret
        FRONTEND_URL          = "https://${var.domain_name}"
        SES_FROM_ADDRESS      = "orders@${var.domain_name}"
      }
    }
    "cart" = {
      role_arn = aws_iam_role.cart.arn
      env      = null
    }
  }
}

resource "aws_lambda_function" "functions" {
  for_each = local.lambda_config

  function_name = "stridelux-${each.key}-fn"
  role          = each.value.role_arn
  runtime       = "nodejs22.x"
  architectures = ["x86_64"]
  handler       = "index.handler"
  timeout       = 29
  memory_size   = 128
  tags          = local.common_tags

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  dynamic "environment" {
    for_each = each.value.env == null ? [] : [each.value.env]
    content {
      variables = environment.value
    }
  }

  lifecycle {
    # Code is deployed by the GitHub Actions pipeline —
    # Terraform manages configuration only.
    ignore_changes = [filename, source_code_hash]
  }
}

# post-confirmation is a standalone resource (not in the for_each map) to
# break the dependency cycle: the Cognito pool's trigger references this
# function, while the admin/payments functions reference the pool's ID.
resource "aws_lambda_function" "post_confirmation" {
  function_name = "stridelux-post-confirmation-fn"
  role          = aws_iam_role.post_confirmation.arn
  runtime       = "nodejs22.x"
  architectures = ["x86_64"]
  handler       = "index.handler"
  timeout       = 29
  memory_size   = 128
  tags          = local.common_tags

  filename         = data.archive_file.placeholder.output_path
  source_code_hash = data.archive_file.placeholder.output_base64sha256

  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }
}
