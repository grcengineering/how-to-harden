# =============================================================================
# HTH Twilio Control 3.1: Configure API Key Security
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.11, NIST SC-12
# Source: https://howtoharden.com/guides/twilio/#31-configure-api-key-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create a standard API key to replace Account SID / Auth Token usage.
# API keys are scoped, rotatable, and revocable -- the Account Auth Token
# is a master credential that should never be used in application code.

resource "twilio_api_accounts_keys" "hardened_api_key" {
  count = var.create_api_key ? 1 : 0

  friendly_name = var.api_key_friendly_name
}

# L2+: Create a dedicated API key per subaccount for credential isolation
resource "twilio_api_accounts_keys" "subaccount_api_key" {
  count = var.profile_level >= 2 ? length(var.subaccounts) : 0

  account_sid   = twilio_api_accounts.subaccount[count.index].sid
  friendly_name = "hth-${var.subaccounts[count.index]}-api-key"
}
# HTH Guide Excerpt: end terraform
