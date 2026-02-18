# =============================================================================
# Google Workspace Hardening Code Pack - Variables
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
# Google Workspace Provider Configuration
# -----------------------------------------------------------------------------

variable "customer_id" {
  description = "Google Workspace customer ID (found in Admin Console > Account > Account settings)"
  type        = string
}

variable "credentials_file" {
  description = "Path to the service account JSON key file"
  type        = string
  sensitive   = true
}

variable "service_account_email" {
  description = "Service account email with domain-wide delegation"
  type        = string
}

variable "impersonated_user_email" {
  description = "Super Admin email to impersonate for API calls"
  type        = string
}

variable "primary_domain" {
  description = "Primary domain for the Google Workspace organization (e.g., example.com)"
  type        = string
}

# -----------------------------------------------------------------------------
# Google Cloud Provider Configuration
# Used for Access Context Manager, DLP, and BigQuery resources
# -----------------------------------------------------------------------------

variable "gcp_project_id" {
  description = "GCP project ID for Access Context Manager, DLP, and log export resources"
  type        = string
  default     = ""
}

variable "organization_id" {
  description = "Google Cloud organization ID (required for Access Context Manager at L2+)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.1: Multi-Factor Authentication
# -----------------------------------------------------------------------------

variable "mfa_enforcement_grace_period_days" {
  description = "Number of days new users have to enroll in 2SV before enforcement"
  type        = number
  default     = 7
}

# -----------------------------------------------------------------------------
# Section 1.2: Super Admin Governance
# -----------------------------------------------------------------------------

variable "delegated_admin_roles" {
  description = "Map of delegated admin role names to their privilege sets"
  type = map(object({
    description = string
    privileges = list(object({
      service_id = string
      privilege  = string
    }))
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 2.1: Network Access Controls (L2+)
# -----------------------------------------------------------------------------

variable "access_policy_name" {
  description = "Access Context Manager policy name (one per organization)"
  type        = string
  default     = "hth-google-workspace-access-policy"
}

variable "admin_allowed_cidrs" {
  description = "List of CIDR ranges allowed to access Admin Console (L2+)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.1: OAuth App Whitelisting
# -----------------------------------------------------------------------------

variable "trusted_oauth_app_ids" {
  description = "List of OAuth client IDs to trust (allow full access)"
  type        = list(string)
  default     = []
}

variable "limited_oauth_app_ids" {
  description = "List of OAuth client IDs to allow with limited (non-sensitive) scopes only"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 4.1: External Drive Sharing
# -----------------------------------------------------------------------------

variable "allowed_external_domains" {
  description = "List of external domains allowed for Drive file sharing (empty = no external sharing)"
  type        = list(string)
  default     = []
}

variable "target_org_unit_path" {
  description = "Organizational unit path for applying Drive sharing restrictions (e.g., '/' for root)"
  type        = string
  default     = "/"
}

# -----------------------------------------------------------------------------
# Section 4.2: Data Loss Prevention (L2+)
# -----------------------------------------------------------------------------

variable "dlp_inspect_template_id" {
  description = "Existing DLP inspect template ID (leave empty to create default template)"
  type        = string
  default     = ""
}

variable "dlp_notification_emails" {
  description = "Email addresses to notify on DLP policy violations (L2+)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 5.1: Audit Logging
# -----------------------------------------------------------------------------

variable "bigquery_dataset_id" {
  description = "BigQuery dataset ID for audit log export (leave empty to create one)"
  type        = string
  default     = "google_workspace_audit_logs"
}

variable "log_retention_days" {
  description = "Number of days to retain audit logs in BigQuery"
  type        = number
  default     = 365
}

variable "alert_notification_emails" {
  description = "Email addresses to receive security alert notifications"
  type        = list(string)
  default     = []
}
