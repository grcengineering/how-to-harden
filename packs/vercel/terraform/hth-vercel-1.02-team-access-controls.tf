# =============================================================================
# HTH Vercel Control 1.2: Team Access Controls
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/vercel/#12-team-access-controls
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "vercel_team_member" "members" {
  for_each = var.team_members

  team_id = var.vercel_team_id
  email   = each.value.email
  role    = each.value.role
}
# HTH Guide Excerpt: end terraform
