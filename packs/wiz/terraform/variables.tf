# =============================================================================
# Wiz Hardening Code Pack - Variables
# How to Harden (howtoharden.com)
#
# Profile levels are cumulative: L2 includes L1, L3 includes L1+L2.
# Usage: terraform apply -var="profile_level=1"
# =============================================================================

# -----------------------------------------------------------------------------
# Profile Level
# -----------------------------------------------------------------------------

variable "profile_level" {
  description = "Hardening profile level: 1 = Baseline, 2 = Hardened, 3 = Maximum Security"
  type        = number
  default     = 1

  validation {
    condition     = var.profile_level >= 1 && var.profile_level <= 3
    error_message = "Profile level must be 1, 2, or 3."
  }
}

# -----------------------------------------------------------------------------
# Wiz Provider Configuration
# -----------------------------------------------------------------------------

variable "wiz_url" {
  description = "Wiz API endpoint URL (e.g., https://api.us1.app.wiz.io/graphql)"
  type        = string
}

variable "wiz_auth_client_id" {
  description = "Wiz service account client ID (Settings > Service Accounts)"
  type        = string
}

variable "wiz_auth_client_secret" {
  description = "Wiz service account client secret"
  type        = string
  sensitive   = true
}

variable "wiz_auth_audience" {
  description = "Wiz authentication audience"
  type        = string
  default     = "wiz-api"
}

# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA
# -----------------------------------------------------------------------------

variable "saml_idp_name" {
  description = "Display name for the SAML identity provider in Wiz"
  type        = string
  default     = "Corporate SSO"
}

variable "saml_login_url" {
  description = "SAML IdP login endpoint URL"
  type        = string
  default     = ""
}

variable "saml_certificate" {
  description = "PEM-encoded certificate from the identity provider"
  type        = string
  default     = ""
  sensitive   = true
}

variable "saml_issuer_url" {
  description = "SAML IdP issuer URL (defaults to login_url if empty)"
  type        = string
  default     = ""
}

variable "saml_logout_url" {
  description = "SAML IdP logout endpoint URL"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.2: Role-Based Access Control
# -----------------------------------------------------------------------------

variable "saml_idp_id" {
  description = "Wiz SAML IdP ID for group mapping (output from control 1.1)"
  type        = string
  default     = ""
}

variable "rbac_group_mappings" {
  description = "Map of SAML group IDs to Wiz roles for RBAC enforcement"
  type = list(object({
    provider_group_id = string
    role              = string
    projects          = optional(list(string), [])
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 2.1: Cloud Connector Security
# -----------------------------------------------------------------------------

variable "aws_connector_name" {
  description = "Name for the hardened AWS cloud connector"
  type        = string
  default     = "hth-aws-connector"
}

variable "aws_connector_role_arn" {
  description = "ARN of the least-privilege IAM role for the Wiz AWS connector"
  type        = string
  default     = ""
}

variable "aws_connector_regions" {
  description = "AWS regions to scan (empty list = all regions)"
  type        = list(string)
  default     = []
}

variable "aws_connector_excluded_accounts" {
  description = "AWS account IDs to exclude from scanning"
  type        = list(string)
  default     = []
}

variable "gcp_connector_name" {
  description = "Name for the hardened GCP cloud connector"
  type        = string
  default     = "hth-gcp-connector"
}

variable "gcp_connector_organization_id" {
  description = "GCP organization ID for the Wiz connector"
  type        = string
  default     = ""
}

variable "gcp_connector_excluded_projects" {
  description = "GCP project IDs to exclude from scanning"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.1: Service Account Management
# -----------------------------------------------------------------------------

variable "service_accounts" {
  description = "Map of purpose-specific service accounts with minimum scopes"
  type = list(object({
    name   = string
    scopes = list(string)
  }))
  default = [
    {
      name   = "hth-siem-integration"
      scopes = ["read:issues", "read:vulnerabilities"]
    },
    {
      name   = "hth-ticketing-integration"
      scopes = ["read:issues"]
    }
  ]
}

# -----------------------------------------------------------------------------
# Section 3.2: API Access Monitoring (L2)
# -----------------------------------------------------------------------------

variable "api_audit_report_name" {
  description = "Name for the scheduled API access audit report"
  type        = string
  default     = "HTH API Access Audit"
}

variable "api_audit_interval_hours" {
  description = "Interval in hours for the API audit report schedule"
  type        = number
  default     = 24
}

# -----------------------------------------------------------------------------
# Section 4.1: Data Export Controls (L2)
# -----------------------------------------------------------------------------

variable "data_export_project_name" {
  description = "Name for the data-export-restricted project"
  type        = string
  default     = "hth-data-export-restricted"
}

# -----------------------------------------------------------------------------
# Section 5.1: Audit Logging
# -----------------------------------------------------------------------------

variable "audit_report_name" {
  description = "Name for the scheduled audit log report"
  type        = string
  default     = "HTH Audit Log Report"
}

variable "audit_report_interval_hours" {
  description = "Interval in hours for the audit log report schedule"
  type        = number
  default     = 24
}
