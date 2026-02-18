# =============================================================================
# HTH Orca Control 2.3: Limit Admin Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/orca/#23-limit-admin-access
#
# Creates a dedicated admin group with explicit membership. Keep this group
# to 2-3 users maximum. All admin actions are auditable through this group.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Dedicated admin group -- limit membership to 2-3 trusted users
resource "orcasecurity_group" "platform_admins" {
  name        = var.admin_group_name
  description = "Restricted admin group. Membership should be limited to 2-3 users maximum. All members require MFA via SSO. Per HTH Orca Guide 2.3."
  sso_group   = true
  users       = var.admin_user_ids
}

# Alert when admin count exceeds recommended limit
resource "orcasecurity_custom_sonar_alert" "excessive_admins" {
  name          = "Excessive Admin Accounts Detected"
  description   = "Monitors for an excessive number of admin-level accounts in the Orca platform, which increases attack surface."
  rule          = "User with Role = 'Admin'"
  orca_score    = 7.0
  category      = "Access control"
  context_score = false

  remediation_text = {
    enable = true
    text   = "Reduce admin accounts to 2-3 users maximum. Assign the Security Analyst or Viewer custom role to users who do not require admin privileges. See HTH Orca Guide section 2.3."
  }

  compliance_frameworks = [
    { name = "HTH Orca Hardening", section = "2.3 Limit Admin Access", priority = "high" }
  ]
}
# HTH Guide Excerpt: end terraform
