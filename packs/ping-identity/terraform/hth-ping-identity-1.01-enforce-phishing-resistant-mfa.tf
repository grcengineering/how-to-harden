# =============================================================================
# HTH Ping Identity Control 1.1: Phishing-Resistant MFA (FIDO2/WebAuthn)
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/6.5, NIST IA-2(1)/IA-2(6), PCI DSS 8.3.1
# Source: https://howtoharden.com/guides/ping-identity/#11-enforce-phishing-resistant-mfa
# =============================================================================

# HTH Guide Excerpt: begin terraform
# MFA device policy requiring FIDO2 for admin authentication
resource "pingone_mfa_device_policy" "phishing_resistant" {
  environment_id = var.pingone_environment_id
  name           = "HTH Phishing-Resistant MFA"

  authentication = {
    device_selection = "DEFAULT_TO_FIRST"
  }

  fido2 = {
    enabled = true
  }

  mobile = {
    enabled = false
  }

  totp = {
    enabled = false
  }

  sms = {
    enabled = false
  }

  voice = {
    enabled = false
  }

  email = {
    enabled = false
  }
}

# FIDO2 policy with platform and cross-platform authenticators
resource "pingone_mfa_fido2_policy" "webauthn" {
  environment_id = var.pingone_environment_id
  name           = "HTH FIDO2 WebAuthn Policy"

  attestation_requirements      = "DIRECT"
  authenticator_attachment       = "BOTH"
  backup_eligibility             = { allow = true, enforce_during_authentication = false }
  device_display_name            = "FIDO2 Security Key"
  discoverable_credentials       = "PREFERRED"
  mds_authenticators_requirements = { enforce_during_authentication = true, option = "SPECIFIC" }
  relying_party_id               = ""
  user_display_name_attributes   = { attributes = [{ name = "username" }] }
  user_verification              = { enforce_during_authentication = true, option = "REQUIRED" }
}

# Sign-on policy enforcing FIDO2 for administrators
resource "pingone_sign_on_policy" "phishing_resistant_admin" {
  environment_id = var.pingone_environment_id
  name           = "HTH Phishing-Resistant Admin Sign-On"
  description    = "Requires FIDO2 MFA for all administrator access"
}

# Sign-on policy action: require MFA with FIDO2
resource "pingone_sign_on_policy_action" "admin_mfa" {
  environment_id    = var.pingone_environment_id
  sign_on_policy_id = pingone_sign_on_policy.phishing_resistant_admin.id
  priority          = 1

  mfa {
    device_sign_on_policy_id = pingone_mfa_device_policy.phishing_resistant.id
    no_device_mode           = "BLOCK"
  }

  conditions {
    user_attribute_equals {
      attribute_reference = "$${user.memberOfGroups[?(id == '${var.admin_group_id}')]}"
      value_boolean       = true
    }
  }
}

# L2+: Reduce admin session duration to 2 hours
resource "pingone_sign_on_policy_action" "admin_session_limit" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id    = var.pingone_environment_id
  sign_on_policy_id = pingone_sign_on_policy.phishing_resistant_admin.id
  priority          = 2

  login {
    recovery_enabled = false
  }
}
# HTH Guide Excerpt: end terraform
