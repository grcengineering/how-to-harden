# =============================================================================
# HTH Vercel Control 3.1: Enable WAF with Managed Rulesets
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-7, SI-3
# Source: https://howtoharden.com/guides/vercel/#31-enable-waf-with-managed-rulesets
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L2: Enable Web Application Firewall with OWASP managed rulesets ---
resource "vercel_firewall_config" "waf" {
  project_id = var.project_id
  team_id    = var.vercel_team_id
  enabled    = var.firewall_enabled

  managed_rulesets = {
    owasp = {
      active = true
      action = var.waf_owasp_action
    }
  }

  # Note: Bot Protection and AI Bot rulesets are managed via
  # Vercel dashboard or API (not yet in Terraform provider)
}

# HTH Guide Excerpt: end terraform
