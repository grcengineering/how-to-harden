# =============================================================================
# HTH Vercel Control 10.4: Treat Container Registry Public Access as a
# Change-Controlled Action
# Profile Level: L1 (Crawl)
# Frameworks: NIST AC-3, AC-21, CM-3, SA-12
# Source: https://howtoharden.com/guides/vercel/#104-treat-container-registry-public-access-as-a-change-controlled-action
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Keep every Vercel Container Registry repository PRIVATE. Making one
#     public becomes a reviewed change to this file, not a dashboard toggle.
#     Import existing repositories before the first apply:
#       terraform import 'vercel_vcr_repository.private["<name>"]' <team_id>/<project_id>/<name>
resource "vercel_vcr_repository" "private" {
  for_each = var.vcr_repositories

  project_id = var.project_id
  team_id    = var.vercel_team_id
  name       = each.value
  public     = false
}

# HTH Guide Excerpt: end terraform
