# =============================================================================
# HTH Netskope Control 1.1: Secure Admin Console Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4 | NIST AC-6(1)
# Source: https://howtoharden.com/guides/netskope/#11-secure-admin-console-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure SSO for admin console access via the Netskope REST API.
# The Terraform provider does not expose SSO/MFA configuration natively,
# so we use null_resource with local-exec to call the REST API.

resource "null_resource" "admin_sso_configuration" {
  count = var.admin_sso_idp_entity_id != "" ? 1 : 0

  triggers = {
    idp_entity_id = var.admin_sso_idp_entity_id
    idp_sso_url   = var.admin_sso_idp_sso_url
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/tenant/sso" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "sso_enabled": true,
          "idp_entity_id": "${var.admin_sso_idp_entity_id}",
          "idp_sso_url": "${var.admin_sso_idp_sso_url}",
          "idp_certificate": "${var.admin_sso_idp_certificate}"
        }'
    EOT
  }
}

# Configure admin session timeout via REST API
resource "null_resource" "admin_session_timeout" {
  triggers = {
    timeout = var.session_timeout_minutes
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/tenant/settings" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "session_timeout": ${var.session_timeout_minutes}
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
