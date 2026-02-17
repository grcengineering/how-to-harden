# =============================================================================
# HTH Terraform Cloud Control 5.01: Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: NIST AU-2, AU-3
# Source: https://howtoharden.com/guides/terraform-cloud/#51-audit-logging
# =============================================================================

terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.62"
    }
  }
}

variable "tfc_organization" {
  description = "Terraform Cloud organization name"
  type        = string
}

variable "tfc_email" {
  description = "Organization billing/admin email"
  type        = string
}

# HTH Guide Excerpt: begin terraform
# Organization-level settings with audit trail URL
# Audit logs are available at:
#   https://app.terraform.io/api/v2/organization/audit-trail
# Enterprise customers can configure streaming to external SIEM.
resource "tfe_organization" "main" {
  name  = var.tfc_organization
  email = var.tfc_email

  # Require 2FA for all organization members
  collaborator_auth_policy = "two_factor_mandatory"
}

# Audit trail data source -- verify logging is accessible
data "http" "audit_trail_check" {
  url = "https://app.terraform.io/api/v2/organization/audit-trail?since=${formatdate("YYYY-MM-DD", timeadd(timestamp(), "-24h"))}"

  request_headers = {
    Authorization = "Bearer ${var.tfc_token}"
    Content-Type  = "application/vnd.api+json"
  }
}

variable "tfc_token" {
  description = "Terraform Cloud API token for audit trail verification"
  type        = string
  sensitive   = true
}

output "audit_trail_status" {
  description = "HTTP status of audit trail endpoint"
  value       = data.http.audit_trail_check.status_code
}
# HTH Guide Excerpt: end terraform
