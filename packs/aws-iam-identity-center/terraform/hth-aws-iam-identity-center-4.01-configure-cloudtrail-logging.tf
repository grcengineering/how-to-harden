# =============================================================================
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-4.1
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#41-configure-cloudtrail-logging
#   profile: L1
#   mode:    mutating
#   requires: AWS credentials in the Organizations management account for an organization trail (s3:CreateBucket, s3:PutBucketPolicy, cloudtrail:CreateTrail, cloudtrail:StartLogging)
#
# HTH AWS IAM Identity Center Control 4.1: Configure CloudTrail Logging
# Profile Level: L1 (Crawl)
# Frameworks: NIST AU-2, SOC 2 CC7.2, ISO 27001 A.12.4.1
# Source: https://howtoharden.com/guides/aws-iam-identity-center/#41-configure-cloudtrail-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# S3 bucket for CloudTrail logs with encryption and lifecycle
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = var.cloudtrail_bucket_name
  force_destroy = false

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "4.1-configure-cloudtrail-logging"
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.cloudtrail_kms_key_id
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket                  = aws_s3_bucket.cloudtrail_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  rule {
    id     = "archive-old-logs"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
  }
}

# S3 bucket policy allowing CloudTrail to write. Both statements are scoped
# with aws:SourceArn to this trail, so no other trail can use the bucket.
data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  trail_name = "hth-sso-audit-trail"
  trail_arn  = "arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:trail/${local.trail_name}"
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = local.trail_arn
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = local.trail_arn
          }
        }
      }
    ]
  })
}

# Organization-level CloudTrail capturing SSO management events.
# depends_on: CreateTrail validates the bucket policy and fails with
# InsufficientS3BucketPolicyException if the policy is not in place yet; nothing
# else in the graph orders the trail after the policy.
resource "aws_cloudtrail" "sso_audit" {
  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]

  name                          = local.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  is_organization_trail         = var.is_organization_trail
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true
  kms_key_id                    = var.cloudtrail_kms_key_id

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "4.1-configure-cloudtrail-logging"
  }
}
# HTH Guide Excerpt: end terraform

variable "cloudtrail_bucket_name" {
  description = "S3 bucket name for CloudTrail logs"
  type        = string
  default     = "hth-sso-cloudtrail-logs"
}

variable "cloudtrail_kms_key_id" {
  description = "KMS key ARN for CloudTrail log encryption (optional)"
  type        = string
  default     = null
}

variable "is_organization_trail" {
  description = "Enable organization-level trail (requires org management account)"
  type        = bool
  default     = true
}
