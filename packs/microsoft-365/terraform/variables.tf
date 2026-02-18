# =============================================================================
# Microsoft 365 Hardening Code Pack - Variables
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
# Azure AD / Entra ID Provider Configuration
# -----------------------------------------------------------------------------

variable "tenant_id" {
  description = "Azure AD / Entra ID tenant ID"
  type        = string
}

variable "client_id" {
  description = "Service principal (app registration) client ID for Terraform authentication"
  type        = string
}

variable "client_secret" {
  description = "Service principal client secret for Terraform authentication"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: Phishing-Resistant MFA
# -----------------------------------------------------------------------------

variable "break_glass_account_upns" {
  description = "UPNs of break-glass emergency access accounts to exclude from Conditional Access policies"
  type        = list(string)
  default     = []
}

variable "mfa_policy_state" {
  description = "State of the MFA Conditional Access policy (enabled, disabled, enabledForReportingButNotEnforced)"
  type        = string
  default     = "enabled"
}

# -----------------------------------------------------------------------------
# Section 1.2: Block Legacy Authentication
# -----------------------------------------------------------------------------

variable "legacy_auth_policy_state" {
  description = "State of the block legacy auth Conditional Access policy"
  type        = string
  default     = "enabled"
}

# -----------------------------------------------------------------------------
# Section 1.3: Privileged Identity Management (L2)
# -----------------------------------------------------------------------------

variable "pim_eligible_admin_upns" {
  description = "UPNs of users to assign as eligible Global Administrators via PIM (L2+)"
  type        = list(string)
  default     = []
}

variable "pim_activation_max_hours" {
  description = "Maximum PIM activation duration in hours (L2+)"
  type        = number
  default     = 2
}

# -----------------------------------------------------------------------------
# Section 1.4: Break-Glass Emergency Access Accounts
# -----------------------------------------------------------------------------

variable "break_glass_account_domain" {
  description = "The .onmicrosoft.com domain for break-glass accounts (e.g., contoso.onmicrosoft.com)"
  type        = string
  default     = ""
}

variable "break_glass_account_passwords" {
  description = "Passwords for the two break-glass accounts (64+ chars recommended). Set via TF_VAR or tfvars."
  type        = list(string)
  default     = []
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 2.1: Trusted Locations / Named Locations (L2)
# -----------------------------------------------------------------------------

variable "trusted_ip_ranges" {
  description = "List of trusted corporate IP CIDR ranges for named locations (L2+)"
  type        = list(string)
  default     = []
}

variable "blocked_country_codes" {
  description = "ISO 3166-1 alpha-2 country codes to block via Conditional Access (L2+)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 3.1: Restrict User Consent to Applications
# -----------------------------------------------------------------------------

variable "admin_consent_request_reviewers" {
  description = "Object IDs of users who can review admin consent requests"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 4.2: External Sharing Restrictions
# -----------------------------------------------------------------------------

variable "allowed_external_domains" {
  description = "List of external domains allowed for sharing (empty = block all external sharing)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 5.1: Unified Audit Logging
# -----------------------------------------------------------------------------

variable "audit_log_retention_days" {
  description = "Number of days to retain audit logs (90 default, up to 365 for E5)"
  type        = number
  default     = 90
}
