# =============================================================================
# HTH Cloudflare Control 3.1: Configure DNS Filtering
# Profile Level: L1 (Crawl)
# Frameworks: NIST SC-7, SI-3 | CIS 9.2
# Source: https://howtoharden.com/guides/cloudflare/#31-configure-dns-filtering
#
# Category IDs: developers.cloudflare.com/cloudflare-one/traffic-policies/domain-categories/
#   Security:  80 Command and Control & Botnet, 83 Cryptomining, 117 Malware,
#              131 Phishing, 153 Spyware, 175 DNS Tunneling,
#              176 Domain Generation Algorithm, 178 Brand Embedding
#   Content:   67 Adult Themes, 125 Nudity, 133 Pornography, 99 Gambling
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_gateway_policy" "block_security_threats_dns" {
  account_id = var.cloudflare_account_id
  name       = "Block Security Threats (DNS)"
  action     = "block"
  filters    = ["dns"]
  traffic    = "any(dns.security_category[*] in {80 83 117 131 153 175 176 178})"
  enabled    = true
  precedence = 10

  rule_settings = {
    block_page_enabled = true
    block_reason       = "Blocked: malware, phishing, spyware, or C2 domain"
  }
}

resource "cloudflare_zero_trust_gateway_policy" "block_content_categories_dns" {
  account_id = var.cloudflare_account_id
  name       = "Block Restricted Content Categories (DNS)"
  action     = "block"
  filters    = ["dns"]
  traffic    = "any(dns.content_category[*] in {67 125 133 99})"
  enabled    = true
  precedence = 20

  rule_settings = {
    block_page_enabled = true
    block_reason       = "This content category is blocked by policy"
  }
}
# HTH Guide Excerpt: end terraform
