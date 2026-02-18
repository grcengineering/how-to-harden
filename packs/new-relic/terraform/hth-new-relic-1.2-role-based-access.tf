# =============================================================================
# HTH New Relic Control 1.2: Role-Based Access
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/new-relic/#12-role-based-access
# =============================================================================
#
# NOTE: New Relic role and group management is available through the NerdGraph
# API but has limited Terraform provider support. This file creates an alert
# to detect privilege escalation as a compensating detective control.
#
# For declarative role management, use the NerdGraph API:
#   mutation { authorizationManagementGrantAccess(...) }

# HTH Guide Excerpt: begin terraform
# Alert policy for access control monitoring
resource "newrelic_alert_policy" "access_control_monitoring" {
  name                = "HTH: Access Control Monitoring"
  incident_preference = "PER_CONDITION"
}

# Detect role and group changes (privilege escalation / unauthorized access grants)
resource "newrelic_nrql_alert_condition" "role_changes" {
  account_id                   = var.newrelic_account_id
  policy_id                    = newrelic_alert_policy.access_control_monitoring.id
  type                         = "static"
  name                         = "HTH 1.2: Role or Group Change Detected"
  description                  = "Detects changes to user roles, groups, or access grants"
  enabled                      = true
  violation_time_limit_seconds = 86400

  nrql {
    query = "SELECT count(*) FROM NrAuditEvent WHERE actionIdentifier LIKE '%group%' OR actionIdentifier LIKE '%role%' OR actionIdentifier LIKE '%grant%' SINCE 5 minutes ago"
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
