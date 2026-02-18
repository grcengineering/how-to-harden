# =============================================================================
# Zscaler Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Zscaler ZPA and ZIA Terraform providers.
# See: https://registry.terraform.io/providers/zscaler/zpa/latest/docs
# See: https://registry.terraform.io/providers/zscaler/zia/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    zpa = {
      source  = "zscaler/zpa"
      version = "~> 3.0"
    }
    zia = {
      source  = "zscaler/zia"
      version = "~> 3.0"
    }
  }
}

provider "zpa" {
  zpa_client_id     = var.zpa_client_id
  zpa_client_secret = var.zpa_client_secret
  zpa_customer_id   = var.zpa_customer_id
  zpa_cloud         = var.zpa_cloud
}

provider "zia" {
  zia_client_id     = var.zia_client_id
  zia_client_secret = var.zia_client_secret
  zia_customer_id   = var.zia_customer_id
  zia_cloud         = var.zia_cloud
}
