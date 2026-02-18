# =============================================================================
# HTH OneLogin Control 2.2: Configure SmartFactor Authentication
# Profile Level: L2 (Hardened)
# Frameworks: CIS 6.5, NIST IA-2(13)
# Source: https://howtoharden.com/guides/onelogin/#22-configure-smartfactor-authentication
# Prerequisites: OneLogin Expert plan or higher
# =============================================================================

# HTH Guide Excerpt: begin terraform
# SmartFactor adaptive MFA policy -- risk-based authentication
# Only deployed at L2+ (requires Expert plan)
resource "onelogin_user_security_policy" "smartfactor" {
  count = var.profile_level >= 2 ? 1 : 0

  name = var.smartfactor_policy_name

  # Enable SmartFactor risk-based authentication
  smartfactor_auth_enabled = true

  # Risk threshold actions:
  #   Low risk    -> no additional MFA required
  #   Medium risk -> require MFA step-up
  #   High risk   -> block and alert
  smartfactor_low_risk_action    = "allow"
  smartfactor_medium_risk_action = "mfa_required"
  smartfactor_high_risk_action   = "deny"
}

# L3: Tighten SmartFactor -- require MFA even on low-risk logins
resource "onelogin_user_security_policy" "smartfactor_max" {
  count = var.profile_level >= 3 ? 1 : 0

  name = "HTH SmartFactor Policy - Maximum Security"

  smartfactor_auth_enabled       = true
  smartfactor_low_risk_action    = "mfa_required"
  smartfactor_medium_risk_action = "mfa_required"
  smartfactor_high_risk_action   = "deny"
}
# HTH Guide Excerpt: end terraform
