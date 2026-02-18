# =============================================================================
# HTH Google Workspace Control 1.1: Enforce Multi-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/6.5, NIST IA-2(1)/IA-2(6), CIS Google Workspace 1.1
# Source: https://howtoharden.com/guides/google-workspace/#11-enforce-multi-factor-authentication-for-all-users
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Retrieve all users to audit 2SV enrollment status.
# The googleworkspace provider does not expose a direct 2SV enforcement toggle;
# enforcement is configured via Admin Console or GAM.  This data source lets
# Terraform surface enrollment gaps so you can detect non-compliant users.

data "googleworkspace_users" "all" {
  filter = "isEnrolledIn2Sv=false"
}

# Create a dedicated OU for users who must complete 2SV enrollment.
# Moving users into this OU lets you apply stricter policies (e.g., security-
# key-only) via Admin Console while tracking the OU in Terraform state.
resource "googleworkspace_org_unit" "mfa_enforcement" {
  name                 = "MFA Enforcement"
  description          = "HTH 1.1 -- Users in this OU are subject to 2SV enforcement policies"
  parent_org_unit_path = var.target_org_unit_path
}

# Create an OU for Super Admins who require security-key-only 2SV (L3).
resource "googleworkspace_org_unit" "super_admin_mfa" {
  count = var.profile_level >= 3 ? 1 : 0

  name                 = "Super Admins - Security Key Only"
  description          = "HTH 1.1 L3 -- Super Admins restricted to hardware security keys"
  parent_org_unit_path = var.target_org_unit_path
}

# Group for tracking users who have NOT enrolled in 2SV.
# Membership is managed outside Terraform (via GAM or Admin SDK scripts) but
# having the group in state ensures it exists and can be referenced by alerts.
resource "googleworkspace_group" "mfa_not_enrolled" {
  email       = "mfa-not-enrolled@${var.primary_domain}"
  name        = "MFA Not Enrolled"
  description = "HTH 1.1 -- Users who have not yet enrolled in 2-Step Verification. Auto-populated by audit scripts."
}
# HTH Guide Excerpt: end terraform
