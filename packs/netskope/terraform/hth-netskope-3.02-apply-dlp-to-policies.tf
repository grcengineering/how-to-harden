# =============================================================================
# HTH Netskope Control 3.2: Apply DLP to Policies
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.1 | NIST SC-8
# Source: https://howtoharden.com/guides/netskope/#32-apply-dlp-to-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Apply DLP profiles to real-time protection and API protection policies.
# DLP enforcement actions escalate with profile level:
#   L1: Alert on violations (log but allow)
#   L2: Coach users (warn and require justification)
#   L3: Block sensitive data transfers

locals {
  dlp_action = (
    var.profile_level >= 3 ? "block" :
    var.profile_level >= 2 ? "coach" :
    "alert"
  )
}

# Apply DLP profile to real-time inline policy
resource "null_resource" "dlp_realtime_policy" {
  triggers = {
    action        = local.dlp_action
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X POST \
        "${var.netskope_tenant_url}/api/v2/policy/realtime" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "name": "HTH - DLP Real-Time Enforcement",
          "description": "Enforce DLP profile on all inline cloud traffic (action: ${local.dlp_action})",
          "enabled": true,
          "source": {
            "users": ["all"]
          },
          "destination": {
            "apps": ["all_cloud_apps"]
          },
          "activity": ["upload", "download", "share"],
          "dlp_profile": "HTH - Corporate Sensitive Data",
          "action": "${local.dlp_action}",
          "user_notification": "Sensitive data detected. This activity has been ${local.dlp_action == "block" ? "blocked" : "logged"} per organization policy."
        }'
    EOT
  }

  depends_on = [null_resource.dlp_profile_corporate]
}

# L2+: Apply DLP profile to API data protection scanning
resource "null_resource" "dlp_api_protection_policy" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/policy/api-protection/dlp" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "dlp_profile": "HTH - Corporate Sensitive Data",
          "enabled": true,
          "remediation": {
            "quarantine": true,
            "revoke_sharing": true,
            "notify_owner": true
          }
        }'
    EOT
  }

  depends_on = [
    null_resource.dlp_profile_corporate,
    null_resource.api_protection_config,
  ]
}
# HTH Guide Excerpt: end terraform
