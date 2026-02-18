# =============================================================================
# Google Workspace Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Google Workspace Terraform provider for domain management.
# See: https://registry.terraform.io/providers/hashicorp/googleworkspace/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    googleworkspace = {
      source  = "hashicorp/googleworkspace"
      version = "~> 0.7"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "googleworkspace" {
  customer_id             = var.customer_id
  credentials             = var.credentials_file
  service_account         = var.service_account_email
  impersonated_user_email = var.impersonated_user_email
}

# Google provider for Access Context Manager, DLP, and BigQuery resources
provider "google" {
  project     = var.gcp_project_id
  credentials = var.credentials_file
}
