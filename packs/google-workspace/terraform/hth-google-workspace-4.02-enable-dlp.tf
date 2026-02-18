# =============================================================================
# HTH Google Workspace Control 4.2: Enable Data Loss Prevention (DLP)
# Profile Level: L2 (Hardened)
# Frameworks: CIS 3.1/3.2, NIST SC-8/SC-28
# Source: https://howtoharden.com/guides/google-workspace/#42-enable-data-loss-prevention-dlp
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Google Workspace DLP uses the Cloud DLP API to detect sensitive data
# in Drive, Chat, and other Workspace services.  DLP requires Google
# Workspace Enterprise Standard or Plus.
#
# This creates a Cloud DLP inspect template with common PII detectors
# and a job trigger for scheduled scanning.  The actual Workspace DLP
# rules (block sharing, warn user) must be configured in:
#   Admin Console > Security > Data protection > Manage Rules

# DLP inspect template with common sensitive data detectors
resource "google_data_loss_prevention_inspect_template" "workspace_pii" {
  count = var.profile_level >= 2 && var.gcp_project_id != "" ? 1 : 0

  parent       = "projects/${var.gcp_project_id}"
  display_name = "HTH Workspace PII Template"
  description  = "HTH 4.2 -- Detects PII (SSN, credit cards, email addresses) in Workspace content"

  inspect_config {
    info_types {
      name = "US_SOCIAL_SECURITY_NUMBER"
    }
    info_types {
      name = "CREDIT_CARD_NUMBER"
    }
    info_types {
      name = "EMAIL_ADDRESS"
    }
    info_types {
      name = "PHONE_NUMBER"
    }
    info_types {
      name = "US_PASSPORT"
    }
    info_types {
      name = "US_DRIVERS_LICENSE_NUMBER"
    }

    min_likelihood = "LIKELY"

    limits {
      max_findings_per_request = 100
    }
  }
}

# L3: Extended DLP template with financial and healthcare data types
resource "google_data_loss_prevention_inspect_template" "workspace_regulated" {
  count = var.profile_level >= 3 && var.gcp_project_id != "" ? 1 : 0

  parent       = "projects/${var.gcp_project_id}"
  display_name = "HTH Workspace Regulated Data Template"
  description  = "HTH 4.2 L3 -- Detects regulated data (HIPAA, PCI) in Workspace content"

  inspect_config {
    info_types {
      name = "US_SOCIAL_SECURITY_NUMBER"
    }
    info_types {
      name = "CREDIT_CARD_NUMBER"
    }
    info_types {
      name = "CREDIT_CARD_TRACK_NUMBER"
    }
    info_types {
      name = "US_BANK_ROUTING_MICR"
    }
    info_types {
      name = "US_DEA_NUMBER"
    }
    info_types {
      name = "US_HEALTHCARE_NPI"
    }
    info_types {
      name = "IBAN_CODE"
    }
    info_types {
      name = "SWIFT_CODE"
    }
    info_types {
      name = "US_INDIVIDUAL_TAXPAYER_IDENTIFICATION_NUMBER"
    }

    min_likelihood = "POSSIBLE"

    limits {
      max_findings_per_request = 500
    }
  }
}

# Group for DLP incident notifications
resource "googleworkspace_group" "dlp_incidents" {
  count = var.profile_level >= 2 ? 1 : 0

  email       = "dlp-incidents@${var.primary_domain}"
  name        = "DLP Incidents"
  description = "HTH 4.2 -- Receives notifications when DLP rules are triggered"
}
# HTH Guide Excerpt: end terraform
