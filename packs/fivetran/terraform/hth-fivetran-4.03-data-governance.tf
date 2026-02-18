# =============================================================================
# HTH Fivetran Control 4.3: Data Governance
# Profile Level: L2 (Hardened)
# Frameworks: CIS 3.1, NIST AC-3
# Source: https://howtoharden.com/guides/fivetran/#43-data-governance
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Data governance: column blocking and hashing for sensitive data (L2+)
# Prevents PII replication and maintains referential integrity

# Block sensitive columns from sync (L2+)
# Column blocking prevents specific columns from being replicated to the destination
resource "fivetran_connector_schema_config" "column_blocking" {
  for_each = var.profile_level >= 2 ? var.blocked_columns : {}

  connector_id          = each.key
  schema_change_handling = "BLOCK_ALL"

  # Note: Column-level blocking is configured per-schema within the connector.
  # The fivetran_connector_schema_config resource manages schema-level settings.
  # For column-level blocking, use the schema configuration to disable
  # specific columns containing PII or sensitive data.
  #
  # Blocked columns for this connector:
  # %{ for col in each.value ~}
  #   - ${col}
  # %{ endfor ~}
}

# Hash sensitive columns during sync (L2+)
# Hashing replaces column values with one-way hashes for referential integrity
resource "null_resource" "configure_column_hashing" {
  for_each = var.profile_level >= 2 ? var.hashed_columns : {}

  triggers = {
    connector_id = each.key
    columns      = join(",", each.value)
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================="
      echo "Column Hashing Configuration (L2+)"
      echo "============================================="
      echo ""
      echo "Connector: ${each.key}"
      echo "Columns to hash:"
      %{ for col in each.value ~}
      echo "  - ${col}"
      %{ endfor ~}
      echo ""
      echo "Column hashing is configured via Fivetran Dashboard:"
      echo "  1. Navigate to connector settings"
      echo "  2. Go to Schema tab"
      echo "  3. Select the column to hash"
      echo "  4. Enable 'Hash this column'"
      echo ""
      echo "Hashing preserves referential integrity while protecting PII."
      echo "Hashed values are consistent -- the same input always produces"
      echo "the same hash -- enabling joins across tables."
    EOT
  }
}

# Audit: document data flows for governance
resource "null_resource" "audit_data_flows" {
  count = var.profile_level >= 2 ? 1 : 0

  triggers = {
    profile_level = var.profile_level
    timestamp     = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================="
      echo "Data Governance Audit (L2+)"
      echo "============================================="
      echo ""

      # Inventory all connectors and destinations
      curl -s \
        "https://api.fivetran.com/v1/groups" \
        -H "Authorization: Basic $(echo -n '${var.fivetran_api_key}:${var.fivetran_api_secret}' | base64)" \
        | python3 -c "
import sys, json
data = json.load(sys.stdin)
groups = data.get('data', {}).get('items', [])
print(f'Data Flow Inventory:')
print(f'  Groups (destinations): {len(groups)}')
for g in groups:
    print(f'  - {g.get(\"name\", \"unnamed\")} (ID: {g.get(\"id\", \"\")})')
print('')
print('Data Governance Checklist:')
print('  [1] Inventory all connectors and their data sources')
print('  [2] Document data destinations and schemas')
print('  [3] Block sensitive/PII columns from sync')
print('  [4] Hash columns requiring referential integrity')
print('  [5] Maintain data lineage documentation')
print('  [6] Review data flows quarterly')
" 2>/dev/null || echo "Note: Python3 required for data flow audit report"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
