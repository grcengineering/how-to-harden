# =============================================================================
# HTH Zscaler Control 5.1: Enable SSL Inspection
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-8, SI-3 | CIS 3.10, 13.3
# Source: https://howtoharden.com/guides/zscaler/#51-enable-ssl-inspection
# =============================================================================

# HTH Guide Excerpt: begin terraform

# SSL inspection rule -- inspect all HTTPS traffic by default
resource "zia_ssl_inspection_rules" "inspect_all" {
  name        = "HTH-Inspect-All-SSL-Traffic"
  description = "Inspect all SSL/TLS traffic for threat detection and policy enforcement"
  state       = "ENABLED"
  action      = "INSPECT"
  order       = 1

  protocols = ["HTTPS_RULE", "SSL_RULE"]
}

# SSL inspection exception -- bypass certificate-pinned applications
resource "zia_ssl_inspection_rules" "do_not_inspect" {
  name        = "HTH-Do-Not-Inspect-Exceptions"
  description = "Bypass SSL inspection for certificate-pinned and privacy-sensitive categories"
  state       = "ENABLED"
  action      = "DO_NOT_INSPECT"
  order       = 0

  url_categories = var.ssl_do_not_inspect_urls
}

# HTH Guide Excerpt: end terraform
