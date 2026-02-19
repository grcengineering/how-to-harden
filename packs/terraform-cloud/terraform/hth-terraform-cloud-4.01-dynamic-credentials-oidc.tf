# =============================================================================
# HTH Terraform Cloud Control 4.01: Dynamic Credentials (OIDC)
# Profile Level: L2 (Hardened)
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/terraform-cloud/#41-dynamic-credentials-oidc
# =============================================================================

# HTH Guide Excerpt: begin oidc-aws-config
# Configure OIDC provider in AWS
resource "aws_iam_openid_connect_provider" "tfc" {
  url             = "https://app.terraform.io"
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
}

# Trust policy for TFC
data "aws_iam_policy_document" "tfc_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.tfc.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "app.terraform.io:aud"
      values   = ["aws.workload.identity"]
    }
    condition {
      test     = "StringLike"
      variable = "app.terraform.io:sub"
      values   = ["organization:myorg:project:*:workspace:*:run_phase:*"]
    }
  }
}

# workspace variables
# TFC_AWS_PROVIDER_AUTH = true
# TFC_AWS_RUN_ROLE_ARN  = arn:aws:iam::123456789:role/tfc-role
# HTH Guide Excerpt: end oidc-aws-config
