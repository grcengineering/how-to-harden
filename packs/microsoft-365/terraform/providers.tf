# =============================================================================
# Microsoft 365 Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the AzureAD Terraform provider for Entra ID / M365 management.
# M365 security controls are configured through Azure AD (Entra ID) APIs.
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
  tenant_id     = var.tenant_id
  client_id     = var.client_id
  client_secret = var.client_secret
}
