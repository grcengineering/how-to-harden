# =============================================================================
# HTH Wiz Control 3.2: API Access Monitoring
# Profile Level: L2 (Hardened)
# Frameworks: NIST AU-6
# Source: https://howtoharden.com/guides/wiz/#32-api-access-monitoring
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Scheduled report for API access audit
# Runs at the configured interval to detect anomalous API usage patterns
# such as unusual query volumes, new source IPs, or off-hours access.
resource "wiz_report_graph_query" "api_access_audit" {
  count = var.profile_level >= 2 ? 1 : 0

  name               = var.api_audit_report_name
  project_id         = "*"
  run_interval_hours = var.api_audit_interval_hours

  query = jsonencode({
    type = [
      "USER_ACCOUNT"
    ]
    select = true
    where = {
      type = {
        EQUALS = [
          "SERVICE"
        ]
      }
    }
  })
}

# Control to detect service accounts with overly broad scopes
resource "wiz_control" "overprivileged_service_accounts" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "HTH: Overprivileged Service Accounts"
  description = "Detects Wiz service accounts with administrative or overly broad API scopes per HTH hardening guide section 3.2"
  severity    = "MEDIUM"
  enabled     = true
  project_id  = "*"

  resolution_recommendation = "Review and reduce service account scopes to the minimum required for each integration. See https://howtoharden.com/guides/wiz/#32-api-access-monitoring"

  query = jsonencode({
    type = [
      "USER_ACCOUNT"
    ]
    select = true
    where = {
      type = {
        EQUALS = [
          "SERVICE"
        ]
      }
      isAdmin = {
        EQUALS = true
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
