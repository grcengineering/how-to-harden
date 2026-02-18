# =============================================================================
# HTH Netskope Control 5.1: Configure Netskope Client Steering
# Profile Level: L1 (Baseline)
# Frameworks: CIS 13.5 | NIST SC-7
# Source: https://howtoharden.com/guides/netskope/#51-configure-netskope-client-steering
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure traffic steering to ensure proper routing through the Netskope
# cloud for inline inspection. Certificate-pinned apps must be excluded.
#
# IMPORTANT: Do NOT set custom app domains to "*" for certificate-pinned apps,
# as this will bypass all inspection.

resource "null_resource" "steering_configuration" {
  triggers = {
    steering_mode      = var.steering_mode
    cert_pinned_domains = join(",", var.cert_pinned_domains)
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/steering/settings" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "steering_mode": "${var.steering_mode}",
          "steer_all_cloud_apps": true
        }'
    EOT
  }
}

# Configure certificate-pinned app exceptions (Do Not Steer list)
resource "null_resource" "cert_pinned_exceptions" {
  count = length(var.cert_pinned_domains) > 0 ? 1 : 0

  triggers = {
    domains = join(",", var.cert_pinned_domains)
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/steering/exceptions" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "do_not_steer": ${jsonencode(var.cert_pinned_domains)},
          "reason": "Certificate-pinned applications that cannot be inspected via SSL interception"
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
