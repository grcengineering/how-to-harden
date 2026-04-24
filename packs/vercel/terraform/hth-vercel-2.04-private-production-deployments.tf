# =============================================================================
# HTH Vercel Control 2.4: Private Production Deployments (Advanced DP)
# Profile Level: L2 (Hardened) — requires Pro $150/mo Advanced DP add-on or Enterprise
# Frameworks: NIST AC-3, SC-7
# Source: https://howtoharden.com/guides/vercel/#24-private-production-deployments
# Reference: https://vercel.com/docs/deployment-protection
# Note: Advanced Deployment Protection has a 30-day minimum commitment on Pro.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L2: Protect ALL deployments including production domains ---
# This is the "All Deployments" scope — requires Enterprise or the $150/mo
# Advanced Deployment Protection add-on on Pro. Applies to production custom
# domains as well as preview/generated URLs, including Routing Middleware.
resource "vercel_project" "private_production" {
  count = var.profile_level >= 2 && var.private_production_deployments_enabled ? 1 : 0

  name    = data.vercel_project.current.name
  team_id = var.vercel_team_id

  vercel_authentication = {
    deployment_type = "all_deployments"
  }
}

# --- L2: Password-protect ALL deployments (prod + preview) ---
resource "vercel_project" "password_all_deployments" {
  count = var.profile_level >= 2 && var.private_production_deployments_enabled && var.preview_password != "" ? 1 : 0

  name    = data.vercel_project.current.name
  team_id = var.vercel_team_id

  password_protection = {
    deployment_type = "all_deployments"
    password        = var.preview_password
  }
}

# --- L3: Only Production via Trusted IPs (Enterprise only) ---
# Leave preview deployments publicly accessible but restrict production domains
# to corporate egress IPs only.
resource "vercel_project" "production_only_trusted_ips" {
  count = var.profile_level >= 3 && var.production_only_trusted_ips_enabled && length(var.trusted_ip_addresses) > 0 ? 1 : 0

  name    = data.vercel_project.current.name
  team_id = var.vercel_team_id

  trusted_ips = {
    addresses       = var.trusted_ip_addresses
    deployment_type = "production"
    protection_mode = "trusted_ip_required"
  }
}

# HTH Guide Excerpt: end terraform
