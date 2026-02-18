# =============================================================================
# HTH SAP SuccessFactors Control 3.1: Configure Data Privacy
# Profile Level: L1 (Baseline)
# Frameworks: NIST SC-28
# Source: https://howtoharden.com/guides/sap-successfactors/#31-configure-data-privacy
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enable the Data Privacy Integration service for SuccessFactors
resource "btp_subaccount_entitlement" "data_privacy" {
  subaccount_id = var.btp_subaccount_id
  service_name  = "data-privacy-integration-service"
  plan_name     = "standard"
}

resource "btp_subaccount_service_instance" "data_privacy" {
  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-data-privacy"
  serviceplan_id = data.btp_subaccount_service_plan.dpi_standard.id
  parameters = jsonencode({
    xs-security = {
      xsappname   = "hth-sf-dpi"
      tenant-mode = "dedicated"
    }
    retention = {
      # Data retention period after employee termination
      defaultRetentionDays = var.data_retention_days
    }
  })

  depends_on = [btp_subaccount_entitlement.data_privacy]
}

data "btp_subaccount_service_plan" "dpi_standard" {
  subaccount_id = var.btp_subaccount_id
  name          = "standard"
  offering_name = "data-privacy-integration-service"
}

# L1: Create role collection for data privacy officers
resource "btp_subaccount_role_collection" "data_privacy_officer" {
  subaccount_id = var.btp_subaccount_id
  name          = "HTH SF Data Privacy Officer"
  description   = "HTH: Manages data protection, consent, and retention policies"

  roles {
    name                 = "Subaccount Viewer"
    role_template_app_id = "cis-local!b2"
    role_template_name   = "Subaccount_Viewer"
  }
}

# L2+: Enable Personal Data Manager for field-level security
resource "btp_subaccount_entitlement" "personal_data_manager" {
  count = var.profile_level >= 2 ? 1 : 0

  subaccount_id = var.btp_subaccount_id
  service_name  = "personal-data-manager-service"
  plan_name     = "standard"
}

resource "btp_subaccount_service_instance" "personal_data_manager" {
  count = var.profile_level >= 2 ? 1 : 0

  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-pdm"
  serviceplan_id = data.btp_subaccount_service_plan.pdm_standard[0].id
  parameters = jsonencode({
    xs-security = {
      xsappname   = "hth-sf-pdm"
      tenant-mode = "dedicated"
    }
    sensitiveFields = var.sensitive_field_names
    masking = {
      enabled        = var.mask_sensitive_fields
      maskCharacter  = "*"
      visibleChars   = 4
    }
  })

  depends_on = [btp_subaccount_entitlement.personal_data_manager]
}

data "btp_subaccount_service_plan" "pdm_standard" {
  count = var.profile_level >= 2 ? 1 : 0

  subaccount_id = var.btp_subaccount_id
  name          = "standard"
  offering_name = "personal-data-manager-service"
}

# L3: Enable data residency enforcement (restrict data to specific regions)
resource "btp_subaccount_service_instance" "data_residency" {
  count = var.profile_level >= 3 ? 1 : 0

  subaccount_id  = var.btp_subaccount_id
  name           = "hth-sf-data-residency"
  serviceplan_id = data.btp_subaccount_service_plan.dpi_standard.id
  parameters = jsonencode({
    xs-security = {
      xsappname   = "hth-sf-data-residency"
      tenant-mode = "dedicated"
    }
    retention = {
      defaultRetentionDays = var.data_retention_days
    }
    dataResidency = {
      enforced = true
    }
  })
}
# HTH Guide Excerpt: end terraform
