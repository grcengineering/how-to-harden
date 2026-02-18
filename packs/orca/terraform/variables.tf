# =============================================================================
# Orca Security Hardening Code Pack - Variables
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
# Orca Provider Configuration
# -----------------------------------------------------------------------------

variable "orca_api_endpoint" {
  description = "Orca Security API endpoint (e.g., https://api.orcasecurity.io)"
  type        = string
  default     = "https://api.orcasecurity.io"
}

variable "orca_api_token" {
  description = "Orca Security API token for provider authentication"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: SAML SSO Configuration
# -----------------------------------------------------------------------------

variable "sso_group_name" {
  description = "Name for the SSO user group in Orca"
  type        = string
  default     = "SSO Users"
}

variable "sso_user_ids" {
  description = "List of Orca user IDs to include in the SSO group"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 2.1: Role-Based Access Control
# -----------------------------------------------------------------------------

variable "readonly_role_name" {
  description = "Name for the read-only analyst custom role"
  type        = string
  default     = "Security Analyst (Read-Only)"
}

variable "readonly_permissions" {
  description = "Permission groups for the read-only analyst role"
  type        = list(string)
  default = [
    "assets.asset.read",
    "alerts.alert.read",
    "dashboard.view.read",
    "compliance.report.read"
  ]
}

variable "viewer_role_name" {
  description = "Name for the viewer custom role (minimal permissions)"
  type        = string
  default     = "Viewer"
}

variable "viewer_permissions" {
  description = "Permission groups for the viewer role"
  type        = list(string)
  default = [
    "assets.asset.read",
    "dashboard.view.read"
  ]
}

# -----------------------------------------------------------------------------
# Section 2.2: Account Scope (L2)
# -----------------------------------------------------------------------------

variable "business_unit_name" {
  description = "Name for the scoped business unit (L2+)"
  type        = string
  default     = "Production Environment"
}

variable "business_unit_cloud_providers" {
  description = "Cloud providers to include in the scoped business unit (L2+)"
  type        = list(string)
  default     = ["aws"]
}

variable "business_unit_cloud_tags" {
  description = "Cloud tags to filter the scoped business unit (L2+, format: 'key|value')"
  type        = list(string)
  default     = []
}

variable "restricted_business_unit_name" {
  description = "Name for the restricted production business unit (L3)"
  type        = string
  default     = "Production - Restricted"
}

variable "restricted_cloud_tags" {
  description = "Cloud tags for restricted production business unit (L3, format: 'key|value')"
  type        = list(string)
  default     = ["env|production"]
}

# -----------------------------------------------------------------------------
# Section 2.3: Limit Admin Access
# -----------------------------------------------------------------------------

variable "admin_group_name" {
  description = "Name for the admin group in Orca"
  type        = string
  default     = "Platform Admins"
}

variable "admin_user_ids" {
  description = "List of Orca user IDs for admin users (limit to 2-3)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.1: Cloud Account Security
# -----------------------------------------------------------------------------

variable "trusted_cloud_accounts" {
  description = "List of trusted cloud accounts for Orca integrations"
  type = list(object({
    account_name      = string
    description       = string
    cloud_provider    = string
    cloud_provider_id = string
  }))
  default = []
}

# -----------------------------------------------------------------------------
# Section 3.2: API Security (L2)
# -----------------------------------------------------------------------------

variable "api_alert_name" {
  description = "Name for the API key usage monitoring alert (L2+)"
  type        = string
  default     = "Unused API Keys Detected"
}

variable "api_alert_score" {
  description = "Orca score for the API key monitoring alert (L2+)"
  type        = number
  default     = 7.0
}

variable "enable_api_automation" {
  description = "Enable automation to notify on API security findings (L2+)"
  type        = bool
  default     = true
}

variable "api_alert_emails" {
  description = "Email addresses for API security alert notifications (L2+)"
  type        = list(string)
  default     = []
}
