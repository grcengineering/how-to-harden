# =============================================================================
# HTH Auth0 Control 1.3: Enable Breached Password Detection
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5 | CIS 5.2
# Source: https://howtoharden.com/guides/auth0/#13-enable-breached-password-detection
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "auth0_attack_protection" "breached_password" {
  breached_password_detection {
    enabled                      = true
    method                       = "standard"
    shields                      = ["admin_notification", "block"]
    admin_notification_frequency = ["immediately"]

    pre_user_registration {
      shields = ["block"]
    }
  }
}
# HTH Guide Excerpt: end terraform
