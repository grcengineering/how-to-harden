# =============================================================================
# Docker Hub Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Docker Terraform provider for Docker Hub organization management.
# See: https://registry.terraform.io/providers/docker/docker/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    docker = {
      source  = "docker/docker"
      version = "~> 0.3"
    }
  }
}

provider "docker" {
  host = var.docker_host
}
