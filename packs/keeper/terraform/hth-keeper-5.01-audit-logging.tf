# =============================================================================
# HTH Keeper Control 5.1: Configure Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/keeper/#51-configure-audit-logging
# =============================================================================
#
# Enable and review audit logs for security events. Keeper supports SIEM
# integration with Splunk, Azure Sentinel, and custom webhooks. Key events
# to monitor include failed logins, 2FA changes, record sharing, admin
# privilege changes, and policy modifications.
#
# Implementation: Keeper Commander CLI and Admin Console.
# SIEM integration is configured through Reporting & Alerts.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure audit logging and SIEM integration
resource "terraform_data" "audit_logging" {
  input = {
    siem_endpoint  = var.siem_endpoint
    retention_days = var.audit_log_retention_days
    profile_level  = var.profile_level
    key_events = [
      "failed_login_attempts",
      "2fa_changes",
      "record_sharing",
      "admin_privilege_changes",
      "policy_modifications",
      "user_provisioning",
      "user_deprovisioning",
      "vault_export_attempts",
    ]
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 5.1: Audit Logging (L1)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure audit logging in Keeper Admin Console"
      echo ""
      echo "  Step 1: Access Reporting"
      echo "  1. Navigate to: Admin Console > Reporting & Alerts"
      echo "  2. Review available reports:"
      echo "     - Login activity"
      echo "     - Record access"
      echo "     - Sharing activity"
      echo "     - Admin actions"
      echo ""
      %{if var.siem_endpoint != ""~}
      echo "  Step 2: Configure SIEM Integration"
      echo "  1. Navigate to: Reporting & Alerts > SIEM Integration"
      echo "  2. Configure export destination: ${var.siem_endpoint}"
      echo "  3. Select events to stream:"
      echo "     - Failed login attempts"
      echo "     - 2FA changes"
      echo "     - Record sharing"
      echo "     - Admin privilege changes"
      echo "     - Policy modifications"
      %{endif~}
      echo ""
      echo "  Log Retention: ${var.audit_log_retention_days} days"
      echo ""
      echo "Or use Keeper Commander CLI:"
      echo "  keeper-commander audit-log --format=syslog \\"
      echo "    --target='${var.siem_endpoint}'"
      echo "============================================================"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
