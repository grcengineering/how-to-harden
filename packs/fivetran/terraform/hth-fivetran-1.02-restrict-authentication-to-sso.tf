# =============================================================================
# HTH Fivetran Control 1.2: Restrict Authentication to SSO
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.3, NIST IA-2
# Source: https://howtoharden.com/guides/fivetran/#12-restrict-authentication-to-sso
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enforce SAML-only authentication (L2+)
# Disables password-based login -- all users must authenticate via IdP
resource "null_resource" "enforce_saml_only" {
  count = var.profile_level >= 2 && var.sso_enforce_saml_only && var.saml_idp_sso_url != "" ? 1 : 0

  triggers = {
    profile_level = var.profile_level
    enforce_saml  = var.sso_enforce_saml_only
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PATCH \
        "https://api.fivetran.com/v1/account/config" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        -H "Content-Type: application/json" \
        -d '{
          "required_authentication_type": "SAML"
        }'
    EOT
  }
}

# Validation: verify password login is disabled after enforcement
resource "null_resource" "verify_saml_enforcement" {
  count = var.profile_level >= 2 && var.sso_enforce_saml_only && var.saml_idp_sso_url != "" ? 1 : 0

  depends_on = [null_resource.enforce_saml_only]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Verifying SAML enforcement..."
      RESPONSE=$(curl -s \
        "https://api.fivetran.com/v1/account/config" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)")
      echo "$RESPONSE" | grep -q '"required_authentication_type":"SAML"' && \
        echo "PASS: SAML-only authentication enforced" || \
        echo "WARN: SAML enforcement could not be verified"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
