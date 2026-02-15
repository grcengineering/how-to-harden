# =============================================================================
# HTH Okta Control 1.9: Audit Default Authentication Policy
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, IA-2
# Source: https://howtoharden.com/guides/okta/#19-audit-default-authentication-policy
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Reference the immutable Default Authentication Policy
data "okta_policy" "default_access" {
  name = "Default Policy"
  type = "ACCESS_POLICY"
}

# Custom catch-all policy to replace reliance on the default policy
resource "okta_app_signon_policy" "mfa_required" {
  name        = "MFA Required - All Applications"
  description = "Enforces MFA for all applications - prevents fallthrough to default policy"
}

# Catch-all deny rule (lowest priority in custom policy)
resource "okta_app_signon_policy_rule" "catch_all_deny" {
  policy_id          = okta_app_signon_policy.mfa_required.id
  name               = "Catch-All Deny"
  priority           = 99
  access             = "DENY"
  factor_mode        = "2FA"
  constraints        = []
  groups_excluded    = []
  groups_included    = ["EVERYONE"]
  network_connection = "ANYWHERE"
}

# MFA enforcement rule (higher priority than catch-all)
resource "okta_app_signon_policy_rule" "require_mfa" {
  policy_id                   = okta_app_signon_policy.mfa_required.id
  name                        = "Require MFA"
  priority                    = 1
  access                      = "ALLOW"
  factor_mode                 = "2FA"
  groups_included             = ["EVERYONE"]
  network_connection          = "ANYWHERE"
  re_authentication_frequency = "PT2H"
}
# HTH Guide Excerpt: end terraform
