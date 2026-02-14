# =============================================================================
# HTH Okta Control 1.1: Phishing-Resistant MFA (FIDO2/WebAuthn)
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/6.5, NIST IA-2(1)/IA-2(6), DISA STIG V-273190/191/193/194
# Source: https://howtoharden.com/guides/okta/#11-enforce-phishing-resistant-mfa
# =============================================================================

# Enable FIDO2 (WebAuthn) as an authenticator
resource "okta_authenticator" "fido2" {
  name   = "FIDO2 WebAuthn"
  key    = "webauthn"
  status = "ACTIVE"
  settings = jsonencode({
    userVerification = "REQUIRED"
    attachment       = "ANY"
  })
}

# Signon policy requiring phishing-resistant MFA for admins
resource "okta_policy_signon" "phishing_resistant" {
  name        = "Phishing-Resistant MFA Policy"
  status      = "ACTIVE"
  description = "Requires FIDO2 for all admin access"
  priority    = 1

  groups_included = [var.admin_group_id]
}

# Rule enforcing FIDO2 on the phishing-resistant policy
resource "okta_policy_rule_signon" "require_fido2" {
  policy_id          = okta_policy_signon.phishing_resistant.id
  name               = "Require FIDO2"
  status             = "ACTIVE"
  priority           = 1
  access             = "ALLOW"
  mfa_required       = true
  mfa_prompt         = "ALWAYS"
  primary_factor     = "PASSWORD_IDP_ANY_FACTOR"
  session_lifetime   = 120
  session_persistent = false
}
