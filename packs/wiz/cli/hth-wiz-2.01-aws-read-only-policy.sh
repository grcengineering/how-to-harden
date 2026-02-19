#!/usr/bin/env bash
# HTH Wiz Control 2.1: Secure Cloud Connector Configuration
# Profile: L1 | NIST: IA-5, AC-6
# https://howtoharden.com/guides/wiz/#21-secure-cloud-connector-configuration

# HTH Guide Excerpt: begin cli-aws-read-only-policy
# AWS IAM policy for Wiz connector (read-only)
cat <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "s3:GetBucketLocation",
        "s3:GetBucketPolicy",
        "s3:ListAllMyBuckets",
        "iam:GetAccountSummary",
        "iam:ListRoles"
      ],
      "Resource": "*"
    }
  ]
}
JSON
# HTH Guide Excerpt: end cli-aws-read-only-policy

# HTH Guide Excerpt: begin cli-aws-external-id-trust
# AWS trust policy with External ID for Wiz role assumption
cat <<'JSON'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::WIZ_ACCOUNT_ID:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "YOUR_UNIQUE_EXTERNAL_ID"
        }
      }
    }
  ]
}
JSON
# HTH Guide Excerpt: end cli-aws-external-id-trust
