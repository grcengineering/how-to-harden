#!/usr/bin/env bash
# HTH GitHub Control 5.06: Configure OIDC for Credential-Free Deployments
# Profile: L2 | NIST: IA-2, IA-5(2)
# https://howtoharden.com/guides/github/#52-use-oidc-instead-of-long-lived-credentials
source "$(dirname "$0")/common.sh"

banner "5.06: Configure OIDC"
should_apply 2 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin api-configure-oidc-trust-policy
# AWS IAM OIDC Trust Policy
# Create this as the trust policy for your deployment role
cat <<'POLICY'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:your-org/your-repo:ref:refs/heads/main"
        }
      }
    }
  ]
}
POLICY
# HTH Guide Excerpt: end api-configure-oidc-trust-policy
