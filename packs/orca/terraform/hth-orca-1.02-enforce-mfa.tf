# =============================================================================
# HTH Orca Control 1.2: Enforce Multi-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5, NIST IA-2(1)
# Source: https://howtoharden.com/guides/orca/#12-enforce-multi-factor-authentication
#
# Note: MFA enforcement in Orca Security is configured through the identity
# provider (IdP) since Orca relies on SSO for authentication. This file
# creates a custom sonar alert to detect any users not covered by SSO/MFA
# and an automation to notify security teams of non-compliant access.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Alert for IAM misconfigurations related to authentication weaknesses
resource "orcasecurity_custom_sonar_alert" "mfa_not_enforced" {
  name          = "Orca Users Without SSO/MFA Coverage"
  description   = "Detects scenarios where cloud identities connected to Orca may not have MFA enforced, indicating a gap in authentication hardening."
  rule          = "User with MFAEnabled = false"
  orca_score    = 8.0
  category      = "Authentication"
  context_score = true

  remediation_text = {
    enable = true
    text   = "Ensure all users authenticate through the configured SAML SSO provider with MFA enforced. Remove local accounts that bypass SSO. See HTH Orca Guide section 1.2."
  }

  compliance_frameworks = [
    { name = "HTH Orca Hardening", section = "1.2 Enforce MFA", priority = "high" }
  ]
}
# HTH Guide Excerpt: end terraform
