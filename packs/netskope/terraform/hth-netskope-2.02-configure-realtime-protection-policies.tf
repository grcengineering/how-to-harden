# =============================================================================
# HTH Netskope Control 2.2: Configure Real-Time Protection Policies
# Profile Level: L1 (Baseline)
# Frameworks: CIS 9.2 | NIST SC-7, AC-4
# Source: https://howtoharden.com/guides/netskope/#22-configure-real-time-protection-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create real-time protection policies to control cloud application access.
# These policies enforce inline inspection for all steered traffic.

# Policy: Block high-risk unsanctioned cloud applications (CCI < threshold)
resource "null_resource" "block_unsanctioned_apps_policy" {
  count = var.block_unsanctioned_apps ? 1 : 0

  triggers = {
    cci_threshold = var.cci_high_risk_threshold
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X POST \
        "${var.netskope_tenant_url}/api/v2/policy/realtime" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "HTH - Block High-Risk Cloud Apps",
          "description": "Block cloud applications with CCI score below ${var.cci_high_risk_threshold}",
          "enabled": true,
          "source": {
            "users": ["all"]
          },
          "destination": {
            "cci_threshold": ${var.cci_high_risk_threshold},
            "cci_operator": "lt"
          },
          "activity": ["all"],
          "action": "block",
          "user_notification": "This application has been blocked by your organization security policy due to high risk score."
        }'
    EOT
  }
}

# Policy: Block uploads/shares to personal instances of cloud apps
resource "null_resource" "block_personal_instances_policy" {
  count = var.block_personal_instances ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X POST \
        "${var.netskope_tenant_url}/api/v2/policy/realtime" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "HTH - Block Upload to Personal Cloud",
          "description": "Prevent data upload and sharing to personal instances of cloud apps",
          "enabled": true,
          "source": {
            "users": ["all"]
          },
          "destination": {
            "instance_type": "personal"
          },
          "activity": ["upload", "share"],
          "action": "block",
          "user_notification": "Uploading or sharing to personal cloud instances is not permitted by organization policy."
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
