# =============================================================================
# HTH Fivetran Control 1.1: Configure SAML Single Sign-On
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/12.5, NIST IA-2/IA-8
# Source: https://howtoharden.com/guides/fivetran/#11-configure-saml-single-sign-on
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure SAML SSO for centralized authentication
resource "fivetran_external_logging" "saml_sso_config_audit" {
  # Note: The Fivetran Terraform provider does not expose a dedicated SAML SSO
  # resource. SAML configuration is managed via the Fivetran REST API or
  # Dashboard. This file provides the API-based implementation as a
  # null_resource provisioner for automation.
  count = 0 # Placeholder -- see null_resource below
}

# Automate SAML SSO configuration via the Fivetran REST API
resource "null_resource" "configure_saml_sso" {
  count = var.saml_idp_sso_url != "" ? 1 : 0

  triggers = {
    idp_sso_url  = var.saml_idp_sso_url
    idp_entity_id = var.saml_idp_entity_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PATCH \
        "https://api.fivetran.com/v1/account/config" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        -H "Content-Type: application/json" \
        -d '{
          "saml_enabled": true,
          "saml_sso_url": "${var.saml_idp_sso_url}",
          "saml_entity_id": "${var.saml_idp_entity_id}",
          "saml_certificate": "${var.saml_x509_certificate}"
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
