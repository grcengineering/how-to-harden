# =============================================================================
# HTH Vercel Control 3.1: Enable WAF with Managed Rulesets
# Profile Level: L2 (Walk)
# Frameworks: NIST SC-7, SI-3
# Source: https://howtoharden.com/guides/vercel/#31-enable-waf-with-managed-rulesets
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ONE vercel_firewall_config per project, created only when this pack is asked
# to manage the firewall. The provider PUTs the WHOLE firewall config on create:
# every custom rule, IP block and managed-ruleset setting the project has now is
# replaced by what is declared here, including rules made in the dashboard and
# the hth-* rules the 3.3 and 9.1 API packs insert. With the defaults nothing is
# managed, so an apply leaves the project's firewall as it is. The 3.2 IP-block
# and rate-limit rules are merged in here from locals.
locals {
  firewall_managed = var.firewall_enabled || length(local.firewall_ip_rules) > 0 || length(local.firewall_rate_limit_rules) > 0
}

resource "vercel_firewall_config" "project" {
  count = local.firewall_managed ? 1 : 0

  project_id = var.project_id
  team_id    = var.vercel_team_id
  enabled    = true

  # L2: OWASP core ruleset (Enterprise), one action per rule group
  dynamic "managed_rulesets" {
    for_each = var.profile_level >= 2 ? [1] : []
    content {
      owasp {
        xss  = { action = var.waf_owasp_action, active = true }
        sqli = { action = var.waf_owasp_action, active = true }
        rce  = { action = var.waf_owasp_action, active = true }
        lfi  = { action = var.waf_owasp_action, active = true }
        rfi  = { action = var.waf_owasp_action, active = true }
        gen  = { action = var.waf_owasp_action, active = true }
      }
    }
  }

  # 3.2 (L2): rate-limit rules
  dynamic "rules" {
    for_each = length(local.firewall_rate_limit_rules) > 0 ? [1] : []
    content {
      dynamic "rule" {
        for_each = local.firewall_rate_limit_rules
        content {
          name            = rule.value.name
          active          = true
          action          = rule.value.action
          condition_group = rule.value.condition_group
        }
      }
    }
  }

  # 3.2 (L1): IP blocking
  dynamic "ip_rules" {
    for_each = length(local.firewall_ip_rules) > 0 ? [1] : []
    content {
      dynamic "rule" {
        for_each = local.firewall_ip_rules
        content {
          action   = rule.value.action
          hostname = rule.value.hostname
          ip       = rule.value.ip
          notes    = rule.value.notes
        }
      }
    }
  }

  lifecycle {
    precondition {
      condition     = length(var.blocked_ip_addresses) == 0 || var.firewall_hostname != ""
      error_message = "Set firewall_hostname: every IP-block rule needs the hostname it applies to."
    }
    precondition {
      condition     = var.firewall_replace_existing_config
      error_message = "This resource replaces the project's WHOLE firewall configuration, including custom rules and IP blocks added in the dashboard or by the 3.3/9.1 API packs. Export the active config first (GET /v1/security/firewall/config/active), declare every rule to keep, then set firewall_replace_existing_config = true."
    }
  }
}

# HTH Guide Excerpt: end terraform
