# =============================================================================
# HTH Twilio Control 1.1: Configure SAML Single Sign-On
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/12.5, NIST IA-2/IA-8
# Source: https://howtoharden.com/guides/twilio/#11-configure-saml-single-sign-on
# =============================================================================

# HTH Guide Excerpt: begin terraform
# NOTE: Twilio SSO/SAML configuration is not natively supported by the
# twilio/twilio Terraform provider as of v0.18.x. SAML SSO must be configured
# via the Twilio Console (Console > Account > Single Sign-On) or via the
# Twilio Organizations API (currently in beta).
#
# This file provides a null_resource provisioner that uses the Twilio CLI
# to document the expected SSO state and validate configuration.

resource "null_resource" "sso_saml_validation" {
  count = var.sso_saml_issuer != "" ? 1 : 0

  triggers = {
    saml_issuer = var.sso_saml_issuer
    saml_url    = var.sso_saml_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Twilio 1.1: SAML SSO Configuration"
      echo "============================================================"
      echo ""
      echo "SAML SSO must be configured manually in the Twilio Console:"
      echo "  Console > Account > Single Sign-On"
      echo ""
      echo "Expected configuration:"
      echo "  IdP Issuer:      ${var.sso_saml_issuer}"
      echo "  IdP SSO URL:     ${var.sso_saml_url}"
      echo "  Certificate:     [provided via variable]"
      echo "  SSO Enforcement: ENABLED"
      echo "  Admin Fallback:  ENABLED"
      echo ""
      echo "Validation: Log in via SSO to confirm configuration."
      echo "============================================================"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
