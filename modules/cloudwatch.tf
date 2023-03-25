# ------------------------------------------------------------
# Cloudwatch Configuration
# ------------------------------------------------------------
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name = "aws-cloudtrail-logs-bucket"
  retention_in_days = 365
}

# -----------------------------------------------------------------------------------
# CloudWatch IAM Role
# -----------------------------------------------------------------------------------
resource "aws_iam_role" "cloudwatch_role" {
  name = "${var.environment}-${var.project}-cloudwatch-cloudtrail-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

data "template_file" "cloudtrail_cloudwatch_json" {
  template = file("${path.module}/config/cloudtrail-cloudwatch-role.json")
}

# Policy definition for the IAM role
resource "aws_iam_role_policy" "lambda_policy_cloudtrail_cloudwatch" {
  name   = "${var.environment}-${var.project}-cloudtrail-cloudwatch-policy"
  role   = aws_iam_role.cloudwatch_role.id
  policy = data.template_file.cloudtrail_cloudwatch_json.rendered
}
