# =============================================================================
# HTH Okta Control 4.1: Session Timeouts
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-12, SC-23, DISA STIG V-273206
# Source: https://howtoharden.com/guides/okta/#41-configure-session-timeouts
# =============================================================================

# Global session policy with hardened timeout values
resource "okta_policy_signon" "session_timeouts" {
  name        = "Hardened Session Timeouts"
  status      = "ACTIVE"
  description = "Session timeout configuration per HTH hardening guide"
  priority    = 3
}

resource "okta_policy_rule_signon" "session_timeout_rule" {
  policy_id          = okta_policy_signon.session_timeouts.id
  name               = "Enforce Session Timeouts"
  status             = "ACTIVE"
  priority           = 1
  access             = "ALLOW"
  mfa_required       = true
  mfa_prompt         = "SESSION"
  session_lifetime   = var.session_max_lifetime_minutes
  session_idle       = var.session_max_idle_minutes
  session_persistent = false
}
