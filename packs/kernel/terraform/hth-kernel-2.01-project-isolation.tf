# Control: 2.1 Isolate Environments with Projects
# Profile Level: L1 (Baseline)
# Frameworks: NIST 800-53 SC-7/AC-4, CIS Controls v8 12, SOC 2 CC6.1
# Guide: https://howtoharden.com/guides/kernel/
# Interface: Terraform provider kernel/kernel —
#   https://registry.terraform.io/providers/kernel/kernel/latest
#   https://github.com/kernel/terraform-provider-kernel (docs/resources/project.md)

# HTH Guide Excerpt: begin provider-setup
terraform {
  required_providers {
    kernel = {
      source = "kernel/kernel"
    }
  }
}

# Authentication comes from the environment where Terraform runs:
#   KERNEL_API_KEY     — a dedicated, expiring CI key (Controls 1.1-1.3)
#   KERNEL_PROJECT_ID  — optional default project binding
# Never place the key in provider config or committed tfvars.
provider "kernel" {}
# HTH Guide Excerpt: end provider-setup

# HTH Guide Excerpt: begin environment-projects
# One project per environment: browsers, profiles, credentials, proxies,
# extensions, deployments, and pools are all project-scoped, so a key or
# workload in staging can never touch production session state.
resource "kernel_project" "production" {
  name = "production"
}

resource "kernel_project" "staging" {
  name = "staging"
}
# HTH Guide Excerpt: end environment-projects
