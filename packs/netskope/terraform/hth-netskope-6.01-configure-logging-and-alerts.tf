# =============================================================================
# HTH Netskope Control 6.1: Configure Logging and Alerts
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2 | NIST AU-2, AU-6
# Source: https://howtoharden.com/guides/netskope/#61-configure-logging-and-alerts
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure comprehensive logging, alerting, and SIEM integration.
# All profile levels require alert configuration; SIEM integration
# is recommended for L2+ environments.

# Configure alert policies for security events
resource "null_resource" "alert_policies" {
  triggers = {
    dlp_alerts         = var.alert_on_dlp_violations
    malware_alerts     = var.alert_on_malware
    policy_alerts      = var.alert_on_policy_violations
    admin_change_alerts = var.alert_on_admin_changes
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/settings/alerts" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "alerts": [
            {
              "name": "HTH - DLP Violations",
              "event_type": "dlp_violation",
              "enabled": ${var.alert_on_dlp_violations}
            },
            {
              "name": "HTH - Malware Detection",
              "event_type": "malware_detected",
              "enabled": ${var.alert_on_malware}
            },
            {
              "name": "HTH - Policy Violations",
              "event_type": "policy_violation",
              "enabled": ${var.alert_on_policy_violations}
            },
            {
              "name": "HTH - Admin Changes",
              "event_type": "admin_audit",
              "enabled": ${var.alert_on_admin_changes}
            }
          ]
        }'
    EOT
  }
}

# Configure SIEM integration via Cloud Log Shipper
resource "null_resource" "siem_integration" {
  count = var.siem_type != "none" ? 1 : 0

  triggers = {
    siem_type     = var.siem_type
    siem_endpoint = var.siem_endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -s -X PUT \
        "${var.netskope_tenant_url}/api/v2/settings/cloud-log-shipper" \
        -H "Netskope-Api-Token: ${var.netskope_api_key}" \
        -H "Content-Type: application/json" \
        -d '{
          "enabled": true,
          "type": "${var.siem_type}",
          "endpoint": "${var.siem_endpoint}",
          "token": "${var.siem_token}",
          "log_types": [
            "application_events",
            "page_events",
            "alert_events",
            "audit_events",
            "infrastructure_events"
          ]
        }'
    EOT
  }
}
# HTH Guide Excerpt: end terraform
