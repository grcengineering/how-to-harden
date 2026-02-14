# =============================================================================
# HTH Okta Control 4.2: Disable Session Persistence
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-23, DISA STIG V-273206
# Source: https://howtoharden.com/guides/okta/#42-disable-session-persistence
# =============================================================================

# Global signon policy that disables persistent sessions
# Prevents session cookies from surviving browser restarts
resource "okta_policy_signon" "disable_session_persistence" {
  count = var.profile_level >= 2 ? 1 : 0

  name        = "Disable Session Persistence"
  status      = "ACTIVE"
  description = "Disables Remember Me and persistent session cookies to reduce session hijacking risk"
  priority    = 2
}

# Rule enforcing non-persistent sessions with strict timeouts
resource "okta_policy_rule_signon" "no_persistent_sessions" {
  count = var.profile_level >= 2 ? 1 : 0

  policy_id          = okta_policy_signon.disable_session_persistence[0].id
  name               = "No Persistent Sessions"
  status             = "ACTIVE"
  priority           = 1
  access             = "ALLOW"
  mfa_required       = true
  mfa_prompt         = "SESSION"
  session_lifetime   = 480
  session_idle       = 30
  session_persistent = false
}
