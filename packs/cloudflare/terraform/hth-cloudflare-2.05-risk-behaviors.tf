# =============================================================================
# HTH Cloudflare Control 2.5: Gate Access Policies on User Risk Score
# Profile Level: L3 (Run)
# Frameworks: NIST AC-2(12) | CIS 13.1
# Source: https://howtoharden.com/guides/cloudflare/#25-gate-access-policies-on-user-risk-score
#
# Enterprise plans only. Every predefined risk behavior is disabled by
# default. This pack reads the account's own behavior list and enables each
# one at its current risk level, except those named in
# var.risk_behaviors_left_disabled -- so no behavior key is hard-coded.
# =============================================================================

# HTH Guide Excerpt: begin terraform
data "cloudflare_zero_trust_risk_behavior" "current" {
  account_id = var.cloudflare_account_id
}

resource "cloudflare_zero_trust_risk_behavior" "enabled" {
  account_id = var.cloudflare_account_id

  behaviors = {
    for key, behavior in data.cloudflare_zero_trust_risk_behavior.current.behaviors :
    key => {
      enabled    = !contains(var.risk_behaviors_left_disabled, key)
      risk_level = behavior.risk_level
    }
  }
}
# HTH Guide Excerpt: end terraform
