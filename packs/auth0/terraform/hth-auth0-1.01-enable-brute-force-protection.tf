# =============================================================================
# HTH Auth0 Control 1.1: Enable Brute Force Protection
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-7, SI-4 | CIS 4.10
# Source: https://howtoharden.com/guides/auth0/#11-enable-brute-force-protection
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "auth0_attack_protection" "brute_force" {
  brute_force_protection {
    enabled      = true
    max_attempts = 5
    mode         = "count_per_identifier_and_ip"
    shields      = ["block", "user_notification"]
    allowlist    = []
  }
}
# HTH Guide Excerpt: end terraform
