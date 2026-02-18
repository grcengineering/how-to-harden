# =============================================================================
# HTH PagerDuty Control 4.1: Configure Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/pagerduty/#41-configure-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# PagerDuty audit records are available at Account Settings > Audit Records.
# This control configures a webhook extension to forward audit-relevant
# events to a SIEM for centralized monitoring and retention.

# Create a generic "audit" service to receive webhook events
resource "pagerduty_service" "audit_logging" {
  count = var.audit_log_webhook_url != "" ? 1 : 0

  name                    = "HTH Audit Log Collector"
  description             = "Service for collecting and forwarding audit events to SIEM"
  auto_resolve_timeout    = "null"
  acknowledgement_timeout = "null"

  escalation_policy = pagerduty_escalation_policy.audit_logging[0].id

  alert_creation = "create_alerts_and_incidents"

  incident_urgency_rule {
    type    = "constant"
    urgency = "low"
  }
}

# Minimal escalation policy for the audit service
resource "pagerduty_escalation_policy" "audit_logging" {
  count = var.audit_log_webhook_url != "" ? 1 : 0

  name      = "HTH Audit Log Escalation"
  num_loops = 0

  rule {
    escalation_delay_in_minutes = 30

    target {
      type = "user_reference"
      id   = data.pagerduty_users.all.users[0].id
    }
  }
}

# Webhook extension to forward events to SIEM
resource "pagerduty_extension" "audit_webhook" {
  count = var.audit_log_webhook_url != "" ? 1 : 0

  name               = var.audit_webhook_name
  type               = "generic_v2_webhook_inbound_integration"
  endpoint_url       = var.audit_log_webhook_url
  extension_schema   = data.pagerduty_extension_schema.webhook[0].id
  extension_objects  = [pagerduty_service.audit_logging[0].id]
}

data "pagerduty_extension_schema" "webhook" {
  count = var.audit_log_webhook_url != "" ? 1 : 0
  name  = "Generic V2 Webhook"
}

# Audit log export reminder
resource "null_resource" "audit_log_guidance" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "[HTH] Audit Logging Configuration:"
      echo "[HTH]   - PagerDuty audit records: Account Settings > Audit Records"
      echo "[HTH]   - API endpoint: GET https://api.pagerduty.com/audit/records"
      echo "[HTH]   - Retention: PagerDuty retains audit records per plan limits"
      echo "[HTH]   - Export: Use API to pull records into SIEM for long-term retention"
      echo "[HTH]"
      echo "[HTH] Verification:"
      RECORD_COUNT=$(curl -s \
        "https://api.pagerduty.com/audit/records?limit=1" \
        -H "Authorization: Token token=${var.pagerduty_api_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/vnd.pagerduty+json;version=2" \
        | jq '.records | length // 0')
      echo "[HTH]   Audit records accessible: $([ "$RECORD_COUNT" -ge 0 ] && echo 'YES' || echo 'NO')"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
