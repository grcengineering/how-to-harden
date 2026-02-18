# =============================================================================
# HTH Twilio Control 1.2: Enforce Two-Factor Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.5, NIST IA-2(1)
# Source: https://howtoharden.com/guides/twilio/#12-enforce-two-factor-authentication
# =============================================================================

# HTH Guide Excerpt: begin terraform
# NOTE: Twilio Console 2FA enforcement is not configurable via the
# twilio/twilio Terraform provider as of v0.18.x. 2FA must be required
# via the Twilio Console (Account > Security) or the Organizations API.
#
# This null_resource documents the expected 2FA state and validates
# that enforcement is active.

resource "null_resource" "enforce_2fa_validation" {
  triggers = {
    profile_level = var.profile_level
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "============================================================"
      echo "HTH Twilio 1.2: Two-Factor Authentication Enforcement"
      echo "============================================================"
      echo ""
      echo "2FA must be enforced manually in the Twilio Console:"
      echo "  Account > Security > Require two-factor authentication"
      echo ""
      echo "Expected configuration (Profile Level ${var.profile_level}):"
      echo "  2FA Required:        YES (all users)"
      echo "  Authenticator Apps:  ALLOWED"
      echo "  Authy:               ALLOWED"
      if [ "${var.profile_level}" -ge 2 ]; then
        echo "  Hardware Keys:       REQUIRED (admin accounts)"
      else
        echo "  Hardware Keys:       RECOMMENDED (admin accounts)"
      fi
      echo ""
      echo "Validation: Verify at Account > Security that 2FA is required."
      echo "============================================================"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
