#############################################
# StrideLux — imports.tf
# Declarative adoption of the live environment (Terraform >= 1.5).
# Fill in the ALL-CAPS placeholders, then run `terraform plan`.
# The plan should flip from "120 to add" to mostly "to import", with a
# small remainder of genuinely-new adds (SSM params, log groups, etc.).
#
# ID lookup one-liners (PowerShell-safe) are noted above each section.
# Delete this file once state is fully adopted and plan shows no drift.
#############################################

# ── S3 ────────────────────────────────────────────────────────────
import {
  to = aws_s3_bucket.frontend
  id = "stridelux-frontend"
}
import {
  to = aws_s3_bucket_public_access_block.frontend
  id = "stridelux-frontend"
}
import {
  to = aws_s3_bucket_server_side_encryption_configuration.frontend
  id = "stridelux-frontend"
}
import {
  to = aws_s3_bucket_policy.frontend
  id = "stridelux-frontend"
}

# ── CloudFront ────────────────────────────────────────────────────
# aws cloudfront list-distributions --query "DistributionList.Items[].{Id:Id,Domain:DomainName}"
# aws cloudfront list-origin-access-controls --query "OriginAccessControlList.Items[].{Id:Id,Name:Name}"
import {
  to = aws_cloudfront_distribution.frontend
  id = "E1895JQCQ2M0NO"
}
import {
  to = aws_cloudfront_origin_access_control.frontend
  id = "EEK4NVY6DWL0C"
}

# ── ACM (us-east-1) ──────────────────────────────────────────────
# aws acm list-certificates --region us-east-1 --query "CertificateSummaryList[].{Arn:CertificateArn,Domain:DomainName}"
import {
  to = aws_acm_certificate.domain
  id = "arn:aws:acm:us-east-1:254566860404:certificate/efe20743-e692-44dd-8c28-623be68f8a2e"
}

# ── Cognito ──────────────────────────────────────────────────────
# aws cognito-idp list-user-pools --max-results 20 --query "UserPools[].{Id:Id,Name:Name}"
# aws cognito-idp list-user-pool-clients --user-pool-id us-east-1_QLfNJkoAW --query "UserPoolClients[]"
import {
  to = aws_cognito_user_pool.main
  id = "us-east-1_QLfNJkoAW"
}
import {
  to = aws_cognito_user_pool_client.web
  id = "us-east-1_QLfNJkoAW/26k73e2fqn4pi5dpf5bbn7mbga"
}
import {
  to = aws_cognito_user_group.admins
  id = "us-east-1_QLfNJkoAW/Admins"
}
import {
  to = aws_cognito_user_group.customers
  id = "us-east-1_QLfNJkoAW/Customers"
}
import {
  to = aws_lambda_permission.cognito_post_confirmation
  id = "stridelux-post-confirmation-fn/CSI_PostConfirmation_us-east-1QLfNJkoAW_CSI_PostConfirmation"
}
import {
  to = aws_lambda_permission.cognito_post_authentication
  id = "stridelux-post-confirmation-fn/CSI_PostAuthentication_us-east-1QLfNJkoAW_CSI_PostAuthentication"
}

# ── DynamoDB ─────────────────────────────────────────────────────
import {
  to = aws_dynamodb_table.products
  id = "stridelux-products"
}
import {
  to = aws_dynamodb_table.users
  id = "stridelux-users"
}
import {
  to = aws_dynamodb_table.orders
  id = "stridelux-orders"
}
import {
  to = aws_dynamodb_table.coupons
  id = "stridelux-coupons"
}
import {
  to = aws_dynamodb_table.cart_wishlist
  id = "stridelux-cart-wishlist"
}

# ── Lambda functions ─────────────────────────────────────────────
import {
  to = aws_lambda_function.functions["products"]
  id = "stridelux-products-fn"
}
import {
  to = aws_lambda_function.functions["orders"]
  id = "stridelux-orders-fn"
}
import {
  to = aws_lambda_function.functions["admin"]
  id = "stridelux-admin-fn"
}
import {
  to = aws_lambda_function.functions["users"]
  id = "stridelux-users-fn"
}
import {
  to = aws_lambda_function.functions["payments"]
  id = "stridelux-payments-fn"
}
import {
  to = aws_lambda_function.functions["cart"]
  id = "stridelux-cart-fn"
}
import {
  to = aws_lambda_function.post_confirmation
  id = "stridelux-post-confirmation-fn"
}

# ── IAM roles ────────────────────────────────────────────────────
import {
  to = aws_iam_role.products
  id = "stridelux-products-fn-role"
}
import {
  to = aws_iam_role.orders
  id = "stridelux-orders-fn-role"
}
import {
  to = aws_iam_role.admin
  id = "stridelux-admin-fn-role"
}
import {
  to = aws_iam_role.users
  id = "stridelux-users-fn-role"
}
import {
  to = aws_iam_role.payments
  id = "stridelux-payments-fn-role"
}
import {
  to = aws_iam_role.cart
  id = "stridelux-cart-fn-role"
}
import {
  to = aws_iam_role.post_confirmation
  id = "stridelux-post-confirmation-fn-role"
}

# ── IAM inline role policies (id = role_name:policy_name) ────────
import {
  to = aws_iam_role_policy.products
  id = "stridelux-products-fn-role:stridelux-products-fn-policy"
}
import {
  to = aws_iam_role_policy.orders
  id = "stridelux-orders-fn-role:stridelux-orders-fn-policy"
}
import {
  to = aws_iam_role_policy.admin_ses
  id = "stridelux-admin-fn-role:stridelux-admin-fn-ses-policy"
}
import {
  to = aws_iam_role_policy.admin
  id = "stridelux-admin-fn-role:stridelux-admin-fn-policy"
}
import {
  to = aws_iam_role_policy.users
  id = "stridelux-users-fn-role:stridelux-users-fn-policy"
}
import {
  to = aws_iam_role_policy.payments_ses
  id = "stridelux-payments-fn-role:stridelux-payments-fn-ses-policy"
}

# ── IAM customer-managed policies + attachments ──────────────────
# aws iam list-policies --scope Local --query "Policies[].{Arn:Arn,Name:PolicyName}"
import {
  to = aws_iam_policy.payments
  id = "arn:aws:iam::254566860404:policy/stridelux-payments-fn-Policy"
}
import {
  to = aws_iam_policy.cart
  id = "arn:aws:iam::254566860404:policy/stridelux-cart-fn-rolePolicy"
}
import {
  to = aws_iam_policy.post_confirmation
  id = "arn:aws:iam::254566860404:policy/stridelux-post-confirmation-fn-Policy"
}
import {
  to = aws_iam_role_policy_attachment.payments
  id = "stridelux-payments-fn-role/arn:aws:iam::254566860404:policy/stridelux-payments-fn-Policy"
}
import {
  to = aws_iam_role_policy_attachment.cart
  id = "stridelux-cart-fn-role/arn:aws:iam::254566860404:policy/stridelux-cart-fn-rolePolicy"
}
import {
  to = aws_iam_role_policy_attachment.post_confirmation
  id = "stridelux-post-confirmation-fn-role/arn:aws:iam::254566860404:policy/stridelux-post-confirmation-fn-Policy"
}

# ── github-actions user ──────────────────────────────────────────
# NOTE: the existing access key CANNOT be imported with its secret.
# Import the user + customer managed policy only; let Terraform create a NEW key
# aws iam list-attached-user-policies --user-name github-actions-stridelux
# via aws_iam_access_key, update GitHub Secrets with the new pair, then
# delete the old key in the console.
import {
  to = aws_iam_user.github_actions
  id = "github-actions-stridelux"
}
import {
  to = aws_iam_policy.github_actions
  id = "arn:aws:iam::254566860404:policy/GitHubActions-StrideLux-Deploy"
}
import {
  to = aws_iam_user_policy_attachment.github_actions
  id = "github-actions-stridelux/arn:aws:iam::254566860404:policy/GitHubActions-StrideLux-Deploy"
}
# aws iam list-user-policies --user-name github-actions-stridelux

# ── API Gateway (HTTP API) ───────────────────────────────────────
# aws apigatewayv2 get-apis --query "Items[].{Id:ApiId,Name:Name}"
# aws apigatewayv2 get-authorizers --api-id op6mdpi7xd #API_ID
# aws apigatewayv2 get-integrations --api-id op6mdpi7xd #API_ID
# aws apigatewayv2 get-routes --api-id op6mdpi7xd --query "Items[].{Id:RouteId,Key:RouteKey}"
import {
  to = aws_apigatewayv2_api.main
  id = "op6mdpi7xd"
}
import {
  to = aws_apigatewayv2_stage.prod
  id = "op6mdpi7xd/prod"
}
import {
  to = aws_apigatewayv2_authorizer.cognito
  id = "op6mdpi7xd/bf8loe"
}
# Integrations — match each integration's target Lambda to the map key:
import {
  to = aws_apigatewayv2_integration.lambda["products"]
  id = "op6mdpi7xd/t1knlyb"
}
import {
  to = aws_apigatewayv2_integration.lambda["orders"]
  id = "op6mdpi7xd/fyk1lsc"
}
import {
  to = aws_apigatewayv2_integration.lambda["admin"]
  id = "op6mdpi7xd/ycfuppm"
}
import {
  to = aws_apigatewayv2_integration.lambda["users"]
  id = "op6mdpi7xd/q9usg3c"
}
import {
  to = aws_apigatewayv2_integration.lambda["payments"]
  id = "op6mdpi7xd/2gwct3a"
}
import {
  to = aws_apigatewayv2_integration.lambda["cart"]
  id = "op6mdpi7xd/lurq5nr"
}

# Routes: 35 import blocks of the form:
#   import {
#     to = aws_apigatewayv2_route.routes["GET /products"]
#     id = "op6mdpi7xd/ROUTE_ID"
#   }
# Generate them from `get-routes` output — the RouteKey maps 1:1 to the
# map key in local.routes. (See README snippet for a generator script.)

import {
  to = aws_apigatewayv2_route.routes["GET /admin/reports"]
  id = "op6mdpi7xd/2ggqig4"
}

import {
  to = aws_apigatewayv2_route.routes["POST /admin/coupons"]
  id = "op6mdpi7xd/520krf8"
}

import {
  to = aws_apigatewayv2_route.routes["PUT /admin/orders/{orderId}/status"]
  id = "op6mdpi7xd/5o2mr6g"
}

import {
  to = aws_apigatewayv2_route.routes["GET /users/me"]
  id = "op6mdpi7xd/5r9rqbt"
}

import {
  to = aws_apigatewayv2_route.routes["POST /admin/employees"]
  id = "op6mdpi7xd/7ba0gdk"
}

import {
  to = aws_apigatewayv2_route.routes["DELETE /admin/employees/{id}"]
  id = "op6mdpi7xd/813vuhm"
}

import {
  to = aws_apigatewayv2_route.routes["POST /orders"]
  id = "op6mdpi7xd/8h6qk5v"
}

import {
  to = aws_apigatewayv2_route.routes["PUT /admin/coupons/{couponId}"]
  id = "op6mdpi7xd/9745o2a"
}

import {
  to = aws_apigatewayv2_route.routes["PUT /admin/employees/{id}"]
  id = "op6mdpi7xd/9hfrchr"
}

import {
  to = aws_apigatewayv2_route.routes["PUT /admin/customer/{id}"]
  id = "op6mdpi7xd/200nvp9"
}

import {
  to = aws_apigatewayv2_route.routes["GET /products"]
  id = "op6mdpi7xd/al3q1fl"
}

import {
  to = aws_apigatewayv2_route.routes["GET /orders/{orderId}"]
  id = "op6mdpi7xd/ayxvfju"
}

import {
  to = aws_apigatewayv2_route.routes["DELETE /wishlist/{productId}"]
  id = "op6mdpi7xd/b9bn9gk"
}

import {
  to = aws_apigatewayv2_route.routes["DELETE /products/{id}"]
  id = "op6mdpi7xd/cfvw5ot"
}

import {
  to = aws_apigatewayv2_route.routes["GET /orders"]
  id = "op6mdpi7xd/chrtya4"
}

import {
  to = aws_apigatewayv2_route.routes["PUT /users/me"]
  id = "op6mdpi7xd/e8enir6"
}

import {
  to = aws_apigatewayv2_route.routes["POST /coupons/validate"]
  id = "op6mdpi7xd/g1ip1x4"
}

import {
  to = aws_apigatewayv2_route.routes["DELETE /users/me/addresses/{addressId}"]
  id = "op6mdpi7xd/hfhyu6t"
}

import {
  to = aws_apigatewayv2_route.routes["POST /wishlist"]
  id = "op6mdpi7xd/hwks5ro"
}

import {
  to = aws_apigatewayv2_route.routes["POST /payments/webhook"]
  id = "op6mdpi7xd/i5c50br"
}

import {
  to = aws_apigatewayv2_route.routes["GET /admin/dashboard"]
  id = "op6mdpi7xd/lkof1nb"
}

import {
  to = aws_apigatewayv2_route.routes["POST /products"]
  id = "op6mdpi7xd/lw24d2c"
}

import {
  to = aws_apigatewayv2_route.routes["GET /wishlist"]
  id = "op6mdpi7xd/myebb65"
}

import {
  to = aws_apigatewayv2_route.routes["DELETE /cart/{productId}"]
  id = "op6mdpi7xd/n69a446"
}

import {
  to = aws_apigatewayv2_route.routes["PUT /products/{id}"]
  id = "op6mdpi7xd/nglbs20"
}

import {
  to = aws_apigatewayv2_route.routes["GET /admin/orders"]
  id = "op6mdpi7xd/ngp3mk5"
}

import {
  to = aws_apigatewayv2_route.routes["POST /cart"]
  id = "op6mdpi7xd/pl09wc1"
}

import {
  to = aws_apigatewayv2_route.routes["POST /users/me/addresses"]
  id = "op6mdpi7xd/q9yh7y6"
}

import {
  to = aws_apigatewayv2_route.routes["GET /products/{id}"]
  id = "op6mdpi7xd/qjtcmft"
}

import {
  to = aws_apigatewayv2_route.routes["POST /payments/checkout-session"]
  id = "op6mdpi7xd/qq2dekk"
}

import {
  to = aws_apigatewayv2_route.routes["GET /users/me/addresses"]
  id = "op6mdpi7xd/re9mnik"
}

import {
  to = aws_apigatewayv2_route.routes["GET /admin/coupons"]
  id = "op6mdpi7xd/sicb8bv"
}

import {
  to = aws_apigatewayv2_route.routes["GET /cart"]
  id = "op6mdpi7xd/skyvgw9"
}

import {
  to = aws_apigatewayv2_route.routes["DELETE /cart"]
  id = "op6mdpi7xd/uq6g13k"
}

import {
  to = aws_apigatewayv2_route.routes["DELETE /admin/coupons/{couponId}"]
  id = "op6mdpi7xd/vpixac7"
}

import {
  to = aws_apigatewayv2_route.routes["PUT /cart/{productId}"]
  id = "op6mdpi7xd/wrxhctd"
}

import {
  to = aws_apigatewayv2_route.routes["PUT /users/me/addresses/{addressId}"]
  id = "op6mdpi7xd/xwzcnxa"
}

import {
  to = aws_apigatewayv2_route.routes["GET /admin/users"]
  id = "op6mdpi7xd/z3nd64e"
}

# ── Route 53 records (id = ZONEID_name_TYPE) ─────────────────────
import {
  to = aws_route53_record.apex
  id = "Z10211162XYVY2PSC2HXQ_strideluxstore.com_A"
}
import {
  to = aws_route53_record.www
  id = "Z10211162XYVY2PSC2HXQ_www.strideluxstore.com_A"
}
import {
  to = aws_route53_record.dmarc
  id = "Z10211162XYVY2PSC2HXQ__dmarc.strideluxstore.com_TXT"
}
# DKIM CNAMEs (count-indexed; order must match dkim_tokens order —
# safest to let plan tell you, or import after first plan shows tokens):
import {
  to = aws_route53_record.ses_dkim[0]
  id = "Z10211162XYVY2PSC2HXQ_zmereyb2vey7sdxl7o2hply3nihg2oa6._domainkey.strideluxstore.com_CNAME"
}
import {
  to = aws_route53_record.ses_dkim[1]
  id = "Z10211162XYVY2PSC2HXQ_odvkxs7g3hbu7ard3aktiwv3qhona7lw._domainkey.strideluxstore.com_CNAME"
}
import {
  to = aws_route53_record.ses_dkim[2]
  id = "Z10211162XYVY2PSC2HXQ_lmkuzvhrsocxdk44gekhuajihbbtj5bf._domainkey.strideluxstore.com_CNAME"
}
# ACM validation CNAME — keyed by domain name in for_each:
import {
  to = aws_route53_record.acm_validation["strideluxstore.com"]
  id = "Z10211162XYVY2PSC2HXQ__24a9c23f9a6fb9ab379bad5a37760b5e.strideluxstore.com_CNAME"
}

# If the cert covers www with its own validation record, add:
# import {
#   to = aws_route53_record.acm_validation["www.strideluxstore.com"]
#   id = "Z10211162XYVY2PSC2HXQ_VALIDATION_NAME_CNAME"
# }

# ── SES ──────────────────────────────────────────────────────────
import {
  to = aws_ses_domain_identity.main
  id = "strideluxstore.com"
}
import {
  to = aws_ses_domain_dkim.main
  id = "strideluxstore.com"
}
import {
  to = aws_ses_email_identity.orders
  id = "orders@strideluxstore.com"
}

#############################################
# NOT imported (Terraform will create these — safe, no collisions):
# - aws_ssm_parameter.* (new)
# - aws_cloudwatch_log_group.* (see note below)
# - aws_lambda_permission.* (see note below)
# - aws_acm_certificate_validation.domain (state-only shim, no real infra)
# - aws_iam_access_key.github_actions (new key by design — rotate secrets)
#
# Log groups: they already exist (auto-created by Lambda), so creating
# them WILL collide. Either import each:
#   import { to = aws_cloudwatch_log_group.lambda["products"]
#            id = "/aws/lambda/stridelux-products-fn" }  (repeat x6 + post_confirmation)
# ...or delete the auto-created groups first and let Terraform recreate
# them with retention (you lose old logs).
#
# Lambda permissions: existing statements with the same statement_id will
# collide on apply. Import as FUNCTION_NAME/STATEMENT_ID, e.g.:
#   import { to = aws_lambda_permission.apigw["products"]
#            id = "stridelux-products-fn/AllowAPIGatewayInvoke" }
# Check live statement IDs first:
#   aws lambda get-policy --function-name stridelux-products-fn
# If the live statement_id differs (console-created ones look like
# "lambda-xxxx..."), either update the config's statement_id to match and
# import, or delete the live statement and let Terraform add its own.
#############################################
