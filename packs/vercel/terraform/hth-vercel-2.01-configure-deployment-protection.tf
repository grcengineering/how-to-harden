# =============================================================================
# HTH Vercel Control 2.1: Configure Deployment Protection
# Profile Level: L1 (Baseline) + L2/L3 enhancements
# Frameworks: NIST CM-3, AC-3
# Source: https://howtoharden.com/guides/vercel/#21-configure-deployment-protection
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

  # Block deployments from forked repositories
  git_fork_protection = var.git_fork_protection_enabled

  # Disable preview deployments for tighter control (L2+)
  preview_deployments_disabled = var.profile_level >= 2

  # Enable skew protection to prevent version mismatches (L2+)
  skew_protection = var.profile_level >= 2 ? "12 hours" : null

  # Prioritize production builds over preview builds
  prioritise_production_builds = true

  # Git provider security options
  git_provider_options = {
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

# --- L3: Trusted IPs restrict access to known networks (Enterprise) ---
resource "vercel_project" "trusted_ips" {
  count = var.profile_level >= 3 && length(var.trusted_ip_addresses) > 0 ? 1 : 0

  name = data.vercel_project.current.name

  trusted_ips = {
    addresses       = var.trusted_ip_addresses
    deployment_type = "all_deployments"
    protection_mode = "trusted_ip_required"
  }
}

# --- L3: Disable automation bypass ---
resource "vercel_project" "automation_bypass" {
  count = var.profile_level >= 3 ? 1 : 0

  name = data.vercel_project.current.name

  protection_bypass_for_automation = false
}

# --- Data source to read current project configuration ---
data "vercel_project" "current" {
  name    = null
  id      = var.project_id
  team_id = var.vercel_team_id
}

# HTH Guide Excerpt: end terraform
