# =============================================================================
# HTH Vercel Control 2.1: Secure Deployments
# Profile Level: L1 (Baseline) + L2 enhancements
# Frameworks: NIST CM-3
# Source: https://howtoharden.com/guides/vercel/#21-secure-deployments
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Production branch protection and deployment settings ---
resource "vercel_project" "hardened" {
  name = data.vercel_project.current.name

  git_repository = var.git_repository != "" ? {
    type              = var.git_provider
    repo              = var.git_repository
    production_branch = var.production_branch
  } : null

  # Require team member approval for production deployments
  git_fork_protection = var.git_fork_protection_enabled

  # Disable preview deployments for tighter control (L2+)
  preview_deployments_disabled = var.profile_level >= 2

  # Enable skew protection to prevent version mismatches
  skew_protection = var.profile_level >= 2 ? "12 hours" : null

  # Prioritise production builds over preview builds
  prioritise_production_builds = true

  # Git provider security options
  git_provider_options = {
    # Only deploy commits from verified sources
    create_deployments = var.profile_level >= 2 ? "only-production" : "enabled"
  }

  # Vercel Authentication on preview deployments (L1)
  vercel_authentication = {
    deployment_type = "all_deployments"
  }
}

# --- L2: Password-protect preview deployments ---
resource "vercel_project" "preview_password_protection" {
  count = var.profile_level >= 2 && var.preview_password != "" ? 1 : 0

  name = data.vercel_project.current.name

  password_protection = {
    deployment_type = "preview"
    password        = var.preview_password
  }
}

# --- Data source to read current project configuration ---
data "vercel_project" "current" {
  name    = null
  id      = var.project_id
  team_id = var.vercel_team_id
}

# HTH Guide Excerpt: end terraform
