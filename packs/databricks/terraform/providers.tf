# =============================================================================
# Databricks Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Databricks Terraform provider for workspace management.
# See: https://registry.terraform.io/providers/databricks/databricks/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }
}

provider "databricks" {
  host  = var.databricks_workspace_url
  token = var.databricks_token
}
