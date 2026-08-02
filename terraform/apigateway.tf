#############################################
# StrideLux — apigateway.tf
# HTTP API (apigatewayv2) — NOT REST API.
# CORS at API level, JWT authorizer against Cognito, prod stage.
#############################################

resource "aws_apigatewayv2_api" "main" {
  name          = "stridelux-api"
  protocol_type = "HTTP"
  tags          = local.common_tags

  cors_configuration {
    allow_origins = [
      "https://${var.domain_name}",
      "https://www.${var.domain_name}",
      "https://d2kkmrzz6627xi.cloudfront.net",
      "http://localhost:3000",
    ]
    allow_headers = ["content-type", "authorization"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = var.environment # "prod"
  auto_deploy = true
  tags        = local.common_tags
}

resource "aws_apigatewayv2_authorizer" "cognito" {
  api_id           = aws_apigatewayv2_api.main.id
  name             = "cognito-authorizer"
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.main.id}"
    audience = [aws_cognito_user_pool_client.web.id]
  }
}

# ── Integrations (one per backend Lambda) ────────────────────────

locals {
  api_backends = ["products", "orders", "admin", "users", "payments", "cart"]

  # method + path → backend function key; protected = uses cognito-authorizer
  routes = {
    # PUBLIC
    "GET /products"                        = { fn = "products", protected = false }
    "GET /products/{id}"                   = { fn = "products", protected = false }
    "POST /payments/checkout-session"      = { fn = "payments", protected = false }
    "POST /payments/webhook"               = { fn = "payments", protected = false }
    "POST /coupons/validate"               = { fn = "payments", protected = false }

    # PROTECTED
    "POST /products"                       = { fn = "products", protected = true }
    "PUT /products/{id}"                   = { fn = "products", protected = true }
    "DELETE /products/{id}"                = { fn = "products", protected = true }
    "POST /orders"                         = { fn = "orders", protected = true }
    "GET /orders"                          = { fn = "orders", protected = true }
    "GET /orders/{orderId}"                = { fn = "orders", protected = true }
    "GET /admin/orders"                    = { fn = "orders", protected = true }
    "PUT /admin/orders/{orderId}/status"   = { fn = "admin", protected = true }
    "GET /admin/dashboard"                 = { fn = "admin", protected = true }
    "GET /admin/reports"                   = { fn = "admin", protected = true }
    "GET /admin/users"                     = { fn = "admin", protected = true }
    "PUT /admin/customer/{id}"             = { fn = "admin", protected = true }
    "POST /admin/employees"                = { fn = "admin", protected = true }
    "PUT /admin/employees/{id}"            = { fn = "admin", protected = true }
    "DELETE /admin/employees/{id}"         = { fn = "admin", protected = true }
    "GET /admin/coupons"                   = { fn = "admin", protected = true }
    "POST /admin/coupons"                  = { fn = "admin", protected = true }
    "PUT /admin/coupons/{couponId}"        = { fn = "admin", protected = true }
    "DELETE /admin/coupons/{couponId}"     = { fn = "admin", protected = true }
    "GET /users/me"                        = { fn = "users", protected = true }
    "PUT /users/me"                        = { fn = "users", protected = true }
    "GET /users/me/addresses"              = { fn = "users", protected = true }
    "POST /users/me/addresses"             = { fn = "users", protected = true }
    "PUT /users/me/addresses/{addressId}"  = { fn = "users", protected = true }
    "DELETE /users/me/addresses/{addressId}" = { fn = "users", protected = true }
    "GET /cart"                            = { fn = "cart", protected = true }
    "POST /cart"                           = { fn = "cart", protected = true }
    "PUT /cart/{productId}"                = { fn = "cart", protected = true }
    "DELETE /cart/{productId}"             = { fn = "cart", protected = true }
    "DELETE /cart"                         = { fn = "cart", protected = true }
    "GET /wishlist"                        = { fn = "cart", protected = true }
    "POST /wishlist"                       = { fn = "cart", protected = true }
    "DELETE /wishlist/{productId}"         = { fn = "cart", protected = true }
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  for_each = toset(local.api_backends)

  api_id                 = aws_apigatewayv2_api.main.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.functions[each.key].invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "routes" {
  for_each = local.routes

  api_id    = aws_apigatewayv2_api.main.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.lambda[each.value.fn].id}"

  authorization_type = each.value.protected ? "JWT" : "NONE"
  authorizer_id      = each.value.protected ? aws_apigatewayv2_authorizer.cognito.id : null
}

# Allow API Gateway to invoke each backend Lambda
resource "aws_lambda_permission" "apigw" {
  for_each = toset(local.api_backends)

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions[each.key].function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*/*"
}
