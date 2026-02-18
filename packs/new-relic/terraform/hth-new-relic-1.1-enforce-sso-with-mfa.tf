# =============================================================================
# HTH New Relic Control 1.1: Enforce SSO with MFA
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1)
# Source: https://howtoharden.com/guides/new-relic/#11-enforce-sso-with-mfa
# =============================================================================
#
# NOTE: New Relic SAML SSO and authentication domain configuration is not
# natively supported by the newrelic/newrelic Terraform provider. SSO must
# be configured via the New Relic UI or NerdGraph API.
#
# This file creates an NRQL alert to detect logins that bypass SSO, serving
# as a compensating detective control.

# HTH Guide Excerpt: begin terraform
# Alert policy for SSO bypass detection
resource "newrelic_alert_policy" "sso_bypass_detection" {
  name                = "HTH: SSO Bypass Detection"
  incident_preference = "PER_CONDITION"
}

# Detect logins not using SSO (non-SAML authentication events)
resource "newrelic_nrql_alert_condition" "non_sso_login" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.sso_bypass_detection.id
  type                         = "static"
  name                         = "HTH 1.1: Non-SSO Login Detected"
  description                  = "Detects authentication events that bypass SAML SSO"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT count(*) FROM NrAuditEvent WHERE actionIdentifier LIKE '%login%' AND description NOT LIKE '%SAML%' SINCE 5 minutes ago"
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
