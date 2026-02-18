# =============================================================================
# HTH Fivetran Control 1.3: Configure Just-In-Time Provisioning
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.3, NIST AC-2
# Source: https://howtoharden.com/guides/fivetran/#13-configure-just-in-time-provisioning
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable JIT user provisioning via SAML (L2+)
# New users are automatically created on first SAML login with no permissions
resource "null_resource" "configure_jit_provisioning" {
  count = var.profile_level >= 2 && var.jit_provisioning_enabled && var.saml_idp_sso_url != "" ? 1 : 0

  triggers = {
    profile_level   = var.profile_level
    jit_enabled     = var.jit_provisioning_enabled
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PATCH \
        "https://api.fivetran.com/v1/account/config" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        -H "Content-Type: application/json" \
        -d '{
          "saml_enabled": true,
          "saml_user_provisioning": true
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
