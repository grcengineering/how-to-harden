# =============================================================================
# Sentry Hardening Code Pack - Variables
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
# Sentry Provider Configuration
# -----------------------------------------------------------------------------

variable "sentry_token" {
  description = "Sentry authentication token (internal integration or personal auth token)"
  type        = string
  sensitive   = true
}

variable "sentry_base_url" {
  description = "Sentry API base URL (default: https://sentry.io/api/ for SaaS; change for self-hosted)"
  type        = string
  default     = "https://sentry.io/api/"
}

variable "sentry_organization" {
  description = "Sentry organization slug"
  type        = string
}

# -----------------------------------------------------------------------------
# Section 2.1: Team Access
# -----------------------------------------------------------------------------

variable "teams" {
  description = "Map of team slugs to team names for least-privilege team structure"
  type        = map(string)
  default = {
    "platform"  = "Platform Engineering"
    "backend"   = "Backend Engineering"
    "frontend"  = "Frontend Engineering"
    "mobile"    = "Mobile Engineering"
    "security"  = "Security"
  }
}

# -----------------------------------------------------------------------------
# Section 2.2: Project Access (L2+)
# -----------------------------------------------------------------------------

variable "projects" {
  description = "Map of project slugs to configuration for team-scoped project access"
  type = map(object({
    name     = string
    platform = string
    teams    = list(string)
  }))
  default = {}
}

# -----------------------------------------------------------------------------
# Section 2.3: Limit Admin Access
# -----------------------------------------------------------------------------

variable "admin_members" {
  description = "Map of email addresses to roles for admin accounts (owner/manager only)"
  type        = map(string)
  default     = {}
}

# -----------------------------------------------------------------------------
# Section 3.1: Data Scrubbing
# -----------------------------------------------------------------------------

variable "sensitive_fields" {
  description = "Additional sensitive field names to scrub from error reports"
  type        = list(string)
  default     = ["password", "secret", "api_key", "token", "authorization", "credit_card", "ssn"]
}

variable "safe_fields" {
  description = "Field names explicitly marked safe (excluded from scrubbing)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.2: DSN Security
# -----------------------------------------------------------------------------

variable "dsn_rate_limit_count" {
  description = "Maximum number of events per rate limit window per DSN"
  type        = number
  default     = 100
}

variable "dsn_rate_limit_window" {
  description = "Rate limit window in seconds for DSN event throttling"
  type        = number
  default     = 60
}

# -----------------------------------------------------------------------------
# Section 3.3: IP Filtering (L2+)
# -----------------------------------------------------------------------------

variable "inbound_data_filters" {
  description = "List of inbound data filter IDs to enable (e.g., browser-extensions, localhost, web-crawlers)"
  type        = list(string)
  default     = ["browser-extensions", "localhost", "web-crawlers", "filtered-transaction"]
}

variable "legacy_browser_subfilters" {
  description = "Legacy browser versions to filter (L2+)"
  type        = list(string)
  default     = ["ie_pre_9", "ie9", "ie10", "ie11", "opera_pre_15", "android_pre_4", "safari_pre_6"]
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Logs - Issue Alert for Security Events
# -----------------------------------------------------------------------------

variable "alert_action_email" {
  description = "Email address for security alert notifications"
  type        = string
  default     = ""
}

variable "security_alert_project" {
  description = "Project slug to attach security monitoring alerts to (must exist in var.projects or already in Sentry)"
  type        = string
  default     = ""
}
