# =============================================================================
# HTH Fivetran Control 3.1: Secure Connector Credentials
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/fivetran/#31-secure-connector-credentials
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create connectors with least-privilege service account credentials
# Each connector should use a dedicated service account with minimum permissions
resource "fivetran_connector" "managed_connectors" {
  for_each = var.connectors

  group_id        = each.value.group_id
  service         = each.value.service
  sync_frequency  = each.value.sync_frequency
  paused          = each.value.paused
  trust_certs     = each.value.trust_certs
  trust_fpints    = each.value.trust_fpints
  run_setup_tests = each.value.run_setup_tests

  dynamic "config" {
    for_each = length(each.value.config) > 0 ? [each.value.config] : []
    content {
      # Connector-specific configuration is passed via the config map
      # Ensure credentials use dedicated service accounts with:
      #   - Read-only access for data extraction
      #   - SELECT-only for database connectors
      #   - Never admin/superuser credentials
    }
  }
}

# Validation: audit connector configurations for security posture
resource "null_resource" "audit_connector_credentials" {
  triggers = {
    connector_count = length(var.connectors)
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================="
      echo "Connector Credential Security Audit"
      echo "============================================="
      echo ""

      # List all connectors and their services
      curl -s \
        "https://api.fivetran.com/v1/groups/${var.fivetran_account_id}/connectors" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
connectors = data.get('data', {}).get('items', [])
print(f'Total connectors: {len(connectors)}')
print('')
for c in connectors:
    status = c.get('status', {}).get('setup_state', 'unknown')
    print(f'  [{status}] {c.get(\"service\", \"unknown\")} -- {c.get(\"schema\", \"no-schema\")}')
print('')
print('Reminder: Verify each connector uses a dedicated service account')
print('with minimum required permissions (read-only / SELECT only).')
" 2>/dev/null || echo "Note: Python3 required for connector audit report"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
