# =============================================================================
# HTH Keeper Control 1.3: Enable Administrative Event Alerts
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.11, NIST SI-4
# Source: https://howtoharden.com/guides/keeper/#13-enable-administrative-event-alerts
# =============================================================================
#
# Configure alerts for administrative events to detect suspicious activity.
# Keeper supports SIEM integration (Splunk, Azure Sentinel, custom webhook)
# and email alerts for admin login events, role modifications, policy
# changes, and user provisioning/deprovisioning.
#
# Implementation: Keeper Commander CLI and Admin Console configuration.
# SIEM endpoints are configured via the Reporting & Alerts console or
# the Commander CLI enterprise-event command.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Document SIEM integration configuration for administrative event alerts
resource "terraform_data" "admin_event_alerts" {
  input = {
    siem_endpoint    = var.siem_endpoint
    alert_recipients = var.alert_recipients
    monitored_events = [
      "admin_login",
      "role_modification",
      "policy_change",
      "user_provisioned",
      "user_deprovisioned",
      "failed_login_attempt",
      "2fa_change",
      "record_shared",
      "admin_privilege_change",
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 1.3: Administrative Event Alerts (L1)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure alerts in Keeper Admin Console"
      echo ""
      echo "  1. Navigate to: Admin Console > Reporting & Alerts"
      echo "  2. Enable alerts for:"
      echo "     - Admin login events"
      echo "     - Role modifications"
      echo "     - Policy changes"
      echo "     - User provisioning/deprovisioning"
      echo ""
      %{if var.siem_endpoint != ""~}
      echo "  3. Configure SIEM integration:"
      echo "     Endpoint: ${var.siem_endpoint}"
      echo ""
      %{endif~}
      %{if length(var.alert_recipients) > 0~}
      echo "  4. Configure notification recipients:"
      %{for email in var.alert_recipients~}
      echo "     - ${email}"
      %{endfor~}
      %{endif~}
      echo ""
      echo "============================================================"
    EOT
  }
}

# Store alert configuration as an auditable record
resource "secretsmanager_login" "alert_config_record" {
  count = var.siem_endpoint != "" ? 1 : 0

  folder_uid = var.security_config_folder_uid
  title      = "HTH Administrative Event Alert Configuration"

  login = "siem-integration"
  url   = var.siem_endpoint

  notes = <<-EOT
    ADMINISTRATIVE EVENT ALERT CONFIGURATION
    ==========================================
    Profile Level: L1 (Baseline)

    SIEM Endpoint: ${var.siem_endpoint}
    Alert Recipients: ${join(", ", var.alert_recipients)}

    Monitored Events:
    - Admin login events
    - Role modifications
    - Policy changes
    - User provisioning/deprovisioning
    - Failed login attempts
    - 2FA changes
    - Record sharing
    - Admin privilege changes

    Last updated: Managed by Terraform
    Control: HTH Keeper 1.3
  EOT
}
# HTH Guide Excerpt: end terraform
