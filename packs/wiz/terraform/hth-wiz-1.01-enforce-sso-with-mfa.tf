# =============================================================================
# HTH Wiz Control 1.1: Enforce SSO with MFA
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1)
# Source: https://howtoharden.com/guides/wiz/#11-enforce-sso-with-mfa
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure SAML SSO identity provider for Wiz console access
resource "wiz_saml_idp" "corporate_sso" {
  count = var.saml_login_url != "" ? 1 : 0

  name                       = var.saml_idp_name
  login_url                  = var.saml_login_url
  certificate                = var.saml_certificate
  issuer_url                 = var.saml_issuer_url != "" ? var.saml_issuer_url : var.saml_login_url
  logout_url                 = var.saml_logout_url != "" ? var.saml_logout_url : null
  use_provider_managed_roles = false
  allow_manual_role_override = false
}
# HTH Guide Excerpt: end terraform
