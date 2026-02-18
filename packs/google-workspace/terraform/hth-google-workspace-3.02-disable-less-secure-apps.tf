# =============================================================================
# HTH Google Workspace Control 3.2: Disable Less Secure Apps
# Profile Level: L1 (Baseline)
# Frameworks: CIS 4.2, NIST IA-2
# Source: https://howtoharden.com/guides/google-workspace/#32-disable-less-secure-apps
# =============================================================================

# HTH Guide Excerpt: begin terraform
# "Less Secure Apps" allow authentication with username/password only,
# completely bypassing 2-Step Verification.  Google has deprecated this
# feature but some legacy tenants may still have it enabled.
#
# The googleworkspace provider does not expose a direct toggle for the
# organization-wide "Less Secure Apps" setting.  This control creates
# the organizational structure to enforce the policy:
#
# 1. An OU for legacy app users who temporarily need access (with
#    an expiration plan)
# 2. A tracking group for audit and remediation
#
# Enforcement is done via:
#   Admin Console > Security > Less secure apps > Disable access (Recommended)
#
# Or via GAM:
#   gam ou / update less_secure_apps DISABLED

# Tracking group for applications still requiring less-secure-app access.
# This group should be empty -- any members represent technical debt.
resource "googleworkspace_group" "legacy_app_tracking" {
  email       = "legacy-app-tracking@${var.primary_domain}"
  name        = "Legacy App Tracking"
  description = "HTH 3.2 -- Tracks applications requiring less-secure-app access. Target: zero members."
}

# Temporary OU for users who need transitional legacy app access.
# Should be emptied and removed within 90 days.
resource "googleworkspace_org_unit" "legacy_app_exception" {
  count = var.profile_level >= 1 ? 1 : 0

  name                 = "Legacy App Exceptions"
  description          = "HTH 3.2 -- Temporary OU for users needing legacy app access. Must be emptied within 90 days."
  parent_org_unit_path = var.target_org_unit_path
}
# HTH Guide Excerpt: end terraform
