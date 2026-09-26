# =============================================================================
# HTH Vercel Control 3.2: Configure IP Blocking and Rate Limiting
# Profile Level: L1 (Crawl)
# Frameworks: NIST SC-5, SI-4
# Source: https://howtoharden.com/guides/vercel/#32-configure-ip-blocking-and-rate-limiting
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Applied through vercel_firewall_config.project (hth-vercel-3.01).
locals {
  # L1: block known-bad IPs/ranges (ip_rules.rule requires a hostname)
  firewall_ip_rules = [for ip in var.blocked_ip_addresses : {
    action   = "deny"
    hostname = var.firewall_hostname
    ip       = ip.value
    notes    = ip.note != "" ? ip.note : "Block ${ip.value}"
  }]

  # L2: rate-limit sensitive paths (algo and keys are required)
  firewall_rate_limit_rules = var.profile_level >= 2 ? [for r in var.rate_limit_rules : {
    name = r.name
    action = {
      action = "rate_limit"
      rate_limit = {
        algo   = "fixed_window"
        keys   = ["ip"]
        limit  = r.limit
        window = r.window
        action = r.follow_up_action
      }
    }
    condition_group = [{ conditions = [{ type = "path", op = "pre", value = r.path }] }]
  }] : []
}

# HTH Guide Excerpt: end terraform
