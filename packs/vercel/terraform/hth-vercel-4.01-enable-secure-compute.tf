# =============================================================================
# HTH Vercel Control 4.1: Enable Secure Compute
# Profile Level: L3 (Maximum Security)
# Frameworks: NIST SC-7, SC-8
# Source: https://howtoharden.com/guides/vercel/#41-enable-secure-compute
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L3: Create Secure Compute network with static IPs ---
resource "vercel_network" "secure_compute" {
  count = var.profile_level >= 3 && var.secure_compute_enabled ? 1 : 0

  team_id = var.vercel_team_id
  name    = var.secure_compute_name
  region  = var.secure_compute_region
}

# --- L3: Link project to Secure Compute network ---
resource "vercel_network_project_link" "secure_link" {
  count = var.profile_level >= 3 && var.secure_compute_enabled ? 1 : 0

  team_id    = var.vercel_team_id
  network_id = vercel_network.secure_compute[0].id
  project_id = var.project_id
}

# HTH Guide Excerpt: end terraform
