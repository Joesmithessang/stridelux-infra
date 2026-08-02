#############################################
# StrideLux — cloudwatch.tf
# Explicit log groups (Lambda would otherwise auto-create them with
# retention = never expire). Managing them here sets 30-day retention.
# No dashboards or alarms — basic logging only, matching live.
#############################################

resource "aws_cloudwatch_log_group" "lambda" {
  for_each = aws_lambda_function.functions

  name              = "/aws/lambda/${each.value.function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}

resource "aws_cloudwatch_log_group" "post_confirmation" {
  name              = "/aws/lambda/${aws_lambda_function.post_confirmation.function_name}"
  retention_in_days = var.log_retention_days
  tags              = local.common_tags
}
