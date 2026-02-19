#!/usr/bin/env bash
# HTH CircleCI Control 2.03: OIDC Token Authentication — AWS IAM Trust Policy
# Profile: L2 | NIST: IA-5
# https://howtoharden.com/guides/circleci/#23-oidc-token-authentication
#
# Deploy: Create this as the IAM trust policy for the CircleCI OIDC role

# HTH Guide Excerpt: begin api-oidc-iam-trust-policy
# AWS IAM Trust Policy for CircleCI OIDC
cat <<'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789:oidc-provider/oidc.circleci.com/org/ORG_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.circleci.com/org/ORG_ID:aud": "ORG_ID"
        },
        "StringLike": {
          "oidc.circleci.com/org/ORG_ID:sub": "org/ORG_ID/project/*/user/*"
        }
      }
    }
  ]
}
POLICY
# HTH Guide Excerpt: end api-oidc-iam-trust-policy
