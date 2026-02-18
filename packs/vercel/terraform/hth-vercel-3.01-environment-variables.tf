# =============================================================================
# HTH Vercel Control 3.1: Environment Variables
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-28
# Source: https://howtoharden.com/guides/vercel/#31-environment-variables
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

# HTH Guide Excerpt: end terraform
