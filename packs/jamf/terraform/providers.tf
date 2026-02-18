# =============================================================================
# Jamf Pro Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the deploymenttheory/jamfpro Terraform provider for Jamf Pro
# management. Requires OAuth2 API client credentials.
# See: https://registry.terraform.io/providers/deploymenttheory/jamfpro/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    jamfpro = {
      source  = "deploymenttheory/jamfpro"
      version = "~> 0.2"
    }
  }
}

provider "jamfpro" {
  jamfpro_instance_fqdn = var.jamfpro_instance_fqdn
  auth_method           = "oauth2"
  client_id             = var.jamfpro_client_id
  client_secret         = var.jamfpro_client_secret
}
