# =============================================================================
# HTH SendGrid Control 1.2: Configure SAML Single Sign-On
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.3, 12.5, NIST IA-2, IA-8
# Source: https://howtoharden.com/guides/sendgrid/#12-configure-saml-single-sign-on
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "sendgrid_sso_integration" "corporate" {
  count = var.profile_level >= 2 && var.sso_signin_url != "" ? 1 : 0

  name        = var.sso_name
  enabled     = true
  signin_url  = var.sso_signin_url
  signout_url = var.sso_signout_url
  entity_id   = var.sso_entity_id
}

resource "sendgrid_sso_certificate" "corporate" {
  count = var.profile_level >= 2 && var.sso_certificate != "" ? 1 : 0

  integration_id     = sendgrid_sso_integration.corporate[0].id
  public_certificate = var.sso_certificate
}
# HTH Guide Excerpt: end terraform
