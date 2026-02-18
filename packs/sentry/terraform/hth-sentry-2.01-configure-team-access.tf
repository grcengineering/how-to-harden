# =============================================================================
# HTH Sentry Control 2.1: Configure Team Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/sentry/#21-configure-team-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create teams for least-privilege access segmentation
resource "sentry_team" "teams" {
  for_each = var.teams

  organization = var.sentry_organization
  name         = each.value
  slug         = each.key
}
# HTH Guide Excerpt: end terraform
