# =============================================================================
# HTH PagerDuty Control 3.1: Configure Role-Based Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/pagerduty/#31-configure-role-based-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create teams for RBAC structure
# Teams enable granular access control and on-call management
resource "pagerduty_team" "teams" {
  for_each = { for idx, team in var.team_definitions : team.name => team }

  name        = each.value.name
  description = each.value.description
}

# Assign observer role to designated users (Business/Enterprise plans)
# Observer = read_only_user in PagerDuty API terminology
resource "pagerduty_user" "observer_role" {
  for_each = var.profile_level >= 2 ? toset(var.observer_user_ids) : toset([])

  # Note: pagerduty_user requires creating or importing users.
  # To change an existing user's role, use a data source + API call.
  # This resource pattern is for documentation; use the API script
  # or ClickOps to modify existing user roles.
  name  = "observer-placeholder-${each.key}"
  email = "observer-${each.key}@placeholder.local"
  role  = "read_only_user"

  lifecycle {
    ignore_changes = [name, email]
  }
}
# HTH Guide Excerpt: end terraform
