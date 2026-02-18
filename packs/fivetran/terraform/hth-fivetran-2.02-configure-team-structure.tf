# =============================================================================
# HTH Fivetran Control 2.2: Configure Team Structure
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/fivetran/#22-configure-team-structure
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create teams for granular access control (L2+)
# Teams enable logical grouping of users with shared connector/destination access
resource "fivetran_team" "teams" {
  for_each = var.profile_level >= 2 ? var.teams : {}

  name        = each.value.name
  description = each.value.description
  role        = "Team Member"
}

# Assign users to teams (L2+)
resource "fivetran_team_user_membership" "memberships" {
  for_each = var.profile_level >= 2 ? var.team_user_memberships : {}

  team_id = fivetran_team.teams[each.key].id

  dynamic "user" {
    for_each = toset(each.value)
    content {
      user_id = user.value
      role    = "Team Member"
    }
  }
}
# HTH Guide Excerpt: end terraform
