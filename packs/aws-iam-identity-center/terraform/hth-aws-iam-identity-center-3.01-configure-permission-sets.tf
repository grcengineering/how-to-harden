# =============================================================================
# HTH AWS IAM Identity Center Control 3.1: Configure Permission Sets
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-6, SOC 2 CC6.3, ISO 27001 A.9.2.3
# Source: https://howtoharden.com/guides/aws-iam-identity-center/#31-configure-permission-sets
# =============================================================================

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

# HTH Guide Excerpt: begin terraform
# Read-only permission set for auditors and compliance teams
resource "aws_ssoadmin_permission_set" "read_only" {
  instance_arn     = local.sso_instance_arn
  name             = "HTH-ReadOnlyAccess"
  description      = "Read-only access for auditors -- 1-hour session limit"
  session_duration = "PT1H"

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "3.1-configure-permission-sets"
    Profile   = "L1"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only_policy" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Developer permission set with scoped access
resource "aws_ssoadmin_permission_set" "developer" {
  instance_arn     = local.sso_instance_arn
  name             = "HTH-DeveloperAccess"
  description      = "Scoped developer access -- no IAM or Organizations changes"
  session_duration = "PT4H"

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "3.1-configure-permission-sets"
    Profile   = "L1"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "developer_poweruser" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.developer.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# Admin permission set with short session and boundary
resource "aws_ssoadmin_permission_set" "admin" {
  instance_arn     = local.sso_instance_arn
  name             = "HTH-AdminAccess"
  description      = "Full admin access -- 1-hour session, restricted to break-glass"
  session_duration = "PT1H"

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "3.1-configure-permission-sets"
    Profile   = "L1"
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "admin_policy" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Deny inline policy to restrict admin from modifying CloudTrail or GuardDuty
resource "aws_ssoadmin_permission_set_inline_policy" "admin_guardrails" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenySecurityServiceModification"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "guardduty:DeleteDetector",
          "guardduty:DisassociateFromMasterAccount",
          "access-analyzer:DeleteAnalyzer"
        ]
        Resource = "*"
      }
    ]
  })
}
# HTH Guide Excerpt: end terraform
