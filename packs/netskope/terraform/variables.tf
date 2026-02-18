# =============================================================================
# Netskope Hardening Code Pack - Variables
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
# Netskope Provider Configuration
# -----------------------------------------------------------------------------

variable "netskope_server_url" {
  description = "Netskope tenant API v2 endpoint (e.g., https://your-tenant.goskope.com/api/v2)"
  type        = string
}

variable "netskope_api_key" {
  description = "Netskope REST API v2 token for provider authentication"
  type        = string
  sensitive   = true
}

variable "netskope_tenant_url" {
  description = "Netskope tenant base URL without /api/v2 (e.g., https://your-tenant.goskope.com) used for REST API calls"
  type        = string
}

# -----------------------------------------------------------------------------
# Section 1.1: Admin Console Access
# -----------------------------------------------------------------------------

variable "admin_sso_idp_entity_id" {
  description = "SAML IdP entity ID for admin SSO configuration"
  type        = string
  default     = ""
}

variable "admin_sso_idp_sso_url" {
  description = "SAML IdP single sign-on URL for admin SSO"
  type        = string
  default     = ""
}

variable "admin_sso_idp_certificate" {
  description = "Base64-encoded SAML IdP signing certificate"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.2: Tenant Hardening
# -----------------------------------------------------------------------------

variable "session_timeout_minutes" {
  description = "Admin console session timeout in minutes (15 for L1, 10 for L2/L3)"
  type        = number
  default     = 15
}

variable "admin_ip_allowlist" {
  description = "List of CIDRs allowed to access the admin console (L2+)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 2.1: Application Visibility
# -----------------------------------------------------------------------------

variable "cci_high_risk_threshold" {
  description = "Cloud Confidence Index score below which apps are considered high risk"
  type        = number
  default     = 50
}

variable "cci_medium_risk_threshold" {
  description = "Cloud Confidence Index score below which apps are considered medium risk"
  type        = number
  default     = 70
}

# -----------------------------------------------------------------------------
# Section 2.2: Real-Time Protection Policies
# -----------------------------------------------------------------------------

variable "block_unsanctioned_apps" {
  description = "Whether to create a policy blocking high-risk unsanctioned cloud apps"
  type        = bool
  default     = true
}

variable "block_personal_instances" {
  description = "Whether to block uploads/shares to personal instances of cloud apps"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 3.1: DLP Profiles
# -----------------------------------------------------------------------------

variable "dlp_credit_card_enabled" {
  description = "Enable DLP detection for credit card numbers"
  type        = bool
  default     = true
}

variable "dlp_ssn_enabled" {
  description = "Enable DLP detection for Social Security numbers"
  type        = bool
  default     = true
}

variable "dlp_api_keys_enabled" {
  description = "Enable DLP detection for API keys and credentials"
  type        = bool
  default     = true
}

variable "dlp_custom_patterns" {
  description = "List of custom regex patterns for DLP detection (e.g., project codes)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 4.1: Malware Protection
# -----------------------------------------------------------------------------

variable "sandbox_enabled" {
  description = "Enable cloud sandboxing for unknown files (requires SSE Professional+)"
  type        = bool
  default     = true
}

variable "sandbox_file_types" {
  description = "File types to submit to cloud sandbox"
  type        = list(string)
  default     = ["exe", "dll", "pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "zip", "rar"]
}

# -----------------------------------------------------------------------------
# Section 4.2: Threat Protection Policies (L2)
# -----------------------------------------------------------------------------

variable "block_newly_registered_domains" {
  description = "Block access to newly registered domains (L2+)"
  type        = bool
  default     = true
}

variable "block_uncategorized_sites" {
  description = "Block access to uncategorized websites (L2+)"
  type        = bool
  default     = false
}

variable "enable_behavior_analytics" {
  description = "Enable cloud behavior analytics for anomaly detection (L2+)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 5.1: Steering Configuration
# -----------------------------------------------------------------------------

variable "steering_mode" {
  description = "Default traffic steering mode: all_traffic, web_traffic, or cloud_apps"
  type        = string
  default     = "all_traffic"

  validation {
    condition     = contains(["all_traffic", "web_traffic", "cloud_apps"], var.steering_mode)
    error_message = "Steering mode must be all_traffic, web_traffic, or cloud_apps."
  }
}

variable "cert_pinned_domains" {
  description = "List of certificate-pinned domains to exclude from SSL inspection (Do Not Steer)"
  type        = list(string)
  default     = []
}

variable "fail_close" {
  description = "Enable fail-close mode on Netskope Client (true = maximum security, false = fail-open for availability)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 5.2: Client Deployment
# -----------------------------------------------------------------------------

variable "client_auto_update" {
  description = "Enable automatic Netskope Client updates"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 6.1: Logging and Alerts
# -----------------------------------------------------------------------------

variable "siem_type" {
  description = "SIEM integration type: splunk, sentinel, syslog, or none"
  type        = string
  default     = "none"

  validation {
    condition     = contains(["splunk", "sentinel", "syslog", "none"], var.siem_type)
    error_message = "SIEM type must be splunk, sentinel, syslog, or none."
  }
}

variable "siem_endpoint" {
  description = "SIEM endpoint URL or syslog destination (host:port)"
  type        = string
  default     = ""
}

variable "siem_token" {
  description = "SIEM authentication token (e.g., Splunk HEC token)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "alert_on_dlp_violations" {
  description = "Enable alerts for DLP policy violations"
  type        = bool
  default     = true
}

variable "alert_on_malware" {
  description = "Enable alerts for malware detection events"
  type        = bool
  default     = true
}

variable "alert_on_policy_violations" {
  description = "Enable alerts for policy violations"
  type        = bool
  default     = true
}

variable "alert_on_admin_changes" {
  description = "Enable alerts for admin configuration changes"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 2.3: API Protection (L2)
# -----------------------------------------------------------------------------

variable "api_protection_apps" {
  description = "List of SaaS applications to connect for API-enabled protection (L2+)"
  type        = list(string)
  default     = []
}

variable "api_scan_frequency" {
  description = "API protection scan frequency: continuous or scheduled"
  type        = string
  default     = "continuous"

  validation {
    condition     = contains(["continuous", "scheduled"], var.api_scan_frequency)
    error_message = "API scan frequency must be continuous or scheduled."
  }
}
