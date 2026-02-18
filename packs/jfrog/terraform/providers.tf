# =============================================================================
# JFrog Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the JFrog Artifactory Terraform provider for platform management.
# See: https://registry.terraform.io/providers/jfrog/artifactory/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    artifactory = {
      source  = "jfrog/artifactory"
      version = "~> 10.0"
    }
  }
}

provider "artifactory" {
  url          = var.artifactory_url
  access_token = var.artifactory_access_token
}
