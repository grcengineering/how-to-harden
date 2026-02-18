# =============================================================================
# HTH OneLogin Control 3.1: Implement Delegated Administration
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/onelogin/#31-implement-delegated-administration
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Custom role: Tier 1 Help Desk (password reset and account unlock only)
resource "onelogin_role" "tier1_helpdesk" {
  count = var.create_custom_roles ? 1 : 0

  name = "HTH Tier 1 Help Desk"
}

# Custom role: Application Administrator (app management, no user admin)
resource "onelogin_role" "app_admin" {
  count = var.create_custom_roles ? 1 : 0

  name = "HTH Application Administrator"
}

# Custom role: Security Auditor (read-only access for compliance review)
resource "onelogin_role" "security_auditor" {
  count = var.create_custom_roles ? 1 : 0

  name = "HTH Security Auditor"
}

# L2+ Custom role: Privileged Admin with stricter separation of duties
resource "onelogin_role" "privileged_admin" {
  count = var.profile_level >= 2 && var.create_custom_roles ? 1 : 0

  name = "HTH Privileged Administrator"
}
# HTH Guide Excerpt: end terraform
