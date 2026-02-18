# =============================================================================
# SAP SuccessFactors Hardening Code Pack - Variables
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
# SAP BTP Provider Configuration
# -----------------------------------------------------------------------------

variable "btp_globalaccount" {
  description = "SAP BTP global account subdomain"
  type        = string
}

variable "btp_cli_server_url" {
  description = "SAP BTP CLI server URL (default: https://cli.btp.cloud.sap)"
  type        = string
  default     = "https://cli.btp.cloud.sap"
}

variable "btp_username" {
  description = "SAP BTP username for provider authentication"
  type        = string
}

variable "btp_password" {
  description = "SAP BTP password for provider authentication"
  type        = string
  sensitive   = true
}

variable "btp_subaccount_id" {
  description = "SAP BTP subaccount ID where SuccessFactors is provisioned"
  type        = string
}


# -----------------------------------------------------------------------------
# Section 1.1: SSO with MFA
# -----------------------------------------------------------------------------

variable "idp_metadata_url" {
  description = "SAML IdP metadata URL for SSO configuration"
  type        = string
  default     = ""
}

variable "idp_name" {
  description = "Display name for the Identity Provider"
  type        = string
  default     = "Corporate IdP"
}

variable "enforce_sso" {
  description = "Whether to enforce SSO for all users (disable password fallback)"
  type        = bool
  default     = true
}


# -----------------------------------------------------------------------------
# Section 1.2: Role-Based Permissions (RBP)
# -----------------------------------------------------------------------------

variable "admin_users" {
  description = "List of user IDs granted System Admin role (keep minimal)"
  type        = list(string)
  default     = []
}

variable "hr_admin_users" {
  description = "List of user IDs granted HR Admin role"
  type        = list(string)
  default     = []
}


# -----------------------------------------------------------------------------
# Section 2.1: OData API Security
# -----------------------------------------------------------------------------

variable "oauth_client_name" {
  description = "Name for the dedicated OData API OAuth client"
  type        = string
  default     = "hth-integration-client"
}

variable "api_allowed_ip_cidrs" {
  description = "CIDR ranges allowed to access OData APIs (L2+ only)"
  type        = list(string)
  default     = []
}


# -----------------------------------------------------------------------------
# Section 2.2: OAuth Token Management
# -----------------------------------------------------------------------------

variable "access_token_validity_seconds" {
  description = "OAuth access token validity in seconds (3600 = 1 hour)"
  type        = number
  default     = 3600
}

variable "refresh_token_validity_seconds" {
  description = "OAuth refresh token validity in seconds (86400 = 24h L1, 28800 = 8h L2)"
  type        = number
  default     = 86400
}


# -----------------------------------------------------------------------------
# Section 3.1: Data Privacy
# -----------------------------------------------------------------------------

variable "data_retention_days" {
  description = "Number of days to retain employee data after termination"
  type        = number
  default     = 365
}

variable "mask_sensitive_fields" {
  description = "Enable masking of sensitive fields (SSN, Tax ID) in UI and API"
  type        = bool
  default     = true
}

variable "sensitive_field_names" {
  description = "List of sensitive field names to mask (L2+ adds additional fields)"
  type        = list(string)
  default     = ["ssn", "tax_id", "national_id"]
}


# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

variable "audit_retention_days" {
  description = "Number of days to retain audit logs (365 for L1, 730 for L2, 1095 for L3)"
  type        = number
  default     = 365
}

variable "siem_webhook_url" {
  description = "Webhook URL for forwarding audit events to SIEM (L2+ only)"
  type        = string
  default     = ""
}
