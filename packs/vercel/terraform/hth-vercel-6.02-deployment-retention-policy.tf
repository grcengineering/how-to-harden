# =============================================================================
# HTH Vercel Control 6.2: Deployment Retention Policy
# Profile Level: L2 (Walk)
# Frameworks: NIST SI-12
# Source: https://howtoharden.com/guides/vercel/#62-deployment-retention-policy
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L2: Limit how long old deployments stay reachable ---
resource "vercel_project_deployment_retention" "policy" {
  count = var.profile_level >= 2 ? 1 : 0

  project_id            = var.project_id
  team_id               = var.vercel_team_id
  expiration_preview    = var.retention_preview
  expiration_production = var.retention_production
  expiration_canceled   = var.retention_canceled
  expiration_errored    = var.retention_errored
}

# HTH Guide Excerpt: end terraform
