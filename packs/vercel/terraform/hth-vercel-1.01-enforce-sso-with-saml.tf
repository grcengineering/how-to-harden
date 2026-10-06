# =============================================================================
# HTH Vercel Control 1.1: Enforce SSO with SAML
# Profile Level: L1 (Crawl)
# Frameworks: NIST IA-2(1), IA-8
# Source: https://howtoharden.com/guides/vercel/#11-enforce-sso-with-saml
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ONE vercel_team_config per team: the provider sends every attribute from its
# own plan on update, so a second resource for the same team would revert this
# one. Team-level settings from other controls (6.1) are merged in via locals.
resource "vercel_team_config" "hardened" {
  id = var.vercel_team_id

  # Enterprise, or Pro with the SAML add-on. Confirm IdP login works BEFORE
  # enforcing, or members are locked out.
  saml = {
    enforced = var.saml_enforced
  }

  # 6.1 (L2): team-wide Sensitive env var policy and IP privacy; null at L1
  # leaves the setting unmanaged.
  sensitive_environment_variable_policy = local.sensitive_env_policy
  hide_ip_addresses                     = local.hide_ip_addresses
  hide_ip_addresses_in_log_drains       = local.hide_ip_addresses
}

# HTH Guide Excerpt: end terraform
