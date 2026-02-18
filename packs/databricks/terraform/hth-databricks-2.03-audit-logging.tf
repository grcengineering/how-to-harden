# =============================================================================
# HTH Databricks Control 2.3: Audit Logging for Data Access
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3, SOC 2 CC7.2
# Source: https://howtoharden.com/guides/databricks/#23-audit-logging-for-data-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable system tables for audit log access
# System tables (system.access.audit) provide comprehensive audit logging
# for all workspace events including data access, cluster operations, and
# administrative changes.
resource "databricks_workspace_conf" "audit_logging" {
  custom_config = {
    "enableDbfsFileBrowser" = false
    "enableExportNotebook"  = var.profile_level >= 3 ? false : true
  }
}

# Note: Verbose audit log queries should be scheduled via Databricks SQL:
#
#   SELECT event_time, user_identity.email as user_email,
#          action_name, request_params.full_name_arg as table_accessed,
#          source_ip_address
#   FROM system.access.audit
#   WHERE action_name IN ('getTable', 'commandSubmit')
#     AND event_time > current_timestamp() - INTERVAL 24 HOURS
#   ORDER BY event_time DESC;
# HTH Guide Excerpt: end terraform
