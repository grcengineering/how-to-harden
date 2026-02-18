# =============================================================================
# HTH Keeper Control 2.2: Enforce Two-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5, NIST IA-2(1)
# Source: https://howtoharden.com/guides/keeper/#22-enforce-two-factor-authentication
# =============================================================================
#
# Require 2FA for all users accessing their Keeper vault. Keeper supports
# TOTP, FIDO2/WebAuthn, Keeper DNA (Apple Watch), Duo Security, and RSA
# SecurID. SMS should be disabled due to SIM swap vulnerability.
#
# L3 environments should enable dual 2FA -- both at the identity provider
# and within Keeper itself for defense-in-depth.
#
# Implementation: Keeper Commander CLI via local-exec provisioners.
# 2FA enforcement is a role-level enforcement policy.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure 2FA enforcement policy
resource "terraform_data" "tfa_enforcement" {
  input = {
    tfa_required      = var.tfa_required
    allowed_methods   = var.tfa_allowed_methods
    disable_sms       = var.tfa_disable_sms
    profile_level     = var.profile_level
    dual_2fa_required = var.profile_level >= 3
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Keeper 2.2: Enforce Two-Factor Authentication (L1)"
      echo "============================================================"
      echo ""
      echo "ACTION REQUIRED: Configure 2FA in Keeper Admin Console"
      echo ""
      echo "  1. Navigate to: Role > Enforcement Policies > Two-Factor Authentication"
      echo "  2. Enable 'Require 2FA'"
      echo "  3. Set prompting frequency: Every login"
      echo "  4. Configure allowed 2FA methods:"
      %{for method in var.tfa_allowed_methods~}
      echo "     - ${method}"
      %{endfor~}
      echo ""
      %{if var.tfa_disable_sms~}
      echo "  5. DISABLE SMS-based 2FA (SIM swap vulnerability)"
      %{endif~}
      echo ""
      %{if var.profile_level >= 3~}
      echo "  L3 REQUIREMENT: Enable dual 2FA"
      echo "  - Configure 2FA on identity provider side"
      echo "  - ALSO configure 2FA on Keeper side"
      echo "  - Both layers must be active for SSO users"
      echo ""
      %{endif~}
      echo "Or use Keeper Commander CLI:"
      echo "  keeper-commander enterprise-role --enforcement \\"
      echo "    two_factor_authentication_required=true \\"
      echo "    two_factor_duration=login"
      echo "============================================================"
    EOT
  }
}

# Store 2FA policy configuration for audit trail
resource "secretsmanager_login" "tfa_policy_record" {
  folder_uid = var.security_config_folder_uid
  title      = "HTH Two-Factor Authentication Policy"

  login = "2fa-policy"
  url   = "https://keepersecurity.com/console"

  notes = <<-EOT
    TWO-FACTOR AUTHENTICATION ENFORCEMENT
    ========================================
    Profile Level: L1 (Baseline)

    2FA Required: ${var.tfa_required}
    Prompting Frequency: Every login
    Allowed Methods: ${join(", ", var.tfa_allowed_methods)}
    SMS Disabled: ${var.tfa_disable_sms}

    Recommended Methods (by security strength):
    1. FIDO2/WebAuthn (hardware keys) -- phishing-resistant
    2. TOTP Authenticator (Google Authenticator, Authy)
    3. Keeper DNA (Apple Watch) -- biometric
    4. Duo Security (if integrated)
    5. RSA SecurID (if integrated)
    AVOID: SMS (vulnerable to SIM swap attacks)

    L3 Requirement: Dual 2FA (IdP + Keeper) = ${var.profile_level >= 3}

    Last updated: Managed by Terraform
    Control: HTH Keeper 2.2
  EOT
}
# HTH Guide Excerpt: end terraform
