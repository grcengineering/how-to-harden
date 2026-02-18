# =============================================================================
# Oracle HCM Cloud Hardening Code Pack - Provider Configuration
# How to Harden (howtoharden.com)
#
# Configures the Oracle Cloud Infrastructure (OCI) Terraform provider for
# managing Oracle HCM Cloud security settings via IDCS and OCI APIs.
# See: https://registry.terraform.io/providers/oracle/oci/latest/docs
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.oci_tenancy_ocid
  user_ocid        = var.oci_user_ocid
  fingerprint      = var.oci_fingerprint
  private_key_path = var.oci_private_key_path
  region           = var.oci_region
}
