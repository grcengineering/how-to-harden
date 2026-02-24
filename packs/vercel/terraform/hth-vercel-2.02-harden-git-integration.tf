# =============================================================================
# HTH Vercel Control 2.2: Harden Git Integration
# Profile Level: L1 (Baseline) + L2 enhancements
# Frameworks: NIST CM-7, SA-10
# Source: https://howtoharden.com/guides/vercel/#22-harden-git-integration
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Git fork protection prevents unauthorized fork deployments ---
# Note: git_fork_protection is configured in hth-vercel-2.01 as part of
# the vercel_project resource.

# --- L2: Require verified (signed) commits for deployments ---
resource "vercel_project" "verified_commits" {
  count = var.profile_level >= 2 && var.require_verified_commits ? 1 : 0

  name = data.vercel_project.current.name

  git_provider_options = {
    require_verified_commits = true
  }
}

# HTH Guide Excerpt: end terraform
