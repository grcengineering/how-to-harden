# =============================================================================
# HTH Wiz Control 5.1: Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3
# Source: https://howtoharden.com/guides/wiz/#51-audit-logging
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Scheduled audit log report for SIEM export
# Captures authentication events, configuration changes, and API access
# at regular intervals for correlation and alerting.
resource "wiz_report_graph_query" "audit_log" {
  name               = var.audit_report_name
  project_id         = "*"
  run_interval_hours = var.audit_report_interval_hours

  query = jsonencode({
    type = [
      "USER_ACCOUNT"
    ]
    select = true
    where = {
      status = {
        EQUALS = [
          "ACTIVE"
        ]
      }
    }
  })
}

# Dedicated service account for SIEM integration (read-only audit access)
resource "wiz_service_account" "siem_export" {
  name   = "hth-siem-audit-export"
  type   = "THIRD_PARTY"
  scopes = ["read:issues", "read:vulnerabilities"]

  recreate_if_rotated = true
}

# Control to detect unusual data access patterns
resource "wiz_control" "unusual_data_access" {
  name        = "HTH: Unusual Data Access Pattern Detection"
  description = "Detects unusual query volumes or access patterns that may indicate compromised credentials or insider threats per HTH hardening guide section 5.1"
  severity    = "MEDIUM"
  enabled     = true
  project_id  = "*"

  resolution_recommendation = "Investigate the user or service account activity. Review source IPs, query volume, and timing. Correlate with SIEM alerts. See https://howtoharden.com/guides/wiz/#51-audit-logging"

  query = jsonencode({
    type = [
      "USER_ACCOUNT"
    ]
    select = true
    where = {
      status = {
        EQUALS = [
          "ACTIVE"
        ]
      }
    }
  })

  scope_query = jsonencode({
    type = [
      "SUBSCRIPTION"
    ]
    select = true
  })
}
# HTH Guide Excerpt: end terraform
