# =============================================================================
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-2.3
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#23-restrict-account-instances-of-iam-identity-center
#   profile: L2
#   mode:    mutating
#   requires: AWS credentials in the Organizations management account (organizations:CreatePolicy, organizations:AttachPolicy); SCPs enabled on the root
#
# HTH AWS IAM Identity Center Control 2.3: Restrict Account Instances of IAM Identity Center
# Profile Level: L2 (Walk)
# Frameworks: NIST CM-7, AC-3, CIS Controls 4.1, 6.8
# Source: https://howtoharden.com/guides/aws-iam-identity-center/#23-restrict-account-instances-of-iam-identity-center
#
# The statement is AWS's own "DenyMemberAccountInstances" example from "Use
# Service Control Policies to control account instance creation" (IAM Identity
# Center User Guide). SCPs never restrict the management account itself.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Deny sso:CreateInstance in member accounts; optionally allow-list accounts
# that are permitted to run their own account instance.
data "aws_iam_policy_document" "deny_account_instances" {
  statement {
    sid       = "DenyMemberAccountInstances"
    effect    = "Deny"
    actions   = ["sso:CreateInstance"]
    resources = ["*"]

    dynamic "condition" {
      for_each = length(var.allowed_account_ids) > 0 ? [1] : []
      content {
        test     = "StringNotEquals"
        variable = "aws:PrincipalAccount"
        values   = var.allowed_account_ids
      }
    }
  }
}

resource "aws_organizations_policy" "deny_account_instances" {
  name        = "hth-deny-identity-center-account-instances"
  description = "Deny IAM Identity Center account-instance creation in member accounts (HTH 2.3)"
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_account_instances.json

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "2.3-restrict-account-instances"
  }
}

# Attach to the organization root (r-...) or to each OU / account that must
# never host its own instance -- in most estates, the root.
resource "aws_organizations_policy_attachment" "deny_account_instances" {
  for_each = toset(var.target_ids)

  policy_id = aws_organizations_policy.deny_account_instances.id
  target_id = each.value
}
# HTH Guide Excerpt: end terraform

variable "target_ids" {
  description = "Root, OU, or account IDs to attach the SCP to (e.g. the organization root r-xxxx)"
  type        = list(string)

  validation {
    condition     = length(var.target_ids) > 0
    error_message = "Name at least one attachment target; an unattached SCP restricts nothing."
  }
}

variable "allowed_account_ids" {
  description = "12-digit account IDs still allowed to create an account instance. Empty = deny everywhere."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for id in var.allowed_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "allowed_account_ids must be 12-digit AWS account IDs"
  }
}
