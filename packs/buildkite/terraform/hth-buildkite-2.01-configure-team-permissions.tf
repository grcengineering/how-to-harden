# =============================================================================
# HTH Buildkite Control 2.1: Configure Team Permissions
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4 | NIST AC-6
# Source: https://howtoharden.com/guides/buildkite/#21-configure-team-permissions
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create teams with least-privilege defaults
resource "buildkite_team" "teams" {
  for_each = var.teams

  name                         = each.key
  description                  = each.value.description
  privacy                      = each.value.privacy
  default_team                 = each.value.default_team
  default_member_role          = each.value.default_member_role
  members_can_create_pipelines = each.value.members_can_create_pipelines
}
# HTH Guide Excerpt: end terraform
