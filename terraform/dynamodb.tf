#############################################
# StrideLux — dynamodb.tf
# All tables On-Demand (PAY_PER_REQUEST). Only key/GSI attributes are
# declared — non-key attributes (name, price, etc.) are schemaless.
#############################################

resource "aws_dynamodb_table" "products" {
  name         = "stridelux-products"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "productId"
  tags         = local.common_tags

  attribute {
    name = "productId"
    type = "S"
  }
  attribute {
    name = "category"
    type = "S"
  }
  attribute {
    name = "brand"
    type = "S"
  }
  attribute {
    name = "createdAt"
    type = "S"
  }

  global_secondary_index {
    name            = "category-index"
    hash_key        = "category"
    range_key       = "createdAt"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "brand-index"
    hash_key        = "brand"
    range_key       = "createdAt"
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_table" "users" {
  name         = "stridelux-users"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId" # Cognito sub
  tags         = local.common_tags

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "email"
    type = "S"
  }

  global_secondary_index {
    name            = "email-index"
    hash_key        = "email"
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_table" "orders" {
  name         = "stridelux-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "orderId"
  tags         = local.common_tags

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "orderId"
    type = "S"
  }
  attribute {
    name = "status"
    type = "S"
  }
  attribute {
    name = "createdAt"
    type = "S"
  }

  global_secondary_index {
    name            = "orderId-index"
    hash_key        = "orderId"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "status-index"
    hash_key        = "status"
    range_key       = "createdAt"
    projection_type = "ALL"
  }
}

resource "aws_dynamodb_table" "coupons" {
  name         = "stridelux-coupons"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "couponId"
  tags         = local.common_tags

  attribute {
    name = "couponId"
    type = "S"
  }
  attribute {
    name = "code"
    type = "S"
  }

  global_secondary_index {
    name            = "code-index"
    hash_key        = "code"
    projection_type = "ALL"
  }
}

# Composite key, no GSIs — all queries use begins_with on the SK
# itemId format: "CART#{productId}#{size}" or "WISHLIST#{productId}"
resource "aws_dynamodb_table" "cart_wishlist" {
  name         = "stridelux-cart-wishlist"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "itemId"
  tags         = local.common_tags

  attribute {
    name = "userId"
    type = "S"
  }
  attribute {
    name = "itemId"
    type = "S"
  }
}
