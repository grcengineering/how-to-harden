# =============================================================================
# HTH Vercel Control 1.1: Enforce SSO with SAML
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-2(1), IA-8
# Source: https://howtoharden.com/guides/vercel/#11-enforce-sso-with-saml
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "vercel_team_config" "saml_enforcement" {
  id = var.vercel_team_id

  saml = {
    enforced = var.saml_enforced
  }
}
# HTH Guide Excerpt: end terraform
