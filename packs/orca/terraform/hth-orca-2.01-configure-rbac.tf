# =============================================================================
# HTH Orca Control 2.1: Configure Role-Based Access Control
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/orca/#21-configure-role-based-access-control
#
# Creates custom roles enforcing least privilege: a read-only Security Analyst
# role and a minimal Viewer role. Assign users to these instead of built-in
# Admin to reduce blast radius.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Read-only Security Analyst role -- least privilege for daily operations
resource "orcasecurity_custom_role" "security_analyst" {
  name        = var.readonly_role_name
  description = "Read-only role for security analysts. Permits viewing assets, alerts, dashboards, and compliance reports without modification rights. Per HTH Orca Guide 2.1."

  permission_groups = var.readonly_permissions
}

# Minimal Viewer role -- dashboard and asset visibility only
resource "orcasecurity_custom_role" "viewer" {
  name        = var.viewer_role_name
  description = "Minimal viewer role for stakeholders who need visibility into cloud security posture without operational access. Per HTH Orca Guide 2.1."

  permission_groups = var.viewer_permissions
}

# Alert when users have overly broad permissions
resource "orcasecurity_custom_sonar_alert" "excessive_permissions" {
  name          = "Cloud Identity with Excessive Permissions"
  description   = "Detects cloud identities with overly broad permissions that violate least privilege principles."
  rule          = "User with Permission = '*' or Permission = 'Admin'"
  orca_score    = 7.5
  category      = "IAM misconfigurations"
  context_score = true

  remediation_text = {
    enable = true
    text   = "Review and reduce permissions to the minimum required for the user's role. Use the Security Analyst or Viewer custom roles instead of Admin. See HTH Orca Guide section 2.1."
  }

  compliance_frameworks = [
    { name = "HTH Orca Hardening", section = "2.1 Configure RBAC", priority = "high" }
  ]
}
# HTH Guide Excerpt: end terraform
