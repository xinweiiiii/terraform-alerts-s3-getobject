# -----------------------------------------------------------------------------------
# iam role for lambda execution to send notification for getObject Selfie
# -----------------------------------------------------------------------------------
resource "aws_iam_role" "s3_keys_monitoring_getObject_lambda_role" {
  name = "${var.environment}-${var.project}-s3-get-object-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "template_file" "lambda_s3_keys_get_object_json" {
  template = file("${path.module}/config/s3-get-object-lambda-role.json")

  vars = {
    ACCOUNT_ID         = var.account_id
    ENVIRONMENT        = var.environment
  }

}

# Policy definition for the IAM role
resource "aws_iam_role_policy" "lambda_policy_s3_get_object_alarm_role" {
  name   = "${var.environment}-${var.project}-lambda-get-object-policy-alarm-role"
  role   = aws_iam_role.s3_keys_monitoring_getObject_lambda_role.id
  policy = data.template_file.lambda_s3_keys_get_object_json.rendered
}