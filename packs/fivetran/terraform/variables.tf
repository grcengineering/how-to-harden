# =============================================================================
# Fivetran Hardening Code Pack - Variables
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
# Fivetran Provider Configuration
# -----------------------------------------------------------------------------

variable "fivetran_api_key" {
  description = "Fivetran API key for authentication (found at Account Settings > API Config)"
  type        = string
  sensitive   = true
}

variable "fivetran_api_secret" {
  description = "Fivetran API secret for authentication (found at Account Settings > API Config)"
  type        = string
  sensitive   = true
}

variable "fivetran_account_id" {
  description = "Fivetran account ID (found at Account Settings > General)"
  type        = string
}

# -----------------------------------------------------------------------------
# Section 1.1: SAML Single Sign-On
# -----------------------------------------------------------------------------

variable "saml_idp_sso_url" {
  description = "Identity Provider SSO URL for SAML authentication"
  type        = string
  default     = ""
}

variable "saml_idp_entity_id" {
  description = "Identity Provider Entity ID for SAML authentication"
  type        = string
  default     = ""
}

variable "saml_x509_certificate" {
  description = "Base64-encoded X.509 certificate from the Identity Provider"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.2: Restrict Authentication to SSO (L2)
# -----------------------------------------------------------------------------

variable "sso_enforce_saml_only" {
  description = "Whether to restrict all authentication to SAML SSO only (disables password login)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 1.3: Just-In-Time Provisioning (L2)
# -----------------------------------------------------------------------------

variable "jit_provisioning_enabled" {
  description = "Whether to enable Just-In-Time user provisioning on SAML login"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 1.4: Session Timeout
# -----------------------------------------------------------------------------

variable "session_timeout_minutes" {
  description = "Session timeout in minutes (60 for L1, 30 for L2, 15 for L3)"
  type        = number
  default     = 60
}

# -----------------------------------------------------------------------------
# Section 2.1: Role-Based Access Control
# -----------------------------------------------------------------------------

variable "admin_user_ids" {
  description = "List of Fivetran user IDs that should have Account Administrator role (limit to 2-3)"
  type        = list(string)
  default     = []
}

variable "analyst_user_ids" {
  description = "List of Fivetran user IDs that should have read-only Analyst role"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 2.2: Team Structure (L2)
# -----------------------------------------------------------------------------

variable "teams" {
  description = "Map of team definitions with name and description"
  type = map(object({
    name        = string
    description = string
  }))
  default = {}
}

variable "team_user_memberships" {
  description = "Map of team ID to list of user IDs for team membership"
  type        = map(list(string))
  default     = {}
}

# -----------------------------------------------------------------------------
# Section 3.1: Connector Credential Security
# -----------------------------------------------------------------------------

variable "connectors" {
  description = "Map of connector configurations with service type and destination group"
  type = map(object({
    service         = string
    group_id        = string
    sync_frequency  = optional(number, 360)
    paused          = optional(bool, false)
    trust_certs     = optional(bool, true)
    trust_fpints    = optional(bool, true)
    run_setup_tests = optional(bool, true)
    config          = optional(map(string), {})
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 3.2: Network Security (L2)
# -----------------------------------------------------------------------------

variable "approved_fivetran_ip_cidrs" {
  description = "Fivetran IP addresses to allowlist on source systems (region-specific)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.3: Destination Security
# -----------------------------------------------------------------------------

variable "destination_group_id" {
  description = "Fivetran group ID for the primary destination"
  type        = string
  default     = ""
}

variable "destination_service" {
  description = "Destination service type (e.g., snowflake, bigquery, redshift)"
  type        = string
  default     = ""
}

variable "destination_config" {
  description = "Destination configuration key-value pairs"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Section 4.1: Activity Logging
# -----------------------------------------------------------------------------

variable "webhook_url" {
  description = "Webhook URL for Fivetran event notifications (e.g., SIEM ingestion endpoint)"
  type        = string
  default     = ""
}

variable "webhook_secret" {
  description = "Shared secret for webhook signature validation"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 4.2: Sync Monitoring
# -----------------------------------------------------------------------------

variable "notification_email_addresses" {
  description = "Email addresses to receive sync failure and event notifications"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 4.3: Data Governance (L2)
# -----------------------------------------------------------------------------

variable "blocked_columns" {
  description = "Map of connector ID to list of column names to block from sync (PII protection)"
  type        = map(list(string))
  default     = {}
}

variable "hashed_columns" {
  description = "Map of connector ID to list of column names to hash during sync"
  type        = map(list(string))
  default     = {}
}
