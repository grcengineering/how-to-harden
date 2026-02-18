# =============================================================================
# HTH JFrog Control 1.1: Enforce SSO with MFA
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1)
# Source: https://howtoharden.com/guides/jfrog/#11-enforce-sso-with-mfa
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Configure SAML SSO for centralized authentication with MFA enforcement
resource "artifactory_saml_settings" "sso" {
  enable                       = true
  login_url                    = var.saml_idp_url
  certificate                  = var.saml_idp_certificate
  service_provider_name        = var.saml_service_provider_id
  allow_user_to_access_profile = false
  auto_redirect                = true
  no_auto_user_creation        = false
  use_encrypted_assertion      = true
}

# Disable anonymous access to force authenticated sessions
resource "artifactory_general_security" "disable_anonymous" {
  enable_anonymous_access = false
}

# HTH Guide Excerpt: end terraform
