# =============================================================================
# HTH Vercel Control 6.1: Environment Variable Security
# Profile Level: L1 (Crawl)
# Frameworks: NIST SC-28, SC-12
# Source: https://howtoharden.com/guides/vercel/#61-environment-variable-security
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Configure environment variables with sensitivity flags ---
# for_each cannot iterate a sensitive value; the variable NAMES are not secret.
resource "vercel_project_environment_variable" "secrets" {
  for_each = nonsensitive(toset(keys(var.environment_variables)))

  project_id = var.project_id
  team_id    = var.vercel_team_id
  key        = each.key
  value      = var.environment_variables[each.key].value
  target     = var.environment_variables[each.key].target
  sensitive  = var.environment_variables[each.key].sensitive
}

# --- L2: team-level policy, applied through vercel_team_config.hardened
#     (hth-vercel-1.01) so only one resource manages the team ---
locals {
  # Enforce Sensitive environment variables team-wide. The provider marks this
  # attribute deprecated in 5.x without a replacement.
  sensitive_env_policy = var.profile_level >= 2 ? "on" : null

  # Hide IP addresses in observability and in Drains (privacy hardening)
  hide_ip_addresses = var.profile_level >= 2 ? true : null
}

# HTH Guide Excerpt: end terraform
