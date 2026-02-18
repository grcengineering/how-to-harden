# =============================================================================
# HTH New Relic Control 4.1: NrAuditEvent Monitoring
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3
# Source: https://howtoharden.com/guides/new-relic/#41-nrauditevent
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Comprehensive alert policy for NrAuditEvent security monitoring
resource "newrelic_alert_policy" "audit_event_monitoring" {
  name                = "HTH: NrAuditEvent Security Monitoring"
  incident_preference = "PER_CONDITION_AND_TARGET"
}

# Detect configuration changes
resource "newrelic_nrql_alert_condition" "config_changes" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.audit_event_monitoring.id
  type                         = "static"
  name                         = "HTH 4.1: Configuration Change Detected"
  description                  = "Detects configuration changes via NrAuditEvent"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT count(*) FROM NrAuditEvent WHERE actionIdentifier LIKE '%update%' OR actionIdentifier LIKE '%modify%' OR actionIdentifier LIKE '%change%' SINCE 5 minutes ago"
  }

  critical {
    operator              = "above"
    threshold             = var.audit_alert_threshold_critical
    threshold_duration    = var.audit_alert_evaluation_window
    threshold_occurrences = "at_least_once"
  }

  warning {
    operator              = "above"
    threshold             = 3
    threshold_duration    = var.audit_alert_evaluation_window
    threshold_occurrences = "at_least_once"
  }

  fill_option = "none"
}

# Detect API key creation events
resource "newrelic_nrql_alert_condition" "api_key_creation" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.audit_event_monitoring.id
  type                         = "static"
  name                         = "HTH 4.1: API Key Created"
  description                  = "Detects API key creation events"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT count(*) FROM NrAuditEvent WHERE actionIdentifier LIKE '%apiKey%' AND actionIdentifier LIKE '%create%' SINCE 5 minutes ago"
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  fill_option = "none"
}

# Detect user additions and permission changes
resource "newrelic_nrql_alert_condition" "user_changes" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.audit_event_monitoring.id
  type                         = "static"
  name                         = "HTH 4.1: User Addition or Permission Change"
  description                  = "Detects user additions and permission modifications"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT count(*) FROM NrAuditEvent WHERE actionIdentifier LIKE '%user%' AND (actionIdentifier LIKE '%create%' OR actionIdentifier LIKE '%update%' OR actionIdentifier LIKE '%grant%') SINCE 5 minutes ago"
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  fill_option = "none"
}

# Detect account-level deletions
resource "newrelic_nrql_alert_condition" "deletion_events" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.audit_event_monitoring.id
  type                         = "static"
  name                         = "HTH 4.1: Deletion Event Detected"
  description                  = "Detects deletion of resources, dashboards, or configurations"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT count(*) FROM NrAuditEvent WHERE actionIdentifier LIKE '%delete%' OR actionIdentifier LIKE '%remove%' SINCE 5 minutes ago"
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  fill_option = "none"
}
# HTH Guide Excerpt: end terraform
