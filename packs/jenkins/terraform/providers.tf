# =============================================================================
# Jenkins Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Jenkins Terraform provider for server management.
# See: https://registry.terraform.io/providers/taiidani/jenkins/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    jenkins = {
      source  = "taiidani/jenkins"
      version = "~> 0.10"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "jenkins" {
  server_url = var.jenkins_server_url
  username   = var.jenkins_username
  password   = var.jenkins_password
  ca_cert    = var.jenkins_ca_cert
}
