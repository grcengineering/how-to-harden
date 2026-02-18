# =============================================================================
# HTH Wiz Control 1.2: Implement Role-Based Access Control
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/wiz/#12-implement-role-based-access-control
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Map SAML groups to Wiz roles with least-privilege access
# Role strategy:
#   - Admin:            Full platform access (limit to 2-3 users)
#   - Security Analyst: View issues, run queries, NO settings
#   - Developer:        View assigned projects only
#   - Auditor:          Read-only access, reports
#   - Integration:      API access for specific use cases
resource "wiz_saml_group_mapping" "rbac" {
  count = var.saml_idp_id != "" && length(var.rbac_group_mappings) > 0 ? 1 : 0

  saml_idp_id = var.saml_idp_id

  dynamic "group_mapping" {
    for_each = var.rbac_group_mappings
    content {
      provider_group_id = group_mapping.value.provider_group_id
      role              = group_mapping.value.role
      projects          = length(group_mapping.value.projects) > 0 ? group_mapping.value.projects : null
    }
  }
}

# Create project-based access boundaries for team segregation
resource "wiz_project" "team_projects" {
  for_each = var.profile_level >= 1 ? toset(["security", "development", "audit"]) : toset([])

  name        = "hth-${each.key}"
  description = "HTH hardened project for ${each.key} team - least-privilege boundary"

  risk_profile {
    business_impact = each.key == "security" ? "HBI" : "MBI"
  }
}
# HTH Guide Excerpt: end terraform
