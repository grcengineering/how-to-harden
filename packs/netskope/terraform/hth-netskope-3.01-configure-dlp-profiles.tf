# =============================================================================
# HTH Netskope Control 3.1: Configure DLP Profiles
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.1, 3.2 | NIST SC-8, SC-28
# Source: https://howtoharden.com/guides/netskope/#31-configure-dlp-profiles
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create DLP profiles for detecting sensitive data across cloud applications.
# Netskope DLP profiles are configured via REST API since the Terraform
# provider focuses on NPA/ZTNA resources.

locals {
  dlp_detection_rules = concat(
    var.dlp_credit_card_enabled ? ["credit_card"] : [],
    var.dlp_ssn_enabled ? ["ssn"] : [],
    var.dlp_api_keys_enabled ? ["api_keys_credentials"] : [],
  )
}

# Create a corporate DLP profile with selected detection rules
resource "null_resource" "dlp_profile_corporate" {
  triggers = {
    rules           = join(",", local.dlp_detection_rules)
    custom_patterns = join(",", var.dlp_custom_patterns)
    profile_level   = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X POST \
        "${var.netskope_tenant_url}/api/v2/policy/dlp/profiles" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "HTH - Corporate Sensitive Data",
          "description": "Detects credit cards, SSNs, API keys, and custom patterns per HTH hardening guide",
          "enabled": true,
          "detection_rules": ${jsonencode(local.dlp_detection_rules)},
          "custom_patterns": ${jsonencode(var.dlp_custom_patterns)},
          "severity": "high"
        }'
    EOT
  }
}

# L2+: Enable advanced DLP detection technologies
resource "null_resource" "dlp_advanced_detection" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/policy/dlp/settings" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "exact_data_match_enabled": true,
          "file_fingerprinting_enabled": true,
          "ocr_enabled": true,
          "ml_classification_enabled": true
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
