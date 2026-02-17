# =============================================================================
# HTH AWS IAM Identity Center Control 1.3: Configure Attribute-Based Access Control
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-3, SOC 2 CC6.1, ISO 27001 A.9.4.1
# Source: https://howtoharden.com/guides/aws-iam-identity-center/#13-configure-attribute-based-access-control
# =============================================================================

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

# HTH Guide Excerpt: begin terraform
# Enable ABAC attributes for Identity Center
# Maps identity provider attributes to session tags for fine-grained access control
resource "aws_ssoadmin_instance_access_control_attributes" "abac" {
  instance_arn = local.sso_instance_arn

  attribute {
    key = "Department"
    value {
      source = ["${path.root}/Department"]
    }
  }

  attribute {
    key = "CostCenter"
    value {
      source = ["${path.root}/CostCenter"]
    }
  }

  attribute {
    key = "Project"
    value {
      source = ["${path.root}/Project"]
    }
  }
}

# Example permission set using ABAC for department-scoped access
resource "aws_ssoadmin_permission_set" "department_scoped" {
  instance_arn     = local.sso_instance_arn
  name             = "DepartmentScopedAccess"
  description      = "ABAC-enabled permission set scoped by department tag"
  session_duration = "PT4H"

  tags = {
    ManagedBy = "how-to-harden"
    Control   = "1.3-configure-abac"
  }
}

# Inline policy enforcing ABAC tag matching
resource "aws_ssoadmin_permission_set_inline_policy" "department_abac_policy" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department_scoped.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowDepartmentScopedAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:ExistingObjectTag/Department" = "$${aws:PrincipalTag/Department}"
          }
        }
      }
    ]
  })
}
# HTH Guide Excerpt: end terraform
