# =============================================================================
# HTH OneLogin Control 4.1: Configure TLS Requirements
# Profile Level: L1 (Baseline)
# Frameworks: CIS 3.10, NIST SC-8
# Source: https://howtoharden.com/guides/onelogin/#41-configure-tls-requirements
#
# NOTE: OneLogin enforces TLS 1.2+ at the platform level. This control is
# primarily a validation checkpoint. The SAML app resources below ensure
# all SSO connections use HTTPS endpoints.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# SAML connector app template enforcing HTTPS-only ACS URLs
# This serves as a reference configuration for validating TLS on SSO apps.
# Actual SAML apps should follow this pattern for their ACS and recipient URLs.
resource "onelogin_saml_app" "tls_reference" {
  name           = "HTH TLS Reference App"
  description    = "Reference SAML app enforcing HTTPS ACS endpoints"
  connector_id   = 110016

  configuration = {
    # All SAML endpoints MUST use HTTPS
    audience   = "https://app.example.com/saml/metadata"
    recipient  = "https://app.example.com/saml/acs"
    acs_url    = "https://app.example.com/saml/acs"
    login_url  = "https://app.example.com/login"
  }

  # Require signed SAML assertions
  visible = false
}
# HTH Guide Excerpt: end terraform
