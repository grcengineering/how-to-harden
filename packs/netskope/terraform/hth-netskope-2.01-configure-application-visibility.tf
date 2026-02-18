# =============================================================================
# HTH Netskope Control 2.1: Configure Application Visibility
# Profile Level: L1 (Baseline)
# Frameworks: CIS 2.1 | NIST CM-8
# Source: https://howtoharden.com/guides/netskope/#21-configure-application-visibility
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable cloud app discovery and configure risk scoring thresholds.
# Application visibility is foundational to all CASB policies.

resource "null_resource" "app_discovery_settings" {
  triggers = {
    cci_high_risk   = var.cci_high_risk_threshold
    cci_medium_risk = var.cci_medium_risk_threshold
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/policy/app-discovery" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "enabled": true,
          "risk_thresholds": {
            "high_risk_below": ${var.cci_high_risk_threshold},
            "medium_risk_below": ${var.cci_medium_risk_threshold}
          }
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
