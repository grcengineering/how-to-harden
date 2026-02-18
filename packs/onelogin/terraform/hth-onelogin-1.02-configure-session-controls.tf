# =============================================================================
# HTH OneLogin Control 1.2: Configure Session Controls
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.2, NIST AC-12
# Source: https://howtoharden.com/guides/onelogin/#12-configure-session-controls
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Session timeout and idle controls for all users
resource "onelogin_user_security_policy" "session_controls" {
  name = "HTH Session Controls"

  # Session timeout (minutes)
  session_timeout = var.session_timeout_minutes

  # Idle session timeout (minutes)
  inactivity_timeout = var.idle_timeout_minutes
}

# L2+ stricter session controls with shorter timeouts
resource "onelogin_user_security_policy" "session_controls_hardened" {
  count = var.profile_level >= 2 ? 1 : 0

  name = "HTH Session Controls - Hardened"

  session_timeout    = min(var.session_timeout_minutes, 240)
  inactivity_timeout = min(var.idle_timeout_minutes, 5)
}

# L3 maximum security: shortest possible session windows
resource "onelogin_user_security_policy" "session_controls_max" {
  count = var.profile_level >= 3 ? 1 : 0

  name = "HTH Session Controls - Maximum Security"

  session_timeout    = 60
  inactivity_timeout = 5
}
# HTH Guide Excerpt: end terraform
