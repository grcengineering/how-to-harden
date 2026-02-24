# =============================================================================
# HTH Vercel Control 6.1: Environment Variable Security
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-28, SC-12
# Source: https://howtoharden.com/guides/vercel/#61-environment-variable-security
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Configure environment variables with sensitivity flags ---
resource "vercel_project_environment_variable" "secrets" {
  for_each = var.environment_variables

  project_id = var.project_id
  team_id    = var.vercel_team_id
  key        = each.key
  value      = each.value.value
  target     = each.value.target
  sensitive  = each.value.sensitive
}

# --- L2: Enforce sensitive environment variable policy at team level ---
resource "vercel_team_config" "sensitive_env_policy" {
  count = var.profile_level >= 2 ? 1 : 0

  id = var.vercel_team_id

  sensitive_environment_variable_policy = "on"
}

# --- L2: Hide IP addresses in observability (privacy hardening) ---
resource "vercel_team_config" "hide_ips" {
  count = var.profile_level >= 2 ? 1 : 0

  id = var.vercel_team_id

  hide_ip_addresses               = true
  hide_ip_addresses_in_log_drains = true
}

# HTH Guide Excerpt: end terraform
