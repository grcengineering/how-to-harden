# =============================================================================
# HTH New Relic Control 2.2: License Key Protection
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/new-relic/#22-license-key-protection
# =============================================================================
#
# NOTE: License key rotation is a manual/API operation. This file creates
# a monitoring alert to detect license key usage anomalies as a compensating
# detective control for key compromise.

# HTH Guide Excerpt: begin terraform
# Alert policy for license key anomaly detection
resource "newrelic_alert_policy" "license_key_monitoring" {
  name                = "HTH: License Key Anomaly Detection"
  incident_preference = "PER_CONDITION"
}

# Detect unusual data ingest patterns that may indicate key compromise
resource "newrelic_nrql_alert_condition" "license_key_anomaly" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.license_key_monitoring.id
  type                         = "static"
  name                         = "HTH 2.2: Unusual Ingest Volume Detected"
  description                  = "Detects abnormal data ingest volumes that may indicate license key compromise or misuse"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT rate(bytecountestimate(), 1 minute) FROM Log, Metric, Span SINCE 10 minutes ago"
  }

  critical {
    operator              = "above"
    threshold             = 1000000000
    threshold_duration    = 600
    threshold_occurrences = "all"
  }

  warning {
    operator              = "above"
    threshold             = 500000000
    threshold_duration    = 600
    threshold_occurrences = "all"
  }

  fill_option = "none"
}
# HTH Guide Excerpt: end terraform
