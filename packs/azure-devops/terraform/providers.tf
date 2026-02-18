# =============================================================================
# Azure DevOps Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Azure DevOps Terraform provider for organization management.
# See: https://registry.terraform.io/providers/microsoft/azuredevops/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 1.0"
    }
  }
}

provider "azuredevops" {
  org_service_url       = var.org_service_url
  personal_access_token = var.personal_access_token
}
