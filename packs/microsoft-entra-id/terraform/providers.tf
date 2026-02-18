# =============================================================================
# Microsoft Entra ID Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the AzureAD Terraform provider for tenant management.
# See: https://registry.terraform.io/providers/hashicorp/azuread/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {
  tenant_id = var.tenant_id
}
