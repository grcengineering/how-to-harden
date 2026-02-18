# =============================================================================
# HTH New Relic Control 2.1: Secure API Keys
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/new-relic/#21-secure-api-keys
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create a managed ingest key with a descriptive name for auditability.
# Each service should have its own key -- never share keys across services.
resource "newrelic_api_access_key" "managed_ingest_key" {
  count = var.api_key_user_id > 0 ? 1 : 0

  account_id  = var.newrelic_account_id
  key_type    = "INGEST"
  ingest_type = "LICENSE"
  name        = var.ingest_key_name
  notes       = "Managed by Terraform - HTH hardening pack. Rotate periodically."
}

# Alert policy for API key lifecycle events
resource "newrelic_alert_policy" "api_key_monitoring" {
  name                = "HTH: API Key Lifecycle Monitoring"
  incident_preference = "PER_CONDITION"
}

# Detect API key creation, deletion, or modification
resource "newrelic_nrql_alert_condition" "api_key_changes" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.api_key_monitoring.id
  type                         = "static"
  name                         = "HTH 2.1: API Key Change Detected"
  description                  = "Detects creation, deletion, or modification of API keys"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT count(*) FROM NrAuditEvent WHERE actionIdentifier LIKE '%apiKey%' OR actionIdentifier LIKE '%api_key%' SINCE 5 minutes ago"
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
