# =============================================================================
# Datadog Hardening Code Pack - Variables
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
# Datadog Provider Configuration
# -----------------------------------------------------------------------------

variable "datadog_api_key" {
  description = "Datadog API key for authentication (found at Organization Settings > API Keys)"
  type        = string
  sensitive   = true
}

variable "datadog_app_key" {
  description = "Datadog Application key for API access (found at Organization Settings > Application Keys)"
  type        = string
  sensitive   = true
}

variable "datadog_api_url" {
  description = "Datadog API URL (https://api.datadoghq.com for US1, https://api.datadoghq.eu for EU, etc.)"
  type        = string
  default     = "https://api.datadoghq.com"
}

# -----------------------------------------------------------------------------
# Section 1.1: SAML Single Sign-On
# -----------------------------------------------------------------------------

variable "saml_idp_metadata_url" {
  description = "URL to the SAML IdP metadata XML document"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 1.2: SAML Strict Mode (L2)
# -----------------------------------------------------------------------------

variable "saml_strict_mode_enabled" {
  description = "Whether to enforce SAML strict mode (disables password and Google login)"
  type        = bool
  default     = true
}

variable "saml_autocreate_users_domains" {
  description = "List of email domains for SAML auto-provisioned users (e.g., ['example.com'])"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 1.3: Session Security
# -----------------------------------------------------------------------------

variable "session_idle_timeout_minutes" {
  description = "Idle session timeout in minutes (30 for L1, 15 for L2/L3)"
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# Section 2.1: Role-Based Access Control
# -----------------------------------------------------------------------------

variable "custom_roles" {
  description = "Map of custom role definitions with name and permission list"
  type = map(object({
    name        = string
    permissions = list(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 3.1: API Key Security
# -----------------------------------------------------------------------------

variable "api_key_names" {
  description = "List of purpose-specific API key names to create (e.g., ['prod-agent', 'staging-agent'])"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.2: Application Key Security
# -----------------------------------------------------------------------------

variable "app_key_names" {
  description = "List of purpose-specific application key names to create (e.g., ['ci-cd-pipeline', 'terraform'])"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Log Monitoring
# -----------------------------------------------------------------------------

variable "audit_alert_recipients" {
  description = "List of notification targets for audit alerts (e.g., ['@slack-security', '@pagerduty-oncall'])"
  type        = list(string)
  default     = []
}
