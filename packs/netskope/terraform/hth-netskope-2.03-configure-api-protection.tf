# =============================================================================
# HTH Netskope Control 2.3: Configure API Protection
# Profile Level: L2 (Hardened)
# Frameworks: CIS 3.1 | NIST SC-28
# Source: https://howtoharden.com/guides/netskope/#23-configure-api-protection
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure API-enabled protection to scan data at rest in sanctioned SaaS apps.
# This is an L2 control requiring SSE Professional or Enterprise license.

resource "null_resource" "api_protection_config" {
  count = var.profile_level >= 2 && length(var.api_protection_apps) > 0 ? 1 : 0

  triggers = {
    apps           = join(",", var.api_protection_apps)
    scan_frequency = var.api_scan_frequency
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/policy/api-protection" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "enabled": true,
          "scan_frequency": "${var.api_scan_frequency}",
          "malware_scan_enabled": true,
          "dlp_scan_enabled": true,
          "remediation": {
            "quarantine_sensitive_files": true,
            "revoke_external_sharing": true,
            "notify_owner": true
          }
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
