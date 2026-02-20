# =============================================================================
# HTH Fivetran Control 4.2: Configure Sync Monitoring
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST CA-7
# Source: https://howtoharden.com/guides/fivetran/#42-configure-sync-monitoring
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure notification settings for sync failure alerts
# Integrates with email, Slack, PagerDuty, and custom webhooks
resource "fivetran_webhook" "sync_failure_webhook" {
  count = var.webhook_url != "" ? 1 : 0

  type   = "account"
  url    = var.webhook_url
  secret = var.webhook_secret
  active = true

  events = [
    "sync_end",
    "connection_failure",
    "status"
  ]
}

# Audit: check current sync health across all connectors
resource "null_resource" "audit_sync_health" {
  triggers = {
    timestamp = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "Checking sync health across all connectors..."
      curl -s \
        "https://api.fivetran.com/v1/groups/${var.fivetran_account_id}/connectors" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
connectors = data.get('data', {}).get('items', [])
failed = [c for c in connectors if c.get('status', {}).get('sync_state') == 'failure']
paused = [c for c in connectors if c.get('paused')]
healthy = len(connectors) - len(failed) - len(paused)
print(f'Connector Health Summary:')
print(f'  Total:   {len(connectors)}')
print(f'  Healthy: {healthy}')
print(f'  Failed:  {len(failed)}')
print(f'  Paused:  {len(paused)}')
if failed:
    print('')
    print('Failed connectors requiring attention:')
    for c in failed:
        print(f'  - {c.get(\"service\", \"unknown\")}: {c.get(\"schema\", \"\")}')
" 2>/dev/null || echo "Note: Python3 required for sync health report"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
