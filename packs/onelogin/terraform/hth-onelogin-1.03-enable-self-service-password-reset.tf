# =============================================================================
# HTH OneLogin Control 1.3: Enable Self-Service Password Reset
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.2, NIST IA-5
# Source: https://howtoharden.com/guides/onelogin/#13-enable-self-service-password-reset
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable self-service password reset with secure recovery methods
resource "onelogin_user_security_policy" "self_service_reset" {
  name = "HTH Self-Service Password Reset"

  # Enable self-service password reset
  allow_password_reset = true

  # Require MFA verification before password reset
  require_mfa_for_password_reset = true

  # Security question configuration
  security_questions_required = 3
}

# L2+ disable less-secure recovery methods
resource "onelogin_user_security_policy" "self_service_reset_hardened" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH Self-Service Password Reset - Hardened"

  allow_password_reset           = true
  require_mfa_for_password_reset = true
  security_questions_required    = 3

  # Disable SMS-based recovery for stronger security
  allow_sms_password_reset = false
}
# HTH Guide Excerpt: end terraform
