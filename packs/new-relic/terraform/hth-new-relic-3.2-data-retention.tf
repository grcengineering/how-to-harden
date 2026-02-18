# =============================================================================
# HTH New Relic Control 3.2: Data Retention
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-12
# Source: https://howtoharden.com/guides/new-relic/#32-data-retention
# =============================================================================
#
# NOTE: Data retention configuration in New Relic is managed through the
# NerdGraph API (dataManagementCustomizeRetentions mutation) and is not
# natively supported by the Terraform provider. This file creates a
# monitoring alert as a compensating detective control to track data
# retention changes.

# HTH Guide Excerpt: begin terraform
# Alert policy for data retention compliance monitoring
resource "newrelic_alert_policy" "data_retention_monitoring" {
  name                = "HTH: Data Retention Compliance"
  incident_preference = "PER_CONDITION"
}

# Detect data retention setting changes via audit events
resource "newrelic_nrql_alert_condition" "retention_changes" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.data_retention_monitoring.id
  type                         = "static"
  name                         = "HTH 3.2: Data Retention Change Detected"
  description                  = "Detects modifications to data retention settings"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT count(*) FROM NrAuditEvent WHERE actionIdentifier LIKE '%retention%' OR actionIdentifier LIKE '%dataManagement%' SINCE 5 minutes ago"
  }

  critical {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 300
    threshold_occurrences = "at_least_once"
  }

  fill_option = "none"
}

# Monitor data age to ensure retention policies are functioning
resource "newrelic_nrql_alert_condition" "data_age_compliance" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.data_retention_monitoring.id
  type                         = "static"
  name                         = "HTH 3.2: Log Data Exceeds Retention Window"
  description                  = "Detects if log data older than the configured retention window still exists"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT count(*) FROM Log WHERE timestamp < ago(${var.log_retention_days} days) SINCE 1 hour ago"
  }

  warning {
    operator              = "above"
    threshold             = 0
    threshold_duration    = 3600
    threshold_occurrences = "all"
  }

  fill_option = "none"
}
# HTH Guide Excerpt: end terraform
