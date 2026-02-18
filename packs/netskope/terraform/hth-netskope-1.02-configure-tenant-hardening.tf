# =============================================================================
# HTH Netskope Control 1.2: Configure Tenant Hardening
# Profile Level: L1 (Baseline), IP allowlisting at L2
# Frameworks: CIS 4.1 | NIST CM-7
# Source: https://howtoharden.com/guides/netskope/#12-configure-tenant-hardening
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable audit logging and configure tenant security settings.
# IP allowlisting for admin access is an L2 control.

resource "null_resource" "tenant_hardening" {
  triggers = {
    session_timeout = var.session_timeout_minutes
    profile_level   = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/tenant/settings" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "audit_logging_enabled": true,
          "session_timeout": ${var.session_timeout_minutes}
        }'
    EOT
  }
}

# L2: Configure IP allowlisting for admin console access
resource "null_resource" "admin_ip_allowlist" {
  count = var.profile_level >= 2 && length(var.admin_ip_allowlist) > 0 ? 1 : 0

  triggers = {
    ip_allowlist = join(",", var.admin_ip_allowlist)
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/tenant/settings" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "admin_ip_allowlist_enabled": true,
          "admin_ip_allowlist": ${jsonencode(var.admin_ip_allowlist)}
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
