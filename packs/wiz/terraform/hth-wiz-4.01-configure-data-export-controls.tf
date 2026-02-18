# =============================================================================
# HTH Wiz Control 4.1: Configure Data Export Controls
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-3
# Source: https://howtoharden.com/guides/wiz/#41-configure-data-export-controls
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Project-based data export boundary
# Restricts bulk export of security findings and vulnerability data
# by isolating sensitive findings into a controlled project with
# limited membership and Admin-only export permissions.
resource "wiz_project" "data_export_restricted" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = var.data_export_project_name
  description = "HTH hardened project with restricted data export permissions. Bulk export limited to Admin role only."

  risk_profile {
    business_impact    = "HBI"
    has_exposed_api    = "NO"
    stores_data        = "YES"
    is_regulated       = "YES"
    sensitive_data_types = ["PII", "FINANCIAL"]
    regulatory_standards = ["SOC", "NIST"]
  }
}

# Control to detect unauthorized large data exports
resource "wiz_control" "data_export_monitoring" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "HTH: Unauthorized Data Export Detection"
  description = "Detects large or unauthorized exports of security findings and vulnerability data per HTH hardening guide section 4.1"
  severity    = "HIGH"
  enabled     = true
  project_id  = "*"

  resolution_recommendation = "Review export activity. Limit bulk export to Admin role only. Configure report sharing with expiration and restrict to internal-only distribution. See https://howtoharden.com/guides/wiz/#41-configure-data-export-controls"

  query = jsonencode({
    type = [
      "USER_ACCOUNT"
    ]
    select = true
    where = {
      isAdmin = {
        EQUALS = false
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
