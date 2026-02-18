# =============================================================================
# HTH Oracle HCM Control 2.2: HCM Data Loader (HDL) Security
# Profile Level: L2 (Hardened)
# Frameworks: NIST SC-8
# Source: https://howtoharden.com/guides/oracle-hcm/#22-hcm-data-loader-hdl-security
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Dedicated IDCS group for users authorized to run HDL bulk operations
resource "oci_identity_domains_group" "hdl_authorized_users" {
  count = var.profile_level >= 2 ? 1 : 0

  idcs_endpoint = var.idcs_domain_url

  schemas      = ["urn:ietf:params:scim:schemas:core:2.0:Group"]
  display_name = var.hdl_authorized_group_name

  urnietfpaaboramsscaborimschemasoaboracleidcsextensiongroup_group {
    description = "Users authorized for HCM Data Loader bulk operations (L2)"
  }
}

# OCI IAM policy restricting HDL operations to the authorized group
resource "oci_identity_policy" "hdl_access_policy" {
  count = var.profile_level >= 2 ? 1 : 0

  compartment_id = var.oci_tenancy_ocid
  name           = "HTH-HCM-HDL-Restricted-Access"
  description    = "Restrict HCM Data Loader operations to authorized group (L2)"

  statements = [
    "Allow group '${var.idcs_compartment_id}'/'${var.hdl_authorized_group_name}' to manage hcm-data-loader in compartment id ${var.idcs_compartment_id}",
  ]
}

# L2: Sign-on policy requiring MFA for HDL operations
resource "oci_identity_domains_policy" "hdl_mfa_policy" {
  count = var.profile_level >= 2 ? 1 : 0

  idcs_endpoint = var.idcs_domain_url

  schemas     = ["urn:ietf:params:scim:schemas:oracle:idcs:Policy"]
  name        = "HTH-HCM-HDL-MFA-Policy"
  description = "Require MFA for all HCM Data Loader operations (L2)"
  active      = true
  policy_type {
    value = "SignOn"
  }

  rules {
    name     = "RequireMFAForHDL"
    sequence = 1
    return {
      name  = "mfaRequired"
      value = "true"
    }
    return {
      name  = "allowAccess"
      value = "true"
    }
  }
}

# L3: OCI Event Rule to detect HDL file uploads and trigger notifications
resource "oci_events_rule" "hdl_upload_detection" {
  count = var.profile_level >= 3 ? 1 : 0

  compartment_id = var.oci_tenancy_ocid
  display_name   = "HTH-HCM-HDL-Upload-Detection"
  description    = "Detect HCM Data Loader file uploads for approval workflow (L3)"
  is_enabled     = true

  condition = jsonencode({
    eventType = ["com.oraclecloud.fusionapps.hcm.hdl.fileupload"]
  })

  actions {
    actions {
      action_type = "ONS"
      is_enabled  = true
      topic_id    = var.alarm_notification_topic_id != "" ? var.alarm_notification_topic_id : oci_ons_notification_topic.hcm_security_alerts[0].id
    }
  }
}
# HTH Guide Excerpt: end terraform
