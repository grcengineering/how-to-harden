# =============================================================================
# HTH Azure DevOps Control 2.1: Migrate to Workload Identity Federation
# Profile Level: L1 (Baseline) - CRITICAL
# Frameworks: NIST IA-5
# Source: https://howtoharden.com/guides/azure-devops/#21-migrate-to-workload-identity-federation
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Create an Azure Resource Manager service connection using workload
# identity federation (OIDC). This eliminates static secrets by using
# short-lived, automatically rotated tokens. The service connection is
# scoped to specific pipelines -- "grant access to all pipelines" is
# disabled by default.
# ---------------------------------------------------------------------------

resource "azuredevops_serviceendpoint_azurerm" "workload_identity" {
  count = var.azure_subscription_id != "" ? 1 : 0

  project_id            = data.azuredevops_project.target.id
  service_endpoint_name = "${var.project_name}-oidc"
  description           = "Workload Identity Federation - no stored credentials"

  credentials {
    serviceprincipalid = var.service_principal_id
  }

  azurerm_spn_tenantid      = var.azure_tenant_id
  azurerm_subscription_id   = var.azure_subscription_id
  azurerm_subscription_name = var.azure_subscription_name
}

# Restrict service connection access to specific pipelines only
resource "azuredevops_pipeline_authorization" "workload_identity" {
  count = var.azure_subscription_id != "" ? 1 : 0

  project_id  = data.azuredevops_project.target.id
  resource_id = azuredevops_serviceendpoint_azurerm.workload_identity[0].id
  type        = "endpoint"
}

# HTH Guide Excerpt: end terraform
