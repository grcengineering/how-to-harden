# =============================================================================
# HTH Cloudflare Control 3.5: Configure Gateway Data Loss Prevention Profiles
# Profile Level: L2 (Walk)
# Frameworks: NIST AC-4, SC-7(10) | CIS 3.13
# Source: https://howtoharden.com/guides/cloudflare/#35-configure-gateway-data-loss-prevention-profiles
#
# Uses a predefined DLP profile (Financial Information is available on Free
# and Pay-as-you-go plans) in an HTTP policy with the DLP Profile selector:
#   any(dlp.profiles[*] in {"<profile id>"})
# Start with action "allow" (log only), tune, then set var.dlp_action = "block".
# TLS decryption is required for DLP to see HTTPS payloads; it is a field of
# the account-wide Gateway configuration, so it is verified here rather than
# written (see pack 3.2).
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_dlp_predefined_profile" "financial" {
  account_id           = var.cloudflare_account_id
  profile_id           = var.dlp_financial_profile_id
  allowed_match_count  = 1
  confidence_threshold = "medium"
}

resource "cloudflare_zero_trust_gateway_policy" "dlp_financial" {
  account_id = var.cloudflare_account_id
  name       = "DLP - Financial Information"
  action     = var.dlp_action
  filters    = ["http"]
  traffic    = "any(dlp.profiles[*] in {\"${cloudflare_zero_trust_dlp_predefined_profile.financial.profile_id}\"})"
  enabled    = true
  precedence = 30
}

check "dlp_tls_decryption_enabled" {
  data "cloudflare_zero_trust_gateway_settings" "dlp" {
    account_id = var.cloudflare_account_id
  }

  assert {
    condition     = try(data.cloudflare_zero_trust_gateway_settings.dlp.settings.tls_decrypt.enabled, false) == true
    error_message = "TLS decryption is off: DLP policies cannot inspect HTTPS payloads."
  }
}
# HTH Guide Excerpt: end terraform
