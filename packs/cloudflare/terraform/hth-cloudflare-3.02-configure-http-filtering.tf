# =============================================================================
# HTH Cloudflare Control 3.2: Configure HTTP Filtering
# Profile Level: L1 (Crawl)
# Frameworks: NIST SC-7, SI-4 | CIS 9.2, 13.3
# Source: https://howtoharden.com/guides/cloudflare/#32-configure-http-filtering
#
# Malware (117), Phishing (131), Spyware (153) and Command and Control &
# Botnet (80) are SECURITY categories, matched with
# http.request.uri.security_category
# (developers.cloudflare.com/cloudflare-one/traffic-policies/domain-categories/).
#
# Antivirus scanning and TLS decryption are not HTTP policies: they are fields
# of the account-wide Gateway configuration
# (cloudflare_zero_trust_gateway_settings.settings.antivirus / .tls_decrypt).
# That resource manages the WHOLE configuration object, so declaring it with
# only these two fields would reset every other Gateway setting on apply. This
# pack therefore verifies them with a `check` block (Terraform >= 1.5) instead
# of writing them; turn them on under Traffic controls > Traffic settings, or
# import the existing configuration before managing it here.
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_gateway_policy" "block_malware_http" {
  account_id = var.cloudflare_account_id
  name       = "Block Malware Downloads (HTTP)"
  action     = "block"
  filters    = ["http"]
  traffic    = "any(http.request.uri.security_category[*] in {80 117 131 153})"
  enabled    = true
  precedence = 10

  rule_settings = {
    block_page_enabled = true
    block_reason       = "Blocked: malware risk detected in download"
  }
}

check "gateway_inspection_enabled" {
  data "cloudflare_zero_trust_gateway_settings" "current" {
    account_id = var.cloudflare_account_id
  }

  assert {
    condition     = try(data.cloudflare_zero_trust_gateway_settings.current.settings.tls_decrypt.enabled, false) == true
    error_message = "TLS decryption is off: HTTP policies cannot inspect HTTPS traffic."
  }

  assert {
    condition     = try(data.cloudflare_zero_trust_gateway_settings.current.settings.antivirus.enabled_download_phase, false) == true
    error_message = "Antivirus scanning of downloads is off (Traffic settings > Scan files for malware)."
  }
}
# HTH Guide Excerpt: end terraform
