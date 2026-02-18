# =============================================================================
# HTH OneLogin Control 1.1: Configure Password Policy
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.2, NIST IA-5
# Source: https://howtoharden.com/guides/onelogin/#11-configure-password-policy
# =============================================================================

# HTH Guide Excerpt: begin terraform
# User policy enforcing password strength, history, and lockout settings
resource "onelogin_user_security_policy" "password_policy" {
  name = "HTH Password Policy"

  # Password complexity requirements
  password_length_min       = var.password_min_length
  password_requires_upper   = true
  password_requires_lower   = true
  password_requires_number  = true
  password_requires_symbol  = true
  password_history_size     = var.password_history_count
  password_expiry_days      = var.password_expiry_days

  # Lockout settings
  lock_account_on_consecutive_fails = var.password_max_failed_attempts
  lockout_duration_minutes          = var.password_lockout_duration_minutes
}

# L2+ stricter password policy with longer minimum length
resource "onelogin_user_security_policy" "password_policy_hardened" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH Password Policy - Hardened"

  password_length_min       = max(var.password_min_length, 14)
  password_requires_upper   = true
  password_requires_lower   = true
  password_requires_number  = true
  password_requires_symbol  = true
  password_history_size     = var.password_history_count
  password_expiry_days      = 60

  lock_account_on_consecutive_fails = 3
  lockout_duration_minutes          = 60
}
# HTH Guide Excerpt: end terraform
