# =============================================================================
# HTH Zscaler Control 1.2: Implement Role-Based Admin Access
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-6(1) | CIS 5.4
# Source: https://howtoharden.com/guides/zscaler/#12-implement-role-based-admin-access
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Note: ZIA admin role management is performed through the ZIA Admin Portal
# (Administration > Administrator Management > Role Management).
# The ZIA Terraform provider supports reading admin roles as data sources.
#
# ZPA admin roles can be referenced and used in access policy configuration.

data "zia_admin_roles" "security_admin" {
  name = "Security Admin"
}

data "zia_admin_roles" "auditor" {
  name = "Auditor"
}

# HTH Guide Excerpt: end terraform
