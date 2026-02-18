# =============================================================================
# HTH Splunk Control 1.2: Configure Local Admin Fallback
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/splunk/#12-configure-local-admin-fallback
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Maintain a local admin account for emergency recovery when SAML is down.
# This account should use a strong password (20+ chars) stored in a vault.
# Local login URL: https://<instance>/en-US/account/login?loginType=splunk

resource "splunk_authentication_users" "emergency_admin" {
  count = var.local_admin_password != "" ? 1 : 0

  name              = var.local_admin_username
  password          = var.local_admin_password
  force_change_pass = false
  roles             = ["admin"]
  email             = "security-team@example.com"
  realname          = "HTH Emergency Admin"
}
# HTH Guide Excerpt: end terraform
