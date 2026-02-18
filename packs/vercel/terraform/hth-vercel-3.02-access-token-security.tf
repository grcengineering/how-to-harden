# =============================================================================
# HTH Vercel Control 3.2: Access Token Security
# Profile Level: L1 (Baseline) + L2 enhancements
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/vercel/#32-access-token-security
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L2: IP allowlisting restricts API access to trusted networks ---
resource "vercel_project" "trusted_ips" {
  count = var.profile_level >= 2 && length(var.trusted_ip_addresses) > 0 ? 1 : 0

  name = data.vercel_project.current.name

  trusted_ips = {
    addresses       = var.trusted_ip_addresses
    deployment_type = "all_deployments"
    protection_mode = "trusted_ip_required"
  }
}

# --- L3: Automation bypass protection ---
resource "vercel_project" "automation_bypass" {
  count = var.profile_level >= 3 ? 1 : 0

  name = data.vercel_project.current.name

  # Disable automation bypass to prevent secret-based authentication circumvention
  protection_bypass_for_automation = false
}

# HTH Guide Excerpt: end terraform
