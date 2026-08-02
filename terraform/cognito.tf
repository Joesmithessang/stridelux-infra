#############################################
# StrideLux — cognito.tf
# User Pool + SPA app client + groups + Lambda triggers.
# No Hosted UI, no OAuth, no client secret.
#############################################

resource "aws_cognito_user_pool" "main" {
  name = "stridelux-user-pool"
  deletion_protection = "ACTIVE"
  tags = local.common_tags

  # Sign-in with email or username, case-insensitive
  alias_attributes = ["email"]
  username_configuration {
    case_sensitive = false
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  mfa_configuration = "OFF"

  # Self-registration enabled
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # Code-based email verification
  auto_verified_attributes = ["email"]
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  # Cognito built-in email provider (not SES)
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Required standard attributes: email, name, phone_number
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }

  schema {
    name                     = "name"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }

  schema {
    name                     = "phone_number"
    attribute_data_type      = "String"
    required                 = true
    mutable                  = true
    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }

  # Custom attribute custom:role (String, mutable)
  schema {
    name                     = "role"
    attribute_data_type      = "String"
    developer_only_attribute = false
    required                 = false
    mutable                  = true
    string_attribute_constraints {
      min_length = 0
      max_length = 256
    }
  }

  # Same Lambda for BOTH triggers
  lambda_config {
    post_confirmation   = aws_lambda_function.post_confirmation.arn
    post_authentication = aws_lambda_function.post_confirmation.arn
  }

}

# Cognito must be allowed to invoke the trigger function
resource "aws_lambda_permission" "cognito_post_confirmation" {
  statement_id  = "CSI_PostConfirmation_us-east-1QLfNJkoAW_CSI_PostConfirmation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

resource "aws_lambda_permission" "cognito_post_authentication" {
  statement_id  = "CSI_PostAuthentication_us-east-1QLfNJkoAW_CSI_PostAuthentication"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

resource "aws_cognito_user_pool_client" "web" {
  name         = "stridelux-web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
  ]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "phone"]
  callback_urls                        = ["https://d84l1y8p4kdic.cloudfront.net"]
  supported_identity_providers         = ["COGNITO"]

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 5
  auth_session_validity  = 3
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true
}

resource "aws_cognito_user_group" "admins" {
  name         = "Admins"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Admin dashboard access"
  precedence   = 1
}

resource "aws_cognito_user_group" "customers" {
  name         = "Customers"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Standard registered customers"
  precedence   = 2
}
