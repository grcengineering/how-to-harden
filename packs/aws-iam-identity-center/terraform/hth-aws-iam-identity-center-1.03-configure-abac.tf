# =============================================================================
# HTH Pack Contract: v1
#   control: aws-iam-identity-center-1.3
#   guide:   https://howtoharden.com/guides/aws-iam-identity-center/#13-configure-attribute-based-access-control
#   profile: L2
#   mode:    mutating
#   requires: AWS credentials in the IAM Identity Center management account (sso:CreateInstanceAccessControlAttributeConfiguration, sso:CreatePermissionSet, sso:PutInlinePolicyToPermissionSet)
#
# HTH AWS IAM Identity Center Control 1.3: Configure Attribute-Based Access Control
# Profile Level: L2 (Walk)
# Frameworks: NIST AC-3, SOC 2 CC6.1, ISO 27001 A.9.4.1
# Source: https://howtoharden.com/guides/aws-iam-identity-center/#13-configure-attribute-based-access-control
#
# TWO THINGS TO GET RIGHT:
#   1. Attribute sources use AWS's ${path:...} syntax, which collides with
#      Terraform interpolation. Escape it as $${path:...}. Written unescaped as
#      "${path.root}/Department", Terraform sends the module path "./Department"
#      to AWS instead of an attribute reference.
#   2. S3 tag condition keys are per-action: only s3:GetObject supports
#      s3:ExistingObjectTag, s3:PutObject takes s3:RequestObjectTag, and
#      s3:ListBucket takes s3:BucketTag (Service Authorization Reference).
#      One statement conditioning all three on ExistingObjectTag grants reads only.
# =============================================================================

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

# HTH Guide Excerpt: begin terraform
# Enable ABAC attributes for Identity Center.
# Map Identity Center directory attributes to session tags. Sources use AWS's
# ${path:...} syntax, escaped as $${...} so Terraform passes it through literally.
# AWS exposes enterprise.{department,costCenter,division,organization,...} but no
# "project" attribute -- pass project or environment tags in the SAML assertion
# (https://aws.amazon.com/SAML/Attributes/AccessControl:<Key>) instead.
resource "aws_ssoadmin_instance_access_control_attributes" "abac" {
  instance_arn = local.sso_instance_arn

  attribute {
    key = "Department"
    value {
      source = ["$${path:enterprise.department}"]
    }
  }

  attribute {
    key = "CostCenter"
    value {
      source = ["$${path:enterprise.costCenter}"]
    }
  }

  attribute {
    key = "Division"
    value {
      source = ["$${path:enterprise.division}"]
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

# Inline policy enforcing ABAC tag matching. Each S3 action uses the tag
# condition key that action actually supports.
resource "aws_ssoadmin_permission_set_inline_policy" "department_abac_policy" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.department_scoped.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadObjectsTaggedForMyDepartment"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:ExistingObjectTag/Department" = "$${aws:PrincipalTag/Department}"
          }
        }
      },
      {
        Sid      = "WriteObjectsTaggedForMyDepartment"
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:RequestObjectTag/Department" = "$${aws:PrincipalTag/Department}"
          }
        }
      },
      {
        Sid      = "ListBucketsTaggedForMyDepartment"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:BucketTag/Department" = "$${aws:PrincipalTag/Department}"
          }
        }
      }
    ]
  })
}
# HTH Guide Excerpt: end terraform
