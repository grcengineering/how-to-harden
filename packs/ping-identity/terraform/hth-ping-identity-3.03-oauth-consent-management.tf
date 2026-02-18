# =============================================================================
# HTH Ping Identity Control 3.3: OAuth Consent Management
# Profile Level: L2 (Hardened)
# Frameworks: NIST AC-6
# Source: https://howtoharden.com/guides/ping-identity/#33-oauth-consent-management
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Resource scope requiring admin consent for sensitive operations (L2+)
resource "pingone_resource_scope" "admin_consent_required" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  resource_id    = pingone_resource.hardened_api.id
  name           = "admin"
  description    = "Administrative scope requiring admin consent"
}

# Application resource grant -- explicitly grant only approved scopes
resource "pingone_application_resource_grant" "limited_scopes" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  application_id = pingone_application.hardened_oidc.id
  resource_id    = pingone_resource.hardened_api.id

  scopes = [
    pingone_resource_scope.read.id,
  ]
}

# OpenID Connect scopes -- restrict to minimum required
resource "pingone_application_resource_grant" "oidc_scopes" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  application_id = pingone_application.hardened_oidc.id
  resource_id    = data.pingone_resource.openid.id

  scopes = [
    data.pingone_resource_scope.openid.id,
    data.pingone_resource_scope.profile.id,
  ]
}

# Data sources for OpenID scopes
data "pingone_resource" "openid" {
  environment_id = var.pingone_environment_id
  name           = "openid"
}

data "pingone_resource_scope" "openid" {
  environment_id = var.pingone_environment_id
  resource_id    = data.pingone_resource.openid.id
  name           = "openid"
}

data "pingone_resource_scope" "profile" {
  environment_id = var.pingone_environment_id
  resource_id    = data.pingone_resource.openid.id
  name           = "profile"
}

# L3+: Require admin consent for all non-standard scopes
resource "pingone_resource_scope" "elevated_consent" {
  count = var.profile_level >= 3 ? 1 : 0

  environment_id = var.pingone_environment_id
  resource_id    = pingone_resource.hardened_api.id
  name           = "elevated"
  description    = "Elevated scope requiring explicit admin approval and justification"
}
# HTH Guide Excerpt: end terraform
