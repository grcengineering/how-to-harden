# =============================================================================
# HTH Ping Identity Control 2.1: Harden SAML Federation Trust
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5, SC-23
# Source: https://howtoharden.com/guides/ping-identity/#21-harden-saml-federation-trust
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Signing key for SAML assertions -- RSA 2048+ with SHA-256
resource "pingone_key" "saml_signing" {
  environment_id = var.pingone_environment_id
  name           = "HTH SAML Signing Key"
  algorithm      = "RSA"
  key_length     = 2048
  signature_algorithm = "SHA256withRSA"
  subject_dn     = "CN=PingOne SAML Signing, O=HTH Hardened"
  usage_type     = "SIGNING"
  validity_period = 365
}

# SAML application with hardened assertion settings
resource "pingone_application" "hardened_saml_sp" {
  environment_id = var.pingone_environment_id
  name           = "HTH Hardened SAML SP Template"
  enabled        = true

  saml_options {
    acs_urls            = ["https://sp.example.com/saml/acs"]
    assertion_duration  = var.saml_assertion_validity_seconds
    sp_entity_id        = "https://sp.example.com"
    response_is_signed  = true
    assertion_signed    = true
    slo_binding         = "HTTP_REDIRECT"

    idp_signing_key {
      key_id    = pingone_key.saml_signing.id
      algorithm = "SHA256withRSA"
    }

    sp_verification {
      authn_request_signed = true
    }
  }
}

# L2+: Require encrypted SAML assertions
resource "pingone_key" "saml_encryption" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH SAML Encryption Key"
  algorithm      = "RSA"
  key_length     = 2048
  signature_algorithm = "SHA256withRSA"
  subject_dn     = "CN=PingOne SAML Encryption, O=HTH Hardened"
  usage_type     = "ENCRYPTION"
  validity_period = 365
}

# L3+: Enforce ECDSA P-256 signing for maximum security
resource "pingone_key" "saml_signing_ecdsa" {
  count = var.profile_level >= 3 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH SAML Signing Key (ECDSA)"
  algorithm      = "EC"
  key_length     = 256
  signature_algorithm = "SHA256withECDSA"
  subject_dn     = "CN=PingOne SAML Signing ECDSA, O=HTH Hardened"
  usage_type     = "SIGNING"
  validity_period = 365
}
# HTH Guide Excerpt: end terraform
