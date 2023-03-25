data "aws_caller_identity" "current" {}

data "aws_canonical_user_id" "current" {}

data "aws_s3_bucket" "s3_bucket_info" {
  bucket = "${var.environment}-${var.project}-selfie"
}

# ------------------------------------------------------------
# CloudTrail Configuration
# ------------------------------------------------------------
resource "aws_cloudtrail" "cloudtrail_info" {
  depends_on = [aws_s3_bucket_policy.bucket_policy]
  name                          = "selfie-getObject"
  s3_bucket_name                = aws_s3_bucket.s3_bucket_info.id
  s3_key_prefix                 = "prefix"
  include_global_service_events = false

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn = aws_iam_role.cloudwatch_role.arn
  enable_log_file_validation = true

  event_selector {
    read_write_type           = "ReadOnly"
    include_management_events = false

    data_resource {
      type = "AWS::S3::Object"

      # Make sure to append a trailing '/' to your ARN if you want
      # to monitor all objects in a bucket.
      values = ["${data.aws_s3_bucket.s3_bucket_info.arn}/"]
    }
  }
}

resource "aws_s3_bucket" "s3_bucket_info" {
  bucket        = "${var.environment}-get-object-cloudtrail-logs"
  force_destroy = true

  versioning {
    enabled = true
  }

  grant {
    id          = data.aws_canonical_user_id.current.id
    permissions = [
        "READ",
        "WRITE",
    ]
    type        = "CanonicalUser"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_bucket" {
  bucket = aws_s3_bucket.s3_bucket_info.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------
# S3 Bucket Policy
# ------------------------------------------------------------
data "aws_iam_policy_document" "policy_document" {
  statement {
    sid    = "DenyDeletion"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["s3:DeleteBucket"]
    resources = ["arn:aws:s3:::${var.environment}-get-object-cloudtrail-logs"]
  }

  statement {
    sid    = "DenyObjectDeletion"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = ["s3:DeleteObject", "s3:DeleteObjectVersion"]
    resources = ["arn:aws:s3:::${var.environment}-get-object-cloudtrail-logs/*"]
  }

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.s3_bucket_info.arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.s3_bucket_info.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
  }
}
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.s3_bucket_info.id
  policy = data.aws_iam_policy_document.policy_document.json
}