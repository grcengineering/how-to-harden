# =============================================================================
# HTH 1Password Control 1.1: Configure SSO with Identity Provider
# Profile Level: L1 (Baseline)
# Source: https://howtoharden.com/guides/1password/#11-configure-sso-with-identity-provider
# =============================================================================
#
# The 1Password Terraform provider (1Password/onepassword) manages items and
# vaults. SSO/SAML configuration is an account-level admin setting that must
# be configured via the 1Password Admin Console or the 1Password CLI.
#
# This file uses a null_resource provisioner with the 1Password CLI (op) to
# verify SSO readiness and document the expected configuration state.
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Verify SSO configuration is active using the 1Password CLI.
# The op CLI must be installed and authenticated with a service account.
resource "null_resource" "verify_sso_configuration" {
  count = var.idp_sso_url != "" ? 1 : 0

  triggers = {
    idp_sso_url    = var.idp_sso_url
    idp_entity_id  = var.idp_entity_id
    profile_level  = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================="
      echo "HTH 1Password Control 1.1: SSO Configuration"
      echo "============================================="
      echo ""
      echo "SSO must be configured in the 1Password Admin Console:"
      echo "  1. Navigate to: Security > Sign-in"
      echo "  2. Click 'Set up Single Sign-On'"
      echo "  3. Select SAML authentication"
      echo "  4. IdP SSO URL: ${var.idp_sso_url}"
      echo "  5. IdP Entity ID: ${var.idp_entity_id}"
      echo ""
      echo "Verifying 1Password CLI availability..."
      if command -v op &> /dev/null; then
        echo "op CLI found: $(op --version)"
        echo "Checking account details..."
        op account list --format=json 2>/dev/null || echo "WARNING: op CLI not signed in"
      else
        echo "WARNING: 1Password CLI (op) not found."
        echo "Install from: https://developer.1password.com/docs/cli/"
      fi
      echo ""
      echo "SSO Unlock Options (configure per profile level):"
      echo "  L1: Biometrics + Master Password"
      echo "  L2: Biometrics + Master Password (enforce MFA via IdP)"
      echo "  L3: Master Password only (no biometric unlock)"
    EOT
  }
}

# HTH Guide Excerpt: end terraform
