# =============================================================================
# HTH Duo Security Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Cisco ISE Terraform provider for Duo/ISE policy management.
# Duo integrates with ISE for MFA enforcement on network access and device
# admin flows. Duo-native settings (Admin API) use null_resource provisioners.
# See: https://registry.terraform.io/providers/CiscoDevNet/ise/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    ise = {
      source  = "CiscoDevNet/ise"
      version = "~> 0.7"
    }
  }
}

provider "ise" {
  url      = var.ise_url
  username = var.ise_username
  password = var.ise_password
  insecure = var.ise_insecure
}
