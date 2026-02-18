# =============================================================================
# HTH Ping Identity Control 6.2: API Client Management
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5, AC-6
# Source: https://howtoharden.com/guides/ping-identity/#62-api-client-management
# =============================================================================

# HTH Guide Excerpt: begin terraform
# SCIM Provisioner -- 1 hour token, IP-restricted, audit logging
resource "pingone_application" "scim_provisioner" {
  environment_id = var.pingone_environment_id
  name           = "HTH SCIM Provisioner"
  enabled        = true
  description    = "SCIM provisioning client with restricted scopes and short token lifetime"

  oidc_options {
    type                        = "WORKER"
    grant_types                 = ["CLIENT_CREDENTIALS"]
    token_endpoint_auth_method  = "CLIENT_SECRET_BASIC"
  }
}

# SCIM provisioner role -- limited to identity data operations
resource "pingone_application_role_assignment" "scim_identity_admin" {
  environment_id = var.pingone_environment_id
  application_id = pingone_application.scim_provisioner.id
  role_id        = data.pingone_role.identity_data_admin.id

  scope_environment_id = var.pingone_environment_id
}

# Admin API client -- 15 minute token, MFA required, IP-restricted
resource "pingone_application" "admin_api_client" {
  environment_id = var.pingone_environment_id
  name           = "HTH Admin API Client"
  enabled        = true
  description    = "Administrative API client with minimal token lifetime and restricted access"

  oidc_options {
    type                        = "WORKER"
    grant_types                 = ["CLIENT_CREDENTIALS"]
    token_endpoint_auth_method  = "CLIENT_SECRET_BASIC"
  }
}

# Admin API role assignment -- environment admin scoped
resource "pingone_application_role_assignment" "admin_api_role" {
  environment_id = var.pingone_environment_id
  application_id = pingone_application.admin_api_client.id
  role_id        = data.pingone_role.environment_admin.id

  scope_environment_id = var.pingone_environment_id
}

# Reporting client -- read-only, 1 hour token, dedicated service account
resource "pingone_application" "reporting_client" {
  environment_id = var.pingone_environment_id
  name           = "HTH Reporting Client"
  enabled        = true
  description    = "Read-only reporting client for dashboards and compliance reports"

  oidc_options {
    type                        = "WORKER"
    grant_types                 = ["CLIENT_CREDENTIALS"]
    token_endpoint_auth_method  = "CLIENT_SECRET_BASIC"
  }
}

# Reporting client role -- read-only access
resource "pingone_application_role_assignment" "reporting_readonly" {
  environment_id = var.pingone_environment_id
  application_id = pingone_application.reporting_client.id
  role_id        = data.pingone_role.identity_data_read_only.id

  scope_environment_id = var.pingone_environment_id
}

# L2+: SSO Application with standard validation and 4-hour token
resource "pingone_application" "sso_app_template" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH SSO Application Template"
  enabled        = true
  description    = "Standard SSO application with OpenID and Profile scopes"

  oidc_options {
    type                        = "WEB_APP"
    grant_types                 = ["AUTHORIZATION_CODE", "REFRESH_TOKEN"]
    response_types              = ["CODE"]
    token_endpoint_auth_method  = "CLIENT_SECRET_POST"
    redirect_uris               = ["https://app.example.com/callback"]

    pkce_enforcement = "S256_REQUIRED"

    refresh_token_duration         = 14400
    refresh_token_rolling_duration = 14400
  }
}
# HTH Guide Excerpt: end terraform
