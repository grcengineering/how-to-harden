# =============================================================================
# HTH Auth0 Control 1.4: Configure Bot Detection
# Profile Level: L2 (Hardened)
# Frameworks: NIST SI-4 | CIS 4.10
# Source: https://howtoharden.com/guides/auth0/#14-configure-bot-detection
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "auth0_attack_protection" "bot_detection" {
  bot_detection {
    bot_detection_level             = "medium"
    challenge_password_policy       = "when_risky"
    challenge_passwordless_policy   = "when_risky"
    challenge_password_reset_policy = "when_risky"
    monitoring_mode_enabled         = false
    allowlist                       = []
  }
}
# HTH Guide Excerpt: end terraform
