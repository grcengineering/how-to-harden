# =============================================================================
# Keeper Security Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Keeper Secrets Manager Terraform provider.
# See: https://registry.terraform.io/providers/Keeper-Security/secretsmanager/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    secretsmanager = {
      source  = "Keeper-Security/secretsmanager"
      version = "~> 1.0"
    }
  }
}

provider "secretsmanager" {
  credential = var.keeper_credential
}
