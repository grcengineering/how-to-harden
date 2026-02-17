# =============================================================================
# HTH Auth0 Control 2.2: Enable Multi-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1) | CIS 6.5
# Source: https://howtoharden.com/guides/auth0/#22-enable-multi-factor-authentication
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "auth0_guardian" "mfa" {
  policy        = "all-applications"
  otp           = true
  recovery_code = true

  webauthn_roaming {
    user_verification = "required"
  }

  webauthn_platform {}
}
# HTH Guide Excerpt: end terraform
