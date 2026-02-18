# =============================================================================
# HTH New Relic Control 3.1: Configure Data Obfuscation
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-28
# Source: https://howtoharden.com/guides/new-relic/#31-configure-data-obfuscation
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Obfuscation expressions for each sensitive data pattern
resource "newrelic_obfuscation_expression" "sensitive_patterns" {
  for_each = { for idx, pattern in var.obfuscation_patterns : pattern.name => pattern }

  account_id  = var.newrelic_account_id
  name        = "HTH: ${each.value.name}"
  description = "Obfuscation pattern for ${each.value.name} - managed by HTH hardening pack"
  regex       = each.value.pattern
}

# Obfuscation rule applying all patterns to log data
resource "newrelic_obfuscation_rule" "sensitive_data_masking" {
  for_each = { for idx, pattern in var.obfuscation_patterns : pattern.name => pattern }

  account_id  = var.newrelic_account_id
  name        = "HTH: Mask ${each.value.name}"
  description = "Mask ${each.value.name} in log messages - managed by HTH hardening pack"
  filter      = "message IS NOT NULL"
  enabled     = true

  action {
    attribute    = ["message"]
    expression_id = newrelic_obfuscation_expression.sensitive_patterns[each.key].id
    method       = "HASH_SHA256"
  }
}

# Alert on obfuscation rule matches to track sensitive data exposure
resource "newrelic_alert_policy" "data_obfuscation_monitoring" {
  name                = "HTH: Data Obfuscation Monitoring"
  incident_preference = "PER_CONDITION"
}

resource "newrelic_nrql_alert_condition" "obfuscation_effectiveness" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.data_obfuscation_monitoring.id
  type                         = "static"
  name                         = "HTH 3.1: High Volume of Obfuscated Data"
  description                  = "Detects high volumes of obfuscated sensitive data, indicating potential data leak in telemetry pipeline"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT count(*) FROM Log WHERE message LIKE '%OBFUSCATED%' SINCE 30 minutes ago"
  }

  warning {
    operator              = "above"
    threshold             = 1000
    threshold_duration    = 1800
    threshold_occurrences = "all"
  }

  fill_option = "none"
}
# HTH Guide Excerpt: end terraform
