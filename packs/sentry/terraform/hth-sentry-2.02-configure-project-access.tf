# =============================================================================
# HTH Sentry Control 2.2: Configure Project Access
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/sentry/#22-configure-project-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create projects with team-scoped access (L2+ only)
# Each project is assigned to specific teams, enforcing least-privilege
# access boundaries between functional groups.
resource "sentry_project" "projects" {
  for_each = var.profile_level >= 2 ? var.projects : {}

  organization = var.sentry_organization
  teams        = each.value.teams
  name         = each.value.name
  slug         = each.key
  platform     = each.value.platform

  # Disable default alert rules -- security alerts are managed separately
  default_rules = false

  # Auto-resolve stale issues after 72 hours to reduce noise
  resolve_age = 72

  depends_on = [sentry_team.teams]
}
# HTH Guide Excerpt: end terraform
