# =============================================================================
# HTH Databricks Control 5.1: Security Monitoring
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-4, SOC 2 CC7.2, CC7.3
# Source: https://howtoharden.com/guides/databricks/#51-security-monitoring
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Workspace configuration for security monitoring
# Disables risky features that complicate audit trails
resource "databricks_workspace_conf" "security_monitoring" {
  custom_config = {
    # Disable DBFS file browser to prevent unaudited file access
    "enableDbfsFileBrowser" = false

    # Restrict notebook export to prevent data exfiltration (L3)
    "enableExportNotebook" = var.profile_level >= 3 ? false : true

    # Disable results download for non-admin users (L2+)
    "enableResultsDownloading" = var.profile_level >= 2 ? false : true
  }
}

# Note: Detection queries should be scheduled as Databricks SQL alerts:
#
# Bulk data access detection:
#   SELECT user_identity.email, request_params.full_name_arg as table_name,
#          COUNT(*) as access_count
#   FROM system.access.audit
#   WHERE action_name = 'commandSubmit'
#     AND event_time > current_timestamp() - INTERVAL 1 HOUR
#   GROUP BY user_identity.email, request_params.full_name_arg
#   HAVING COUNT(*) > 100;
#
# Unusual export detection:
#   SELECT * FROM system.access.audit
#   WHERE action_name IN ('downloadResults', 'exportResults')
#     AND event_time > current_timestamp() - INTERVAL 24 HOURS;
#
# Service principal anomaly detection:
#   SELECT user_identity.email, source_ip_address, COUNT(*) as request_count
#   FROM system.access.audit
#   WHERE user_identity.email LIKE 'svc-%'
#     AND event_time > current_timestamp() - INTERVAL 1 HOUR
#   GROUP BY user_identity.email, source_ip_address;
# HTH Guide Excerpt: end terraform
