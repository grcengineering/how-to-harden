# =============================================================================
# Ping Identity Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the PingOne Terraform provider for environment management.
# See: https://registry.terraform.io/providers/pingidentity/pingone/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    pingone = {
      source  = "pingidentity/pingone"
      version = "~> 1.0"
    }
  }
}

provider "pingone" {
  client_id      = var.pingone_client_id
  client_secret  = var.pingone_client_secret
  environment_id = var.pingone_environment_id
  region_code    = var.pingone_region
}
