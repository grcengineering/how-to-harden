# =============================================================================
# HTH Oracle HCM Control 3.2: Data Retention and Purge
# Profile Level: L1 (Baseline)
# Frameworks: NIST SI-12
# Source: https://howtoharden.com/guides/oracle-hcm/#32-data-retention-and-purge
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Object lifecycle policy for automated data retention and purge
resource "oci_objectstorage_object_lifecycle_policy" "hcm_data_retention" {
  namespace  = data.oci_objectstorage_namespace.tenancy.namespace
  bucket     = oci_objectstorage_bucket.hcm_secure_exports.name

  rules {
    name        = "HTH-HCM-Archive-Old-Exports"
    action      = "ARCHIVE"
    target      = "objects"
    is_enabled  = true
    time_amount = 90
    time_unit   = "DAYS"
  }

  rules {
    name        = "HTH-HCM-Delete-Expired-Data"
    action      = "DELETE"
    target      = "objects"
    is_enabled  = true
    time_amount = var.audit_retention_days
    time_unit   = "DAYS"
  }

  rules {
    name        = "HTH-HCM-Cleanup-Previous-Versions"
    action      = "DELETE"
    target      = "previous-object-versions"
    is_enabled  = true
    time_amount = 30
    time_unit   = "DAYS"
  }
}

# OCI Logging Analytics log group for centralized audit log retention
resource "oci_log_analytics_log_group" "hcm_audit_logs" {
  compartment_id = var.idcs_compartment_id
  namespace      = data.oci_objectstorage_namespace.tenancy.namespace
  display_name   = "HTH-HCM-Audit-Logs"
  description    = "Centralized log group for Oracle HCM Cloud audit log retention"
}

# IAM policy for log analytics access
resource "oci_identity_policy" "hcm_log_analytics_policy" {
  compartment_id = var.oci_tenancy_ocid
  name           = "HTH-HCM-Log-Analytics-Access"
  description    = "Grant HCM service access to log analytics for audit retention"

  statements = [
    "Allow dynamic-group '${var.idcs_compartment_id}'/HTH-HCM-Service-Instances to use log-analytics-log-group in compartment id ${var.idcs_compartment_id}",
    "Allow group '${var.idcs_compartment_id}'/'${var.it_security_manager_group_name}' to read log-analytics-log-group in compartment id ${var.idcs_compartment_id}",
  ]
}

# L2: Object Storage bucket for GDPR data subject access request exports
resource "oci_objectstorage_bucket" "hcm_dsar_exports" {
  count = var.profile_level >= 2 ? 1 : 0

  compartment_id = var.idcs_compartment_id
  namespace      = data.oci_objectstorage_namespace.tenancy.namespace
  name           = "hth-hcm-dsar-exports"

  kms_key_id = var.profile_level >= 2 ? (
    var.oci_key_id != "" ? var.oci_key_id : oci_kms_key.hcm_master_key[0].id
  ) : null

  versioning = "Enabled"
}

# L2: Lifecycle policy for DSAR export data (30-day auto-purge)
resource "oci_objectstorage_object_lifecycle_policy" "dsar_retention" {
  count = var.profile_level >= 2 ? 1 : 0

  namespace = data.oci_objectstorage_namespace.tenancy.namespace
  bucket    = oci_objectstorage_bucket.hcm_dsar_exports[0].name

  rules {
    name        = "HTH-HCM-DSAR-Auto-Purge"
    action      = "DELETE"
    target      = "objects"
    is_enabled  = true
    time_amount = 30
    time_unit   = "DAYS"
  }
}
# HTH Guide Excerpt: end terraform
