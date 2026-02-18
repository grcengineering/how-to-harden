# =============================================================================
# HTH Oracle HCM Control 3.1: Configure Data Encryption
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-28
# Source: https://howtoharden.com/guides/oracle-hcm/#31-configure-data-encryption
# =============================================================================

# HTH Guide Excerpt: begin terraform
# OCI Vault for customer-managed encryption keys (optional but recommended)
resource "oci_kms_vault" "hcm_vault" {
  count = var.oci_vault_id == "" && var.profile_level >= 2 ? 1 : 0

  compartment_id = var.idcs_compartment_id
  display_name   = "HTH-HCM-Security-Vault"
  vault_type     = "DEFAULT"
}

# Master encryption key for HCM data at rest
resource "oci_kms_key" "hcm_master_key" {
  count = var.oci_key_id == "" && var.profile_level >= 2 ? 1 : 0

  compartment_id      = var.idcs_compartment_id
  display_name        = "HTH-HCM-Master-Encryption-Key"
  management_endpoint = var.oci_vault_id != "" ? data.oci_kms_vault.existing[0].management_endpoint : oci_kms_vault.hcm_vault[0].management_endpoint

  key_shape {
    algorithm = "AES"
    length    = 32
  }

  protection_mode = var.profile_level >= 3 ? "HSM" : "SOFTWARE"
}

# Data source to look up an existing vault (when user provides one)
data "oci_kms_vault" "existing" {
  count    = var.oci_vault_id != "" ? 1 : 0
  vault_id = var.oci_vault_id
}

# IAM policy granting HCM service access to the encryption key
resource "oci_identity_policy" "hcm_encryption_policy" {
  count = var.profile_level >= 2 ? 1 : 0

  compartment_id = var.oci_tenancy_ocid
  name           = "HTH-HCM-Encryption-Key-Access"
  description    = "Grant Oracle HCM Cloud access to customer-managed encryption keys"

  statements = [
    "Allow dynamic-group '${var.idcs_compartment_id}'/HTH-HCM-Service-Instances to use keys in compartment id ${var.idcs_compartment_id}",
  ]
}

# OCI Object Storage bucket for encrypted HCM data exports
resource "oci_objectstorage_bucket" "hcm_secure_exports" {
  compartment_id = var.idcs_compartment_id
  namespace      = data.oci_objectstorage_namespace.tenancy.namespace
  name           = "hth-hcm-secure-exports"

  # Server-side encryption with customer-managed key (L2+)
  kms_key_id = var.profile_level >= 2 ? (
    var.oci_key_id != "" ? var.oci_key_id : oci_kms_key.hcm_master_key[0].id
  ) : null

  # Versioning for data integrity
  versioning = "Enabled"

  # Auto-tiering for cost optimization
  auto_tiering = "InfrequentAccess"
}

# Data source for Object Storage namespace
data "oci_objectstorage_namespace" "tenancy" {
  compartment_id = var.oci_tenancy_ocid
}
# HTH Guide Excerpt: end terraform
