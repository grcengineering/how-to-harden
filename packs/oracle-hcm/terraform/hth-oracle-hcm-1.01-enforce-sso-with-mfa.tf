# =============================================================================
# HTH Oracle HCM Control 1.1: Enforce SSO with MFA
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1)
# Source: https://howtoharden.com/guides/oracle-hcm/#11-enforce-sso-with-mfa
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Identity Domain MFA sign-on policy requiring multi-factor authentication
resource "oci_identity_domains_authentication_factor_setting" "mfa_enforcement" {
  idcs_endpoint = var.idcs_domain_url

  authentication_factor_setting_id = "AuthenticationFactorSettings"
  schemas                          = ["urn:ietf:params:scim:schemas:oracle:idcs:AuthenticationFactorSettings"]

  # Enable TOTP (authenticator app)
  totp_enabled = contains(var.mfa_enabled_factors, "TOTP")

  # Enable push notifications
  push_enabled = contains(var.mfa_enabled_factors, "PUSH")

  # Enable FIDO2/WebAuthn
  fido_authenticator_enabled = contains(var.mfa_enabled_factors, "FIDO2")

  # Enable email factor
  email_enabled = contains(var.mfa_enabled_factors, "EMAIL")

  # Bypass settings — no bypass codes at L2+
  bypass_code_enabled = var.profile_level >= 2 ? false : true

  # MFA enrollment — require enrollment for all users
  mfa_enrollment_type = "Required"

  # FIDO2 settings for phishing-resistant auth
  dynamic "fido2_settings" {
    for_each = contains(var.mfa_enabled_factors, "FIDO2") ? [1] : []
    content {
      attestation                    = "DIRECT"
      authenticator_selection_attachment = "PLATFORM"
      domain_validation_level        = 1
      exclude_credentials            = true
      public_key_types               = ["RS256", "ES256"]
      resident_key_requirement       = var.profile_level >= 3 ? "REQUIRED" : "PREFERRED"
      timeout                        = 60000
      user_verification_requirement  = "REQUIRED"
    }
  }
}

# Sign-on policy enforcing MFA for all HCM access
resource "oci_identity_domains_policy" "hcm_sso_mfa_policy" {
  idcs_endpoint = var.idcs_domain_url

  schemas     = ["urn:ietf:params:scim:schemas:oracle:idcs:Policy"]
  name        = "HTH-HCM-SSO-MFA-Policy"
  description = "Enforce SSO with MFA for all Oracle HCM Cloud access"
  active      = true
  policy_type {
    value = "SignOn"
  }

  rules {
    name      = "RequireMFA"
    sequence  = 1
    return {
      name  = "mfaRequired"
      value = "true"
    }
    return {
      name  = "allowAccess"
      value = "true"
    }
  }
}

# L3: Enforce FIDO2-only authentication (phishing-resistant)
resource "oci_identity_domains_policy" "fido2_only_policy" {
  count = var.profile_level >= 3 ? 1 : 0

  idcs_endpoint = var.idcs_domain_url

  schemas     = ["urn:ietf:params:scim:schemas:oracle:idcs:Policy"]
  name        = "HTH-HCM-FIDO2-Only-Policy"
  description = "Require FIDO2 phishing-resistant authentication for HCM (L3)"
  active      = true
  policy_type {
    value = "SignOn"
  }

  rules {
    name      = "RequireFIDO2"
    sequence  = 1
    return {
      name  = "mfaRequired"
      value = "true"
    }
    return {
      name  = "allowedFactors"
      value = "FIDO2"
    }
    return {
      name  = "allowAccess"
      value = "true"
    }
  }
}
# HTH Guide Excerpt: end terraform
