# =============================================================================
# HTH OneLogin Control 4.2: Configure Brute Force Protection
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3, NIST AC-7
# Source: https://howtoharden.com/guides/onelogin/#42-configure-brute-force-protection
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Account lockout policy to prevent brute force attacks
resource "onelogin_user_security_policy" "brute_force_protection" {
  name = "HTH Brute Force Protection"

  # Lock account after consecutive failed attempts
  lock_account_on_consecutive_fails = var.password_max_failed_attempts
  lockout_duration_minutes          = var.password_lockout_duration_minutes
}

# L2+ stricter brute force protection: fewer attempts, longer lockout
resource "onelogin_user_security_policy" "brute_force_hardened" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH Brute Force Protection - Hardened"

  lock_account_on_consecutive_fails = 3
  lockout_duration_minutes          = 60
}

# L3: most aggressive lockout settings
resource "onelogin_user_security_policy" "brute_force_max" {
  count = var.profile_level >= 3 ? 1 : 0

  name = "HTH Brute Force Protection - Maximum Security"

  lock_account_on_consecutive_fails = 3
  lockout_duration_minutes          = 120
}
# HTH Guide Excerpt: end terraform
