# =============================================================================
# HTH Vercel Control 3.2: Configure IP Blocking and Rate Limiting
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-5, SI-4
# Source: https://howtoharden.com/guides/vercel/#32-configure-ip-blocking-and-rate-limiting
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Configure firewall with IP blocking rules ---
resource "vercel_firewall_config" "ip_blocking" {
  project_id = var.project_id
  team_id    = var.vercel_team_id
  enabled    = true

  # IP blocking rules
  dynamic "rules" {
    for_each = var.blocked_ip_addresses
    content {
      name      = rules.value.note != "" ? rules.value.note : "Block ${rules.value.value}"
      action    = "deny"
      active    = true
      condition_group = [{
        conditions = [{
          type  = "ip_address"
          op    = "eq"
          value = rules.value.value
        }]
      }]
    }
  }

  # L2: Rate limiting rules for sensitive endpoints
  dynamic "rules" {
    for_each = var.profile_level >= 2 ? var.rate_limit_rules : []
    content {
      name      = rules.value.name
      action    = "rate_limit"
      active    = true
      rate_limit = {
        limit  = rules.value.limit
        window = rules.value.window
        action = rules.value.follow_up_action
      }
      condition_group = [{
        conditions = [{
          type  = "path"
          op    = "pre"
          value = rules.value.path
        }]
      }]
    }
  }
}

# HTH Guide Excerpt: end terraform
