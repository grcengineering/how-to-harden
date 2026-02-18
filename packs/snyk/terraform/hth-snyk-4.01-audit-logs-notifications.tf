# =============================================================================
# HTH Snyk Control 4.1: Audit Logs and Notification Settings
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3, SI-4, SOC 2 CC7.2, CC7.3, ISO 27001 A.12.4, PCI DSS 10.2
# Source: https://howtoharden.com/guides/snyk/#41-audit-logs-enterprise
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure notification settings for security-relevant events.
# Audit logs are available via the Snyk API (Enterprise plan) and
# should be forwarded to a SIEM for centralized monitoring.

# Enable notifications for new vulnerability discoveries
resource "snyk_notification_setting" "new_issues" {
  organization_id = var.snyk_org_id

  new_issues_remediations = {
    enabled    = var.new_issues_notification
    issue_type = "vuln"
    severity   = "high"
  }
}

# Enable weekly vulnerability report for security oversight
resource "snyk_notification_setting" "weekly_report" {
  organization_id = var.snyk_org_id

  weekly_report = {
    enabled = var.weekly_report_enabled
  }
}

# Note: Audit log export requires the Snyk REST API (Enterprise plan):
#
#   GET https://api.snyk.io/rest/groups/{group_id}/audit_logs/search
#     ?from=2024-01-01T00:00:00Z
#     &to=2024-01-31T23:59:59Z
#
# Key audit events to monitor:
# - org.user.add / org.user.remove (membership changes)
# - org.service_account.create / org.service_account.delete
# - org.integration.create / org.integration.delete
# - org.project.ignore.create (vulnerability ignores)
# - org.settings.update (organization setting changes)
# - group.sso.update (SSO configuration changes)
#
# Forward audit logs to your SIEM using the Snyk Audit Logs API
# or configure a webhook for real-time event streaming.
#
# Use the companion API script for audit log export:
#   bash packs/snyk/api/hth-snyk-4.01-audit-logs-notifications.sh
# HTH Guide Excerpt: end terraform
