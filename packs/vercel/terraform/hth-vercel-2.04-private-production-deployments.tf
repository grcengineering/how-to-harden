# =============================================================================
# HTH Vercel Control 2.4: Private Production Deployments (Advanced DP)
# Profile Level: L2 (Walk) — requires Pro $150/mo Advanced DP add-on or Enterprise
# Frameworks: NIST AC-3, SC-7
# Source: https://howtoharden.com/guides/vercel/#24-private-production-deployments
# Reference: https://vercel.com/docs/deployment-protection
# Note: Advanced Deployment Protection has a 30-day minimum commitment on Pro.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Applied through vercel_project.hardened (hth-vercel-2.01).
locals {
  private_production = var.profile_level >= 2 && var.private_production_deployments_enabled

  # L2: "all_deployments" also covers production custom domains (paid scope);
  # otherwise the current Standard Protection scope ("standard_protection_new")
  # applies. The provider's "standard_protection" and "only_preview_deployments"
  # are the (Legacy) scopes the guide says to migrate away from.
  vercel_authentication_scope = local.private_production ? "all_deployments" : "standard_protection_new"
  password_protection_scope   = local.private_production ? "all_deployments" : "standard_protection_new"

  # L3: Trusted IPs on production domains only, previews stay reachable (Enterprise)
  trusted_ips_scope = var.production_only_trusted_ips_enabled ? "only_production_deployments" : "all_deployments"
}

# HTH Guide Excerpt: end terraform
