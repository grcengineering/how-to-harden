# =============================================================================
# HTH Vercel Control 4.1: Audit Log & Monitoring
# Profile Level: L1 (Baseline) + L2 enhancements
# Frameworks: NIST AU-2, AU-3
# Source: https://howtoharden.com/guides/vercel/#41-audit-log-enterprise
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Configure log drain to forward deployment and runtime logs ---
resource "vercel_log_drain" "security_logging" {
  count = var.log_drain_endpoint != "" ? 1 : 0

  name             = "hth-security-log-drain"
  team_id          = var.vercel_team_id
  delivery_format  = "json"
  endpoint         = var.log_drain_endpoint
  environments     = var.log_drain_environments
  sources          = var.log_drain_sources
  secret           = var.log_drain_secret != "" ? var.log_drain_secret : null
}

# --- L2: Add firewall logs to log drain sources ---
resource "vercel_log_drain" "firewall_logging" {
  count = var.profile_level >= 2 && var.log_drain_endpoint != "" ? 1 : 0

  name             = "hth-firewall-log-drain"
  team_id          = var.vercel_team_id
  delivery_format  = "json"
  endpoint         = var.log_drain_endpoint
  environments     = ["production", "preview"]
  sources          = ["firewall"]
  secret           = var.log_drain_secret != "" ? var.log_drain_secret : null
}

# --- L2: Enable Web Application Firewall ---
resource "vercel_firewall_config" "waf" {
  count = var.profile_level >= 2 && var.firewall_enabled ? 1 : 0

  project_id = var.project_id
  team_id    = var.vercel_team_id
  enabled    = true

  managed_rulesets = {
    owasp = {
      active = true
      action = "deny"
    }
  }
}

# --- L2: Hide IP addresses in observability (privacy hardening) ---
resource "vercel_team_config" "hide_ips" {
  count = var.profile_level >= 2 ? 1 : 0

  id = var.vercel_team_id

  hide_ip_addresses              = true
  hide_ip_addresses_in_log_drains = true
}

# HTH Guide Excerpt: end terraform
