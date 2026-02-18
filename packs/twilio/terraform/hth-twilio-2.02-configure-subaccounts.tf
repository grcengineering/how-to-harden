# =============================================================================
# HTH Twilio Control 2.2: Configure Subaccounts
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/twilio/#22-configure-subaccounts
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create isolated subaccounts for environment and application separation.
# Each subaccount gets its own credentials, usage limits, and audit trail.

resource "twilio_api_accounts" "subaccount" {
  count = var.profile_level >= 2 ? length(var.subaccounts) : 0

  friendly_name = var.subaccounts[count.index]
}
# HTH Guide Excerpt: end terraform
