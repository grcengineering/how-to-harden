# =============================================================================
# HTH Cloudflare Control 3.4: Enable Browser Isolation
# Profile Level: L3 (Maximum Security)
# Frameworks: NIST SI-3 | CIS 10.5
# Source: https://howtoharden.com/guides/cloudflare/#34-enable-browser-isolation-l3
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_gateway_policy" "isolate_risky_sites" {
  account_id = var.cloudflare_account_id
  name       = "Isolate risky and uncategorized websites"
  action     = "isolate"
  filters    = ["http"]
  traffic    = "any(http.request.uri.content_category[*] in {68 155})"
  enabled    = true
  precedence = 5

  rule_settings = {
    biso_admin_controls = {
      copy     = "remote_only"
      paste    = "block"
      download = "block"
      upload   = "block"
      printing = "block"
      keyboard = "allow"
    }
  }
}
# HTH Guide Excerpt: end terraform
