# =============================================================================
# HTH Harness Control 1.2: Enforce Two-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5, NIST IA-2(1)
# Source: https://howtoharden.com/guides/harness/#12-enforce-two-factor-authentication
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enforce two-factor authentication at the account level.
# Note: Harness 2FA enforcement is managed via Account Settings > Authentication
# in the UI. The Terraform provider manages this through account-level settings.
# The harness_platform_usergroup resources below ensure that all groups
# require SSO (which includes IdP-enforced MFA).

# Admin group with SSO-enforced MFA
resource "harness_platform_usergroup" "mfa_enforced_admins" {
  identifier         = "mfa_enforced_admins"
  name               = "MFA Enforced Administrators"
  linked_sso_type    = "SAML"
  externally_managed = true
  sso_linked         = true

  notification_configs {
    type              = "EMAIL"
    send_email_to_all = true
  }
}

# Service account for automation (exempt from interactive MFA, uses SAT)
resource "harness_platform_service_account" "automation" {
  identifier  = "hth_automation_sa"
  name        = "HTH Automation Service Account"
  description = "Service account for automated operations -- authenticates via SAT, not interactive MFA"
  email       = "automation@harness.local"
  account_id  = var.harness_account_id
}
# HTH Guide Excerpt: end terraform
