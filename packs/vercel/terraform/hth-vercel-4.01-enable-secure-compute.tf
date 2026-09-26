# =============================================================================
# HTH Vercel Control 4.1: Enable Secure Compute
# Profile Level: L3 (Run)
# Frameworks: NIST SC-7, SC-8
# Source: https://howtoharden.com/guides/vercel/#41-enable-secure-compute
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L3: Create a Secure Compute network (Enterprise) ---
resource "vercel_network" "secure_compute" {
  count = var.profile_level >= 3 && var.secure_compute_enabled ? 1 : 0

  team_id = var.vercel_team_id
  name    = var.secure_compute_name
  region  = var.secure_compute_region
  cidr    = var.secure_compute_cidr
}

# --- Connecting a project to the network has no Terraform resource in the
#     vercel/vercel provider: do it in the project's Settings -> Networking. ---

# HTH Guide Excerpt: end terraform
