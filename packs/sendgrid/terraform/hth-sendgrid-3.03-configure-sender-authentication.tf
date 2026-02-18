# =============================================================================
# HTH SendGrid Control 3.3: Configure Sender Authentication
# Profile Level: L1 (Baseline)
# Frameworks: CIS 9.2, NIST SC-8
# Source: https://howtoharden.com/guides/sendgrid/#33-configure-sender-authentication
# =============================================================================

# HTH Guide Excerpt: begin terraform
resource "sendgrid_sender_authentication" "primary" {
  count = var.authenticated_domain != "" ? 1 : 0

  domain    = var.authenticated_domain
  subdomain = var.authenticated_domain_subdomain != "" ? var.authenticated_domain_subdomain : null
  default   = true
}

resource "sendgrid_link_branding" "primary" {
  count = var.link_branding_domain != "" ? 1 : 0

  domain    = var.link_branding_domain
  subdomain = var.link_branding_subdomain != "" ? var.link_branding_subdomain : null
  default   = true
}
# HTH Guide Excerpt: end terraform
