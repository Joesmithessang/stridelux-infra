#############################################
# StrideLux — iam.tf
# Lambda execution roles (least-privilege, per-function) and the
# github-actions-stridelux CI/CD user.
#############################################

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Reused fragments -------------------------------------------------

locals {
  logs_statement = {
    Effect   = "Allow"
    Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    Resource = "*"
  }
}

# ── stridelux-products-fn ─────────────────────────────────────────

resource "aws_iam_role" "products" {
  name               = "stridelux-products-fn-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "products" {
  name = "stridelux-products-fn-policy"
  role = aws_iam_role.products.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
          "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.products.arn,
          "${aws_dynamodb_table.products.arn}/index/*",
        ]
      },
      local.logs_statement,
    ]
  })
}

# ── stridelux-orders-fn ───────────────────────────────────────────

resource "aws_iam_role" "orders" {
  name               = "stridelux-orders-fn-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "orders" {
  name = "stridelux-orders-fn-policy"
  role = aws_iam_role.orders.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
          "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.orders.arn,
          "${aws_dynamodb_table.orders.arn}/index/*",
          aws_dynamodb_table.products.arn,
          "${aws_dynamodb_table.products.arn}/index/*",
        ]
      },
      local.logs_statement,
    ]
  })
}

# ── stridelux-admin-fn ────────────────────────────────────────────

resource "aws_iam_role" "admin" {
  name               = "stridelux-admin-fn-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "admin_ses" {
  name = "stridelux-admin-fn-ses-policy"
  role = aws_iam_role.admin.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "admin" {
  name = "stridelux-admin-fn-policy"
  role = aws_iam_role.admin.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
          "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.orders.arn,
          "${aws_dynamodb_table.orders.arn}/index/*",
          aws_dynamodb_table.products.arn,
          "${aws_dynamodb_table.products.arn}/index/*",
          aws_dynamodb_table.users.arn,
          "${aws_dynamodb_table.users.arn}/index/*",
          aws_dynamodb_table.coupons.arn,
          "${aws_dynamodb_table.coupons.arn}/index/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "cognito-idp:AdminCreateUser",
          "cognito-idp:AdminAddUserToGroup",
          "cognito-idp:AdminUpdateUserAttributes",
        ]
        Resource = aws_cognito_user_pool.main.arn
      },
      local.logs_statement,
    ]
  })
}

# ── stridelux-users-fn ────────────────────────────────────────────

resource "aws_iam_role" "users" {
  name               = "stridelux-users-fn-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "users" {
  name = "stridelux-users-fn-policy"
  role = aws_iam_role.users.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:UpdateItem", "dynamodb:Query",
          "dynamodb:PutItem", "dynamodb:DeleteItem", "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.users.arn,
          "${aws_dynamodb_table.users.arn}/index/*",
        ]
      },
      local.logs_statement,
    ]
  })
}

# ── stridelux-payments-fn ─────────────────────────────────────────

resource "aws_iam_role" "payments" {
  name               = "stridelux-payments-fn-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy" "payments_ses" {
  name = "stridelux-payments-fn-ses-policy"
  role = aws_iam_role.payments.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail"]
        Resource = "*"
      }
    ]
  })
}

# Customer-managed policy (matches live: stridelux-payments-fn-Policy)
resource "aws_iam_policy" "payments" {
  name = "stridelux-payments-fn-Policy"
  tags = local.common_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem",
          "dynamodb:UpdateItem", "dynamodb:Query", "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.orders.arn,
          "${aws_dynamodb_table.orders.arn}/index/*",
          aws_dynamodb_table.coupons.arn,
          "${aws_dynamodb_table.coupons.arn}/index/*",
          aws_dynamodb_table.products.arn,
          "${aws_dynamodb_table.products.arn}/index/*",
        ]
      },
      local.logs_statement,
    ]
  })
}

resource "aws_iam_role_policy_attachment" "payments" {
  role       = aws_iam_role.payments.name
  policy_arn = aws_iam_policy.payments.arn
}

# ── stridelux-cart-fn ─────────────────────────────────────────────

resource "aws_iam_role" "cart" {
  name               = "stridelux-cart-fn-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

# Customer-managed policy (matches live: stridelux-cart-fn-rolePolicy)
resource "aws_iam_policy" "cart" {
  name = "stridelux-cart-fn-rolePolicy"
  tags = local.common_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem",
          "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:BatchWriteItem"
        ]
        Resource = [
          aws_dynamodb_table.cart_wishlist.arn,
          "${aws_dynamodb_table.cart_wishlist.arn}/index/*",
        ]
      },
      {
        Effect = "Allow"
        Action = ["dynamodb:GetItem", "dynamodb:BatchGetItem"]
        Resource = [
          aws_dynamodb_table.products.arn,
          "${aws_dynamodb_table.products.arn}/index/*",
        ]
      },
      local.logs_statement,
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cart" {
  role       = aws_iam_role.cart.name
  policy_arn = aws_iam_policy.cart.arn
}

# ── stridelux-post-confirmation-fn ────────────────────────────────

resource "aws_iam_role" "post_confirmation" {
  name               = "stridelux-post-confirmation-fn-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.common_tags
}

# Customer-managed policy (matches live: stridelux-post-confirmation-fn-Policy)
resource "aws_iam_policy" "post_confirmation" {
  name = "stridelux-post-confirmation-fn-Policy"
  tags = local.common_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.users.arn
      },
      {
        Effect   = "Allow"
        Action   = ["cognito-idp:AdminAddUserToGroup"]
        Resource = aws_cognito_user_pool.main.arn
      },
      local.logs_statement,
    ]
  })
}

resource "aws_iam_role_policy_attachment" "post_confirmation" {
  role       = aws_iam_role.post_confirmation.name
  policy_arn = aws_iam_policy.post_confirmation.arn
}

# ── github-actions-stridelux (CI/CD, programmatic only) ───────────

resource "aws_iam_user" "github_actions" {
  name = var.github_actions_user_name
  tags = local.common_tags
}

resource "aws_iam_policy" "github_actions" {
  name = "GitHubActions-StrideLux-Deploy"
  tags = local.common_tags
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          aws_s3_bucket.frontend.arn,
          "${aws_s3_bucket.frontend.arn}/*",
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudfront:CreateInvalidation"]
        Resource = aws_cloudfront_distribution.frontend.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "github_actions" {
  user       = aws_iam_user.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}

# Access key for GitHub Secrets. The secret is only readable in state /
# first apply output — rotate via the console or `terraform taint` as needed.
resource "aws_iam_access_key" "github_actions" {
  user = aws_iam_user.github_actions.name
}
