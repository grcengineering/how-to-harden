# =============================================================================
# HTH Vercel Control 2.2: Harden Git Integration
# Profile Level: L1 (Crawl) + L2 enhancements
# Frameworks: NIST CM-7, SA-10
# Source: https://howtoharden.com/guides/vercel/#22-harden-git-integration
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Applied through vercel_project.hardened (hth-vercel-2.01).
locals {
  # L1: block deployments from forked repositories without approval
  git_fork_protection = var.git_fork_protection_enabled

  # L2: Git pushes create production deployments only (no PR previews).
  # In provider 5.x git_provider_options.create_deployments is a bool that
  # switches ALL Git deployments on or off, so it is left unmanaged here.
  # Below L2 the project's current setting is kept: planning false would
  # re-enable preview deployments on a project that had them off.
  preview_deployments_disabled = var.profile_level >= 2 || data.vercel_project.current.preview_deployments_disabled == true

  git_provider_options = {
    # L2: require verified (signed) commits. Never switched off by this pack.
    require_verified_commits = (var.profile_level >= 2 && var.require_verified_commits) || try(data.vercel_project.current.git_provider_options.require_verified_commits, false) == true
  }
}

# HTH Guide Excerpt: end terraform
