# =============================================================================
# HTH Cloudflare Control 5.3: Detect and Block TryCloudflare Quick Tunnel Abuse
# Profile Level: L1 (Crawl)
# Frameworks: NIST CM-7(2), SI-4 | CIS 4.8, 13.3
# Source: https://howtoharden.com/guides/cloudflare/#53-detect-and-block-trycloudflare-quick-tunnel-abuse
#
# The Domain selector matches a domain and all of its subdomains
# (dns.domains / http.request.domains). The Host selector matches one exact
# hostname only, so it would not catch *.trycloudflare.com.
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_gateway_policy" "block_trycloudflare_dns" {
  account_id = var.cloudflare_account_id
  name       = "Block TryCloudflare Quick Tunnels (DNS)"
  action     = "block"
  filters    = ["dns"]
  traffic    = "any(dns.domains[*] == \"trycloudflare.com\")"
  enabled    = true
  precedence = 6
}

resource "cloudflare_zero_trust_gateway_policy" "block_trycloudflare_http" {
  account_id = var.cloudflare_account_id
  name       = "Block TryCloudflare Quick Tunnels (HTTP)"
  action     = "block"
  filters    = ["http"]
  traffic    = "any(http.request.domains[*] == \"trycloudflare.com\")"
  enabled    = true
  precedence = 7
}
# HTH Guide Excerpt: end terraform
