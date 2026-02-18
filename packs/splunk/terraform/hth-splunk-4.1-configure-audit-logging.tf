# =============================================================================
# HTH Splunk Control 4.1: Configure Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2, NIST AU-2
# Source: https://howtoharden.com/guides/splunk/#41-configure-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Monitor administrative and security events through the _audit index.
# Configure saved searches for audit alerting on critical actions.

# Enable audit trail forwarding to dedicated index
resource "splunk_configs_conf" "audit_trail_inputs" {
  name = "inputs/monitor:///opt/splunk/var/log/splunk/audit.log"

  variables = {
    "disabled"   = "false"
    "index"      = var.audit_index_name
    "sourcetype" = "splunk_audit"
  }
}

# Saved search: Alert on admin role changes (L1)
resource "splunk_saved_searches" "alert_role_changes" {
  name    = "HTH - Admin Role Changes"
  search  = "index=_audit action=edit_roles OR action=edit_user | stats count by user, action, info"

  is_scheduled  = true
  is_visible    = true
  cron_schedule = "*/15 * * * *"

  actions               = "email"
  action_email_to       = "security-team@example.com"
  action_email_subject  = "HTH Alert: Splunk Role Change Detected"

  alert_type            = "number of events"
  alert_comparator      = "greater than"
  alert_threshold       = "0"

  dispatch_earliest_time = "-15m"
  dispatch_latest_time   = "now"
}

# Saved search: Alert on failed authentications (L1)
resource "splunk_saved_searches" "alert_failed_auth" {
  name    = "HTH - Failed Authentication Attempts"
  search  = "index=_audit action=login status=failure | stats count by user, src | where count > 5"

  is_scheduled  = true
  is_visible    = true
  cron_schedule = "*/10 * * * *"

  actions               = "email"
  action_email_to       = "security-team@example.com"
  action_email_subject  = "HTH Alert: Multiple Failed Splunk Logins"

  alert_type            = "number of events"
  alert_comparator      = "greater than"
  alert_threshold       = "0"

  dispatch_earliest_time = "-10m"
  dispatch_latest_time   = "now"
}

# Saved search: Alert on configuration changes (L2+)
resource "splunk_saved_searches" "alert_config_changes" {
  count = var.profile_level >= 2 ? 1 : 0

  name    = "HTH - Configuration Changes"
  search  = "index=_internal sourcetype=splunkd component=ModifyConfig | stats count by user, action, object"

  is_scheduled  = true
  is_visible    = true
  cron_schedule = "*/30 * * * *"

  actions               = "email"
  action_email_to       = "security-team@example.com"
  action_email_subject  = "HTH Alert: Splunk Configuration Modified"

  alert_type            = "number of events"
  alert_comparator      = "greater than"
  alert_threshold       = "0"

  dispatch_earliest_time = "-30m"
  dispatch_latest_time   = "now"
}

# Saved search: Alert on search of sensitive indexes (L2+)
resource "splunk_saved_searches" "alert_sensitive_search" {
  count = var.profile_level >= 2 ? 1 : 0

  name    = "HTH - Sensitive Index Access"
  search  = "index=_audit action=search info=granted search=*${var.security_index_name}* NOT user=splunk-system-user | stats count by user, search"

  is_scheduled  = true
  is_visible    = true
  cron_schedule = "*/60 * * * *"

  actions               = "email"
  action_email_to       = "security-team@example.com"
  action_email_subject  = "HTH Alert: Sensitive Index Searched"

  alert_type            = "number of events"
  alert_comparator      = "greater than"
  alert_threshold       = "0"

  dispatch_earliest_time = "-60m"
  dispatch_latest_time   = "now"
}
# HTH Guide Excerpt: end terraform
