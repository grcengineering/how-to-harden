# =============================================================================
# HTH Azure DevOps Control 5.1: Secure Variable Groups
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-28
# Source: https://howtoharden.com/guides/azure-devops/#51-secure-variable-groups
# =============================================================================

# HTH Guide Excerpt: begin terraform

# ---------------------------------------------------------------------------
# Create environment-specific variable groups with appropriate access
# controls. Production secrets are linked to Azure Key Vault so that
# secret values are never stored in Azure DevOps. Non-secret
# configuration uses standard variable groups.
#
# Variable group hierarchy:
#   production-secrets   (Key Vault linked)
#   staging-secrets      (Key Vault linked or standard)
#   shared-config        (non-secret configuration)
# ---------------------------------------------------------------------------

# Production secrets variable group linked to Azure Key Vault
resource "azuredevops_variable_group" "production_secrets" {
  count = var.key_vault_name != "" ? 1 : 0

  project_id   = data.azuredevops_project.target.id
  name         = "production-secrets"
  description  = "Production secrets linked to Azure Key Vault - managed by HTH"
  allow_access = false

  key_vault {
    name                = var.key_vault_name
    service_endpoint_id = var.key_vault_service_connection_id
  }

  dynamic "variable" {
    for_each = var.key_vault_secrets
    content {
      name = variable.key
    }
  }
}

# Shared non-secret configuration variable group
resource "azuredevops_variable_group" "shared_config" {
  project_id   = data.azuredevops_project.target.id
  name         = "shared-config"
  description  = "Shared non-secret configuration - managed by HTH"
  allow_access = false

  variable {
    name  = "ENVIRONMENT"
    value = "production"
  }

  variable {
    name  = "HTH_MANAGED"
    value = "true"
  }
}

# Restrict production secrets variable group to specific pipelines only
resource "azuredevops_pipeline_authorization" "production_secrets" {
  count = var.key_vault_name != "" ? 1 : 0

  project_id  = data.azuredevops_project.target.id
  resource_id = azuredevops_variable_group.production_secrets[0].id
  type        = "variablegroup"
}

# HTH Guide Excerpt: end terraform
