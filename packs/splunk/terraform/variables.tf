# =============================================================================
# Splunk Hardening Code Pack - Variables
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
# Splunk Provider Configuration
# -----------------------------------------------------------------------------

variable "splunk_url" {
  description = "Splunk management URL (e.g., https://your-instance:8089)"
  type        = string
}

variable "splunk_username" {
  description = "Splunk admin username (used if auth_token is empty)"
  type        = string
  default     = ""
}

variable "splunk_password" {
  description = "Splunk admin password (used if auth_token is empty)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "splunk_auth_token" {
  description = "Splunk authentication token (preferred over username/password)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "splunk_insecure_skip_verify" {
  description = "Skip TLS certificate verification (set true only for dev/test)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 1.1: SAML SSO Configuration
# -----------------------------------------------------------------------------

variable "saml_idp_url" {
  description = "SAML IdP Single Sign-On URL"
  type        = string
  default     = ""
}

variable "saml_idp_cert_path" {
  description = "Path to SAML IdP certificate PEM file"
  type        = string
  default     = ""
}

variable "saml_entity_id" {
  description = "SAML Entity ID / Issuer from IdP"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.2: Local Admin Fallback
# -----------------------------------------------------------------------------

variable "local_admin_username" {
  description = "Username for the local emergency admin account"
  type        = string
  default     = "hth-emergency-admin"
}

variable "local_admin_password" {
  description = "Strong password for the local emergency admin (20+ characters)"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 2.1: Role-Based Access Control
# -----------------------------------------------------------------------------

variable "custom_analyst_role_name" {
  description = "Name for the custom security analyst role"
  type        = string
  default     = "hth_security_analyst"
}

variable "analyst_allowed_indexes" {
  description = "Indexes the security analyst role can search"
  type        = list(string)
  default     = ["main", "security"]
}

variable "analyst_default_index" {
  description = "Default index for the security analyst role"
  type        = string
  default     = "security"
}

# -----------------------------------------------------------------------------
# Section 2.2: Index Access Controls
# -----------------------------------------------------------------------------

variable "security_index_name" {
  description = "Name for the dedicated security log index"
  type        = string
  default     = "security"
}

variable "security_index_max_data_size" {
  description = "Maximum size of hot/warm bucket in MB (auto = 750MB)"
  type        = string
  default     = "auto"
}

variable "security_index_frozen_time_period" {
  description = "Seconds before data is frozen (default: 94608000 = 3 years)"
  type        = number
  default     = 94608000
}

# -----------------------------------------------------------------------------
# Section 3.1: Search Security (L2)
# -----------------------------------------------------------------------------

variable "search_quota_standard" {
  description = "Maximum concurrent searches for standard users"
  type        = number
  default     = 3
}

variable "search_quota_power" {
  description = "Maximum concurrent searches for power users"
  type        = number
  default     = 6
}

variable "search_time_limit_seconds" {
  description = "Maximum search execution time in seconds (L2: 600, L3: 300)"
  type        = number
  default     = 600
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

variable "audit_index_name" {
  description = "Index name for audit trail data"
  type        = string
  default     = "audit_trail"
}

variable "audit_index_frozen_time_period" {
  description = "Seconds before audit data is frozen (default: 220752000 = 7 years)"
  type        = number
  default     = 220752000
}

# -----------------------------------------------------------------------------
# Section 3.2: Encryption - HEC Configuration (L2)
# -----------------------------------------------------------------------------

variable "hec_enable_ssl" {
  description = "Require SSL for HTTP Event Collector endpoints"
  type        = bool
  default     = true
}

variable "hec_port" {
  description = "Port for HTTP Event Collector"
  type        = number
  default     = 8088
}
