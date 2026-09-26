# =============================================================================
# HTH Cloudflare Control 3.4: Enable Browser Isolation
# Profile Level: L3 (Run)
# Frameworks: NIST SI-3 | CIS 10.5
# Source: https://howtoharden.com/guides/cloudflare/#34-enable-browser-isolation-l3
#
# Requires the Browser Isolation add-on. Isolates the "Security Risks" content
# category (32: New Domains 169, Newly Seen Domains 177, Parked & For Sale
# Domains 128), the expression Cloudflare documents for isolating high-risk
# content. The copy/paste/download/upload/printing/keyboard controls apply
# only when version = "v2".
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "cloudflare_zero_trust_gateway_policy" "isolate_risky_sites" {
  account_id = var.cloudflare_account_id
  name       = "Isolate high-risk content"
  action     = "isolate"
  filters    = ["http"]
  traffic    = "any(http.request.uri.content_category[*] in {32 169 177 128})"
  enabled    = true
  precedence = 5

  rule_settings = {
    biso_admin_controls = {
      version  = "v2"
      copy     = "remote_only"
      paste    = "disabled"
      download = "disabled"
      upload   = "disabled"
      printing = "disabled"
      keyboard = "enabled"
    }
  }
}
# HTH Guide Excerpt: end terraform
