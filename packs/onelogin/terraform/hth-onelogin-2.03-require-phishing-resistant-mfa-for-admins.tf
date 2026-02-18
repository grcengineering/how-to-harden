# =============================================================================
# HTH OneLogin Control 2.3: Require Phishing-Resistant MFA for Admins
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.5, NIST IA-2(6)
# Source: https://howtoharden.com/guides/onelogin/#23-require-phishing-resistant-mfa-for-admins
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Admin-only policy requiring WebAuthn/FIDO2 for phishing resistance
# Only deployed at L2+ where admin accounts need strongest protection
resource "onelogin_user_security_policy" "admin_webauthn" {
  count = var.profile_level >= 2 ? 1 : 0

  name = var.admin_mfa_policy_name

  # Require MFA at every login -- no device trust for admins
  otp_auth_required              = true
  mfa_device_trust_duration_days = 0

  # Restrict to WebAuthn/FIDO2 only -- disable weaker factors
  allowed_auth_factor_types = ["WebAuthn"]
}

# Assign admin policy to each admin user
resource "onelogin_user_policy_assignment" "admin_webauthn" {
  count = var.profile_level >= 2 ? length(var.admin_user_ids) : 0

  user_id   = var.admin_user_ids[count.index]
  policy_id = onelogin_user_security_policy.admin_webauthn[0].id
}
# HTH Guide Excerpt: end terraform
