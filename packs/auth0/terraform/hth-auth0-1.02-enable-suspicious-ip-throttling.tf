# =============================================================================
# HTH Auth0 Control 1.2: Enable Suspicious IP Throttling
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-4 | CIS 4.10
# Source: https://howtoharden.com/guides/auth0/#12-enable-suspicious-ip-throttling
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "auth0_attack_protection" "suspicious_ip" {
  suspicious_ip_throttling {
    enabled   = true
    shields   = ["admin_notification", "block"]
    allowlist = []

    pre_login {
      max_attempts = 100
      rate         = 864000
    }

    pre_user_registration {
      max_attempts = 50
      rate         = 1200000
    }
  }
}
# HTH Guide Excerpt: end terraform
