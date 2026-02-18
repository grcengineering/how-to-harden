# =============================================================================
# HTH Splunk Control 1.1: Configure SAML Single Sign-On
# Profile Level: L1 (Baseline)
# Frameworks: CIS 6.3/12.5, NIST IA-2/IA-8
# Source: https://howtoharden.com/guides/splunk/#11-configure-saml-single-sign-on
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Configure SAML SSO authentication for centralized identity management.
# Requires SAML to be enabled by Splunk Cloud Support first.
# The splunk_configs_conf resource writes to authentication.conf.

# Enable SAML authentication method
resource "splunk_configs_conf" "auth_saml_settings" {
  count = var.saml_idp_url != "" ? 1 : 0

  name = "authentication/authentication"

  variables = {
    "authType"    = "SAML"
    "authSettings" = "hth_saml"
  }
}

# Configure the SAML stanza with IdP settings
resource "splunk_configs_conf" "auth_saml_idp" {
  count = var.saml_idp_url != "" ? 1 : 0

  name = "authentication/hth_saml"

  variables = {
    "fqdn"                        = replace(replace(var.splunk_url, "https://", ""), ":8089", "")
    "idpSSOUrl"                   = var.saml_idp_url
    "idpCertPath"                 = var.saml_idp_cert_path
    "entityId"                    = var.saml_entity_id
    "signAuthnRequest"            = "true"
    "signedAssertion"             = "true"
    "attributeQuerySoapPassword"  = ""
    "attributeQueryRequestSigned" = "true"
    "redirectAfterLogoutToUrl"    = var.saml_idp_url
    "nameIdFormat"                = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
    "ssoBinding"                  = "HTTPPost"
    "sloBinding"                  = "HTTPPost"
    "role"                        = "role"
    "realName"                    = "realName"
    "mail"                        = "mail"
  }

  depends_on = [splunk_configs_conf.auth_saml_settings]
}
# HTH Guide Excerpt: end terraform
