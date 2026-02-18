# =============================================================================
# HTH PagerDuty Control 2.1: Configure User Provisioning
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.3, NIST AC-2
# Source: https://howtoharden.com/guides/pagerduty/#21-configure-user-provisioning
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Note: On-demand SAML provisioning is automatic when SSO is enabled.
# Users are created on first SSO login with attributes from the IdP.
#
# This file provides a validation check to confirm provisioning is active
# by verifying the account has SSO-provisioned users.

data "pagerduty_user" "provisioning_check" {
  email = "check@example.com"

  # This data source will fail if the user does not exist.
  # It serves as a pattern for validating provisioned users.
  # Replace with an actual SSO-provisioned user email for verification.
  count = 0
}

# Output a reminder about SAML attribute mapping
resource "null_resource" "provisioning_reminder" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "[HTH] User Provisioning Configuration Reminder:"
      echo "[HTH]   - With SSO enabled, users are created on first login"
      echo "[HTH]   - Configure IdP to send: email, name, role attributes"
      echo "[HTH]   - IMPORTANT: SAML attributes are only used at initial creation"
      echo "[HTH]   - Changes in IdP do NOT automatically sync to PagerDuty"
      echo "[HTH]   - For ongoing sync, enable SCIM provisioning (Control 2.2, L2)"
    EOT
  }
}
# HTH Guide Excerpt: end terraform
