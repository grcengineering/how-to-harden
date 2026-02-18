# =============================================================================
# HTH Microsoft Entra ID Control 1.1: Enforce Phishing-Resistant MFA
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/6.5, NIST IA-2(1)/IA-2(6), CIS Azure 1.1.1
# Source: https://howtoharden.com/guides/microsoft-entra-id/#11-enforce-phishing-resistant-mfa
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure authentication methods policy with phishing-resistant MFA
resource "azuread_authentication_methods_policy" "main" {
  display_name = "Default Authentication Methods Policy"

  # Enable FIDO2 security keys for all users
  fido2 {
    state              = "enabled"
    allowed_aaguids    = var.fido2_allowed_aaguids
    self_service_registration_enabled = true
    key_restrictions {
      enforcement_type = length(var.fido2_allowed_aaguids) > 0 ? "allow" : "block"
      aaguids          = var.fido2_allowed_aaguids
    }
  }

  # Enable Microsoft Authenticator with number matching and app context
  microsoft_authenticator {
    state = "enabled"
    feature_settings {
      display_app_information_required_state {
        state = "enabled"
      }
      number_matching_required_state {
        state = "enabled"
      }
      display_location_information_required_state {
        state = "enabled"
      }
    }
  }

  # Disable SMS authentication (vulnerable to SIM swapping)
  sms {
    state = var.disable_sms_authentication ? "disabled" : "enabled"
  }
}

# Authentication strength policy for phishing-resistant methods
resource "azuread_authentication_strength_policy" "phishing_resistant" {
  display_name = "HTH Phishing-Resistant MFA"
  description  = "Requires FIDO2, Windows Hello, or certificate-based authentication"

  allowed_combinations = [
    "fido2",
    "windowsHelloForBusiness",
    "x509CertificateMultiFactor",
  ]
}
# HTH Guide Excerpt: end terraform
