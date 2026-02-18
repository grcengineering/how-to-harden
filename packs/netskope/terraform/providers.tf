# =============================================================================
# Netskope Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Netskope Terraform provider for tenant management.
# See: https://registry.terraform.io/providers/netskopeoss/netskope/latest/docs
#
# The provider manages NPA private apps, publishers, access policies, and
# tunnel configurations. Controls not covered by the provider (DLP, CASB,
# threat protection) use null_resource with the Netskope REST API v2.
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    netskope = {
      source  = "netskopeoss/netskope"
      version = "~> 0.3"
    }
  }
}

provider "netskope" {
  server_url = var.netskope_server_url
  api_key    = var.netskope_api_key
}
