# =============================================================================
# HTH Ping Identity Control 6.1: SP Connection Hardening
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5, SC-23
# Source: https://howtoharden.com/guides/ping-identity/#61-sp-connection-hardening
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Hardened SAML SP connection template with all required validations
resource "pingone_application" "hardened_sp_connection" {
  environment_id = var.pingone_environment_id
  name           = "HTH Hardened SP Connection"
  enabled        = true
  description    = "Template SP connection with audience restriction, signed assertions, minimum validity"

  saml_options {
    acs_urls           = ["https://sp.example.com/saml/acs"]
    assertion_duration = var.saml_assertion_validity_seconds
    sp_entity_id       = "https://sp.example.com"

    # Require signed responses and assertions
    response_is_signed = true
    assertion_signed   = true

    # SLO configuration
    slo_binding  = "HTTP_REDIRECT"
    slo_endpoint = "https://sp.example.com/saml/slo"

    # Signing configuration using hardened key
    idp_signing_key {
      key_id    = pingone_key.saml_signing.id
      algorithm = "SHA256withRSA"
    }

    # Require signed authn requests from SP
    sp_verification {
      authn_request_signed = true
    }
  }
}

# L2+: SP connection with encrypted assertions
resource "pingone_application" "encrypted_sp_connection" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH Encrypted SP Connection"
  enabled        = true
  description    = "SP connection with encrypted SAML assertions for sensitive applications"

  saml_options {
    acs_urls           = ["https://secure-sp.example.com/saml/acs"]
    assertion_duration = var.saml_assertion_validity_seconds
    sp_entity_id       = "https://secure-sp.example.com"

    response_is_signed = true
    assertion_signed   = true

    slo_binding  = "HTTP_REDIRECT"
    slo_endpoint = "https://secure-sp.example.com/saml/slo"

    idp_signing_key {
      key_id    = pingone_key.saml_signing.id
      algorithm = "SHA256withRSA"
    }

    sp_verification {
      authn_request_signed = true
    }

    # Encryption for L2+ environments
    sp_encryption {
      algorithm     = "AES_256"
      key_transport = {
        algorithm = "RSA_OAEP"
      }
    }
  }
}
# HTH Guide Excerpt: end terraform
