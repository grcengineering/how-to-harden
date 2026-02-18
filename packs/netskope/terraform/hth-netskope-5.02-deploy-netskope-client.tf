# =============================================================================
# HTH Netskope Control 5.2: Deploy Netskope Client
# Profile Level: L1 (Baseline)
# Frameworks: CIS 4.1 | NIST SC-7
# Source: https://howtoharden.com/guides/netskope/#52-deploy-netskope-client
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure Netskope Client settings for endpoint deployment.
# Fail-close mode provides maximum security but may impact availability.
# L3 environments should enable fail-close; L1/L2 may prefer fail-open.

locals {
  # L3 forces fail-close for maximum security regardless of variable setting
  effective_fail_close = var.profile_level >= 3 ? true : var.fail_close
}

resource "null_resource" "client_configuration" {
  triggers = {
    fail_close  = local.effective_fail_close
    auto_update = var.client_auto_update
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/steering/client-config" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "fail_close": ${local.effective_fail_close},
          "auto_update": ${var.client_auto_update},
          "ssl_inspection": true
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
