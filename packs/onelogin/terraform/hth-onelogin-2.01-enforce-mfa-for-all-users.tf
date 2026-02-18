# =============================================================================
# HTH OneLogin Control 2.1: Enforce MFA for All Users
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5, NIST IA-2(1)
# Source: https://howtoharden.com/guides/onelogin/#21-enforce-mfa-for-all-users
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Authentication factor: OneLogin Protect (push notification)
resource "onelogin_auth_factor" "onelogin_protect" {
  name        = "OneLogin Protect"
  factor_type = "OneLogin Protect"
  enabled     = true
}

# Authentication factor: Google Authenticator (TOTP)
resource "onelogin_auth_factor" "google_authenticator" {
  name        = "Google Authenticator"
  factor_type = "Google Authenticator"
  enabled     = true
}

# Authentication factor: WebAuthn / FIDO2 (phishing-resistant)
resource "onelogin_auth_factor" "webauthn" {
  name        = "WebAuthn"
  factor_type = "WebAuthn"
  enabled     = true
}

# User policy requiring OTP at every login
resource "onelogin_user_security_policy" "mfa_required" {
  name = var.mfa_policy_name

  # Require MFA at login
  otp_auth_required = true

  # L1: Allow device trust for 30 days
  # L3: Never trust devices -- require MFA every login
  mfa_device_trust_duration_days = var.profile_level >= 3 ? 0 : 30
}
# HTH Guide Excerpt: end terraform
