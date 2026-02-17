# =============================================================================
# HTH Cloudflare Control 3.2: Configure HTTP Filtering
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-7, SI-4 | CIS 9.2, 13.3
# Source: https://howtoharden.com/guides/cloudflare/#32-configure-http-filtering
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_gateway_policy" "block_malware_http" {
  account_id = var.cloudflare_account_id
  name       = "Block Malware Downloads (HTTP)"
  action     = "block"
  filters    = ["http"]
  traffic    = "any(http.request.uri.content_category[*] in {80 83})"
  enabled    = true
  precedence = 10

  rule_settings = {
    block_page_enabled = true
    block_reason       = "Blocked: malware risk detected in download"
  }
}

resource "cloudflare_zero_trust_gateway_policy" "av_scan_downloads" {
  account_id = var.cloudflare_account_id
  name       = "Scan file downloads for threats"
  action     = "block"
  filters    = ["http"]
  traffic    = "any(http.request.uri.content_category[*] in {80}) and http.request.method == \"GET\""
  enabled    = true
  precedence = 15

  rule_settings = {
    block_page_enabled = true
    block_reason       = "File blocked: threat detected during scan"
  }
}
# HTH Guide Excerpt: end terraform
