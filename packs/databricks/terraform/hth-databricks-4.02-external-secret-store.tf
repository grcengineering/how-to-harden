# =============================================================================
# HTH Databricks Control 4.2: External Secret Store Integration
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-28, SOC 2 CC6.7
# Source: https://howtoharden.com/guides/databricks/#42-external-secret-store-integration
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Azure Key Vault-backed secret scope (L2+, Azure only)
# Secrets are fetched directly from Key Vault at runtime rather than
# stored in Databricks, providing centralized secret lifecycle management.
resource "databricks_secret_scope" "azure_keyvault" {
  count = var.profile_level >= 2 && var.azure_keyvault_resource_id != "" ? 1 : 0

  name = "azure-kv-scope"

  keyvault_metadata {
    resource_id = var.azure_keyvault_resource_id
    dns_name    = var.azure_keyvault_dns_name
  }
}

# Note: For AWS deployments, use AWS Secrets Manager or Parameter Store
# integration via instance profiles and IAM roles on the cluster. Configure
# the cluster policy to enforce the required instance profile ARN.
#
# For GCP deployments, use Google Secret Manager via workload identity
# federation configured on the cluster service account.
# HTH Guide Excerpt: end terraform
