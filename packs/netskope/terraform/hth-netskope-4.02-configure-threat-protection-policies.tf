# =============================================================================
# HTH Netskope Control 4.2: Configure Threat Protection Policies
# Profile Level: L2 (Hardened)
# Frameworks: CIS 10.5 | NIST SI-4
# Source: https://howtoharden.com/guides/netskope/#42-configure-threat-protection-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create comprehensive threat protection policies following Netskope best
# practices. These L2 controls add behavioral analytics and suspicious
# category blocking beyond the L1 malware baseline.

# Block newly registered domains (common phishing/malware vector)
resource "null_resource" "block_newly_registered_domains" {
  count = var.profile_level >= 2 && var.block_newly_registered_domains ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X POST \
        "${var.netskope_tenant_url}/api/v2/policy/realtime" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "HTH - Block Newly Registered Domains",
          "description": "Block access to domains registered within the last 30 days",
          "enabled": true,
          "source": {
            "users": ["all"]
          },
          "destination": {
            "url_category": ["newly_registered_domains"]
          },
          "action": "block",
          "user_notification": "Access blocked: This domain was recently registered and may pose a security risk."
        }'
    EOT
  }
}

# Block uncategorized websites
resource "null_resource" "block_uncategorized_sites" {
  count = var.profile_level >= 2 && var.block_uncategorized_sites ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X POST \
        "${var.netskope_tenant_url}/api/v2/policy/realtime" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "HTH - Block Uncategorized Sites",
          "description": "Block access to uncategorized and parked domains",
          "enabled": true,
          "source": {
            "users": ["all"]
          },
          "destination": {
            "url_category": ["uncategorized", "parked_domains"]
          },
          "action": "block",
          "user_notification": "Access blocked: This website has not been categorized and may pose a security risk."
        }'
    EOT
  }
}

# Enable cloud behavior analytics for anomaly detection
resource "null_resource" "behavior_analytics" {
  count = var.profile_level >= 2 && var.enable_behavior_analytics ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/settings/security/behavior-analytics" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "enabled": true,
          "anomaly_detection": {
            "data_exfiltration": true,
            "compromised_account": true,
            "insider_threat": true
          }
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
