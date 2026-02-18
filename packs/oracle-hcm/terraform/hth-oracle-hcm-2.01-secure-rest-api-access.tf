# =============================================================================
# HTH Oracle HCM Control 2.1: Secure REST API Access
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/oracle-hcm/#21-secure-rest-api-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Confidential OAuth application for HCM REST API access
resource "oci_identity_domains_app" "hcm_api_client" {
  idcs_endpoint = var.idcs_domain_url

  schemas = [
    "urn:ietf:params:scim:schemas:oracle:idcs:App",
  ]

  display_name = var.oauth_client_name
  description  = "Hardened OAuth client for HCM REST API access (HTH)"
  active       = true
  is_login_target = false

  # Client type: confidential application
  client_type = "confidential"

  # Grant types — prefer authorization_code over client_credentials
  allowed_grant_types = var.oauth_allowed_grant_types

  # Redirect URIs — exact match only
  redirect_uris = var.oauth_redirect_uris

  # Token configuration
  access_token_expiry = var.profile_level >= 2 ? 1800 : 3600
  refresh_token_expiry = var.profile_level >= 2 ? 28800 : 86400

  # Allowed scopes — minimum required
  dynamic "scopes" {
    for_each = var.oauth_allowed_scopes
    content {
      fqs = scopes.value
    }
  }

  # L2: Require PKCE for authorization code grants
  is_opc_service = false
}

# Sign-on policy for API clients requiring authentication
resource "oci_identity_domains_policy" "api_signon_policy" {
  idcs_endpoint = var.idcs_domain_url

  schemas     = ["urn:ietf:params:scim:schemas:oracle:idcs:Policy"]
  name        = "HTH-HCM-API-SignOn-Policy"
  description = "Sign-on policy for HCM REST API client authentication"
  active      = true
  policy_type {
    value = "SignOn"
  }

  rules {
    name     = "RequireAuthForAPI"
    sequence = 1
    return {
      name  = "allowAccess"
      value = "true"
    }
    return {
      name  = "mfaRequired"
      value = "true"
    }
  }
}

# L2: Network perimeter for API access — restrict to known IP ranges
resource "oci_identity_domains_network_perimeter" "api_network_perimeter" {
  count = var.profile_level >= 2 ? 1 : 0

  idcs_endpoint = var.idcs_domain_url

  schemas     = ["urn:ietf:params:scim:schemas:oracle:idcs:NetworkPerimeter"]
  name        = "HTH-HCM-API-Network-Perimeter"
  description = "Restrict HCM API access to approved network ranges (L2)"

  ip_addresses {
    type  = "RANGE"
    value = "0.0.0.0/0"  # Replace with actual corporate CIDR ranges
  }
}

# L3: Create a dedicated service user for API access (no interactive login)
resource "oci_identity_domains_user" "api_service_account" {
  count = var.profile_level >= 3 ? 1 : 0

  idcs_endpoint = var.idcs_domain_url

  schemas = [
    "urn:ietf:params:scim:schemas:core:2.0:User",
    "urn:ietf:params:scim:schemas:oracle:idcs:extension:user:User",
  ]

  user_name = "hth-hcm-api-service"
  active    = true

  name {
    given_name  = "HTH HCM"
    family_name = "API Service"
  }

  emails {
    value   = "hcm-api-service@noreply.local"
    type    = "work"
    primary = true
  }

  urnietfpaaboramsscaborimschemasoaboracleidcsextensionuser_user {
    is_federated_user = false
  }
}
# HTH Guide Excerpt: end terraform
