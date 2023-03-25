data "archive_file" "archive_cloudtrail_getObject_lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda-code/index.js"
  output_path = "${path.module}/lambda-code/archive.zip"
}

resource "aws_lambda_function" "s3_get_object_alarm" {
  filename      = "${path.module}/lambda-code/archive.zip"
  function_name = "${var.environment}-s3-getObject"
  role          = aws_iam_role.s3_keys_monitoring_getObject_lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs16.x"
  timeout       = 360
  memory_size   = 2048

  source_code_hash = data.archive_file.archive_cloudtrail_getObject_lambda.output_base64sha256

  environment {
    variables = {
      environment = var.environment
      account_id = var.account_id
      webhook_url = var.webhook_url
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_permission" "get_object_logging" {
  action        = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.s3_get_object_alarm.arn
  principal     = "logs.ap-southeast-1.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
}

resource "aws_cloudwatch_log_subscription_filter" "logging" {
  depends_on      = [aws_lambda_permission.get_object_logging]
  destination_arn = aws_lambda_function.s3_get_object_alarm.arn
  filter_pattern  = "{$.eventName = \"GetObject\"}"
  log_group_name  = aws_cloudwatch_log_group.cloudtrail_logs.name
  name            = "s3-getObject-selfie"
}