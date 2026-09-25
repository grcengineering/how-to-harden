# =============================================================================
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-3.3
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#33-protect-privileged-access
#   profile: L2
#   mode:    mutating
#   requires: AWS credentials in the IAM Identity Center management account (sso:CreatePermissionSet, sso:AttachManagedPolicyToPermissionSet, sso:CreateAccountAssignment)
#
# HTH AWS IAM Identity Center Control 3.3: Protect Privileged Access
# Profile Level: L2 (Walk)
# Frameworks: NIST AC-6(1), CIS Controls 5.4
# Source: https://howtoharden.com/guides/aws-iam-identity-center/#33-protect-privileged-access
#
# A dedicated admin permission set, separate from day-to-day access, held at a
# 1-hour session (the minimum AWS allows; the range is 1-12 hours) and assigned
# to a GROUP only -- never to individual users. Permission sets carry no MFA
# setting of their own: MFA comes from the instance-wide setting in control 1.1
# (or from the external IdP, control 2.1).
# =============================================================================

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

# HTH Guide Excerpt: begin terraform
resource "aws_ssoadmin_permission_set" "privileged_admin" {
  instance_arn     = local.sso_instance_arn
  name             = "HTH-PrivilegedAdmin"
  description      = "Separate admin access -- 1-hour sessions, group-assigned only"
  session_duration = "PT1H"

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "3.3-protect-privileged-access"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "privileged_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.privileged_admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Assign the admin set to one admin GROUP, only in the accounts that need it.
resource "aws_ssoadmin_account_assignment" "privileged_admin_group" {
  for_each = toset(var.admin_account_ids)

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.privileged_admin.arn
  principal_type     = "GROUP"
  principal_id       = var.admin_group_id
  target_type        = "AWS_ACCOUNT"
  target_id          = each.value

  # Provision the set only after its policy is attached.
  depends_on = [aws_ssoadmin_managed_policy_attachment.privileged_admin]
}
# HTH Guide Excerpt: end terraform

variable "admin_group_id" {
  description = "Identity Store group ID of the privileged-admin group (a group, never a user)"
  type        = string
}

variable "admin_account_ids" {
  description = "12-digit AWS account IDs where the admin group needs the privileged set"
  type        = list(string)

  validation {
    condition     = alltrue([for id in var.admin_account_ids : can(regex("^[0-9]{12}$", id))])
    error_message = "admin_account_ids must be 12-digit AWS account IDs"
  }
}
