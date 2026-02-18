# =============================================================================
# HTH Zscaler Control 2.1: Configure URL Filtering Policies
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-7, SI-3 | CIS 9.2
# Source: https://howtoharden.com/guides/zscaler/#21-configure-url-filtering-policies
# =============================================================================

# HTH Guide Excerpt: begin terraform

# Block high-risk URL categories (security, legal, risk)
resource "zia_url_filtering_rules" "block_high_risk" {
  name        = "HTH-Block-High-Risk-Categories"
  description = "Block malware, phishing, botnet, cryptomining, and policy-violating categories"
  state       = "ENABLED"
  action      = "BLOCK"
  order       = 1

  url_categories = var.url_block_categories

  protocols = ["HTTPS_RULE", "HTTP_PROXY", "HTTP_RULE", "SSL_RULE", "FTP_RULE"]
}

# Caution on medium-risk URL categories (user override with acknowledgment)
resource "zia_url_filtering_rules" "caution_medium_risk" {
  name        = "HTH-Caution-Medium-Risk-Categories"
  description = "Caution on uncategorized, newly registered domains, and file sharing sites"
  state       = "ENABLED"
  action      = "CAUTION"
  order       = 2

  url_categories = var.url_caution_categories

  protocols = ["HTTPS_RULE", "HTTP_PROXY", "HTTP_RULE", "SSL_RULE"]
}

# HTH Guide Excerpt: end terraform
