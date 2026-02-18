# =============================================================================
# HTH SendGrid Control 2.1: Use API Keys Instead of Passwords
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/sendgrid/#21-use-api-keys-instead-of-passwords
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "sendgrid_api_key" "managed" {
  for_each = var.api_keys

  name   = each.key
  scopes = each.value.scopes
}
# HTH Guide Excerpt: end terraform
