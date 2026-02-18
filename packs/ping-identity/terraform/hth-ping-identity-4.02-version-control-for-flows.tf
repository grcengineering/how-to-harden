# =============================================================================
# HTH Ping Identity Control 4.2: Version Control for Flows
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-3
# Source: https://howtoharden.com/guides/ping-identity/#42-version-control-for-flows
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Worker application for DaVinci flow export automation (L2+)
# Used by CI/CD pipeline to export flows to git for version control
resource "pingone_application" "davinci_export_worker" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  name           = "HTH DaVinci Flow Export Worker"
  enabled        = true
  description    = "Service account for automated DaVinci flow export to version control"

  oidc_options {
    type                        = "WORKER"
    grant_types                 = ["CLIENT_CREDENTIALS"]
    token_endpoint_auth_method  = "CLIENT_SECRET_BASIC"
  }
}

# Grant the export worker read-only access to DaVinci resources
resource "pingone_application_role_assignment" "davinci_export_readonly" {
  count = var.profile_level >= 2 ? 1 : 0

  environment_id = var.pingone_environment_id
  application_id = pingone_application.davinci_export_worker[0].id
  role_id        = data.pingone_role.identity_data_read_only.id

  scope_environment_id = var.pingone_environment_id
}

# L3+: Dedicated staging environment for flow testing before production
resource "pingone_environment" "davinci_staging" {
  count = var.profile_level >= 3 ? 1 : 0

  name        = "HTH DaVinci Staging"
  description = "Staging environment for testing DaVinci flow changes before production deployment"
  type        = "SANDBOX"
  region      = var.pingone_region

  service {
    type = "SSO"
  }

  service {
    type = "DaVinci"
  }
}
# HTH Guide Excerpt: end terraform
