# =============================================================================
# HTH Fivetran Control 4.1: Configure Activity Logging
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/fivetran/#41-configure-activity-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure webhook for streaming activity logs to SIEM/monitoring
# Fivetran emits events for user logins, config changes, connector mods, syncs
resource "fivetran_webhook" "activity_log_webhook" {
  count = var.webhook_url != "" ? 1 : 0

  type   = "account"
  url    = var.webhook_url
  secret = var.webhook_secret
  active = true

  events = [
    "sync_start",
    "sync_end",
    "status",
    "connection_successful",
    "connection_failure",
    "dbt_run_start",
    "dbt_run_succeeded",
    "dbt_run_failed"
  ]
}

# Audit: enumerate recent activity log events via API
resource "null_resource" "audit_activity_logs" {
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================="
      echo "Activity Log Audit"
      echo "============================================="
      echo ""

      # Fetch recent activity log entries
      curl -s \
        "https://api.fivetran.com/v1/account/activity-log?limit=10" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
events = data.get('data', {}).get('items', [])
print(f'Recent activity log entries (last 10):')
print('')
for e in events:
    print(f'  [{e.get(\"created_at\", \"\")}] {e.get(\"event\", \"unknown\")} -- {e.get(\"actor\", \"system\")}')
if not events:
    print('  No activity log entries found (or API permissions insufficient)')
print('')
print('Key events to monitor:')
print('  - User logins and provisioning/deprovisioning')
print('  - SSO configuration changes')
print('  - Connector credential updates')
print('  - Permission modifications')
print('  - Sync failures and errors')
" 2>/dev/null || echo "Note: Python3 required for activity log report"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
