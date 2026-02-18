# =============================================================================
# New Relic Hardening Code Pack - Variables
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
# New Relic Provider Configuration
# -----------------------------------------------------------------------------

variable "newrelic_account_id" {
  description = "New Relic account ID (numeric)"
  type        = number
}

variable "newrelic_api_key" {
  description = "New Relic User API key (NRAK-...) for provider authentication"
  type        = string
  sensitive   = true
}

variable "newrelic_region" {
  description = "New Relic region: US or EU"
  type        = string
  default     = "US"

  validation {
    condition     = contains(["US", "EU"], var.newrelic_region)
    error_message = "Region must be US or EU."
  }
}

# -----------------------------------------------------------------------------
# Section 2.1: API Key Management
# -----------------------------------------------------------------------------

variable "api_key_user_id" {
  description = "New Relic user ID to associate with managed API keys"
  type        = number
  default     = 0
}

variable "ingest_key_name" {
  description = "Name for the managed ingest (license) key"
  type        = string
  default     = "hth-managed-ingest-key"
}

# -----------------------------------------------------------------------------
# Section 3.1: Data Obfuscation
# -----------------------------------------------------------------------------

variable "obfuscation_patterns" {
  description = "List of regex patterns to obfuscate in logs (e.g., credit card, SSN)"
  type = list(object({
    name    = string
    pattern = string
  }))
  default = [
    {
      name    = "Credit Card Numbers"
      pattern = "\\b(?:\\d{4}[- ]?){3}\\d{4}\\b"
    },
    {
      name    = "Social Security Numbers"
      pattern = "\\b\\d{3}-\\d{2}-\\d{4}\\b"
    },
    {
      name    = "API Keys and Tokens"
      pattern = "(?i)(?:api[_-]?key|token|bearer|authorization)[\"':\\s=]+[A-Za-z0-9+/=_-]{20,}"
    }
  ]
}

# -----------------------------------------------------------------------------
# Section 3.2: Data Retention
# -----------------------------------------------------------------------------

variable "log_retention_days" {
  description = "Log data retention period in days (30 is New Relic default)"
  type        = number
  default     = 30
}

# -----------------------------------------------------------------------------
# Section 4.1: NrAuditEvent Monitoring
# -----------------------------------------------------------------------------

variable "alert_notification_channel_id" {
  description = "New Relic notification channel ID for alert policies (optional, empty to skip)"
  type        = string
  default     = ""
}

variable "audit_alert_threshold_critical" {
  description = "Critical threshold: number of audit events in evaluation window to trigger alert"
  type        = number
  default     = 10
}

variable "audit_alert_evaluation_window" {
  description = "Evaluation window in seconds for audit event alerts"
  type        = number
  default     = 300
}
