# =============================================================================
# HTH OneLogin Control 3.3: Protect Privileged Accounts
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/onelogin/#33-protect-privileged-accounts
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Dedicated admin security policy with enhanced protections
resource "onelogin_user_security_policy" "admin_protection" {
  name = "HTH Admin Account Protection"

  # Shorter session timeout for admin accounts
  session_timeout    = 120
  inactivity_timeout = 10

  # Always require MFA -- no device trust for admins
  otp_auth_required              = true
  mfa_device_trust_duration_days = 0

  # Stricter lockout for admin accounts
  lock_account_on_consecutive_fails = 3
  lockout_duration_minutes          = 60
}

# L2+ even stricter admin protections
resource "onelogin_user_security_policy" "admin_protection_hardened" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH Admin Account Protection - Hardened"

  session_timeout    = 60
  inactivity_timeout = 5

  otp_auth_required              = true
  mfa_device_trust_duration_days = 0

  lock_account_on_consecutive_fails = 3
  lockout_duration_minutes          = 120

  # Require IP restriction for admin access
  ip_address_restriction = var.allowed_ip_addresses != "" ? true : false
  allowed_ip_addresses   = var.allowed_ip_addresses
}
# HTH Guide Excerpt: end terraform
