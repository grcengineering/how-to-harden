# =============================================================================
# HTH Vercel Control 8.1: Configure Log Drains for SIEM
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-6
# Source: https://howtoharden.com/guides/vercel/#81-configure-log-drains-for-siem
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Configure log drain to forward deployment and runtime logs ---
resource "vercel_log_drain" "security_logging" {
  count = var.log_drain_endpoint != "" ? 1 : 0

  name            = "hth-security-log-drain"
  team_id         = var.vercel_team_id
  delivery_format = "json"
  endpoint        = var.log_drain_endpoint
  environments    = var.log_drain_environments
  sources         = var.log_drain_sources
  secret          = var.log_drain_secret != "" ? var.log_drain_secret : null
}

# --- L2: Separate firewall log drain for WAF activity ---
resource "vercel_log_drain" "firewall_logging" {
  count = var.profile_level >= 2 && var.log_drain_endpoint != "" ? 1 : 0

  name            = "hth-firewall-log-drain"
  team_id         = var.vercel_team_id
  delivery_format = "json"
  endpoint        = var.log_drain_endpoint
  environments    = ["production", "preview"]
  sources         = ["firewall"]
  secret          = var.log_drain_secret != "" ? var.log_drain_secret : null
}

# HTH Guide Excerpt: end terraform
