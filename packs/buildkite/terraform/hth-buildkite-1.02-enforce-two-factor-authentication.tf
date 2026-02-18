# =============================================================================
# HTH Buildkite Control 1.2: Enforce Two-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5 | NIST IA-2(1)
# Source: https://howtoharden.com/guides/buildkite/#12-enforce-two-factor-authentication
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "buildkite_organization" "hardened" {
  enforce_2fa = var.enforce_2fa
}
# HTH Guide Excerpt: end terraform
