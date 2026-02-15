# =============================================================================
# HTH GitHub Control 1.01: Enforce Two-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1), IA-2(2)
# Source: https://howtoharden.com/guides/github/#11-enforce-two-factor-authentication
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "github_organization_settings" "security" {
  billing_email                      = var.github_organization
  two_factor_requirement             = true
}
# HTH Guide Excerpt: end terraform
