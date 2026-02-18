# =============================================================================
# Microsoft Entra ID Hardening Code Pack - Variables
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
# AzureAD Provider Configuration
# -----------------------------------------------------------------------------

variable "tenant_id" {
  description = "Azure AD tenant ID (GUID) for provider authentication"
  type        = string
}

variable "domain_name" {
  description = "Primary domain name for the tenant (e.g., yourorg.onmicrosoft.com)"
  type        = string
}

# -----------------------------------------------------------------------------
# Section 1.1: Phishing-Resistant MFA
# -----------------------------------------------------------------------------

variable "fido2_allowed_aaguids" {
  description = "List of FIDO2 AAGUIDs to allow (empty list allows all FIDO2 keys)"
  type        = list(string)
  default     = []
}

variable "disable_sms_authentication" {
  description = "Whether to disable SMS as an authentication method (recommended)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 1.2: Emergency Access (Break-Glass) Accounts
# -----------------------------------------------------------------------------

variable "emergency_account_count" {
  description = "Number of emergency access accounts to create (minimum 2 recommended)"
  type        = number
  default     = 2

  validation {
    condition     = var.emergency_account_count >= 2
    error_message = "At least 2 emergency access accounts are required."
  }
}

variable "emergency_account_upn_prefix" {
  description = "UPN prefix for emergency accounts (e.g., 'emergency-admin' creates emergency-admin-01@domain)"
  type        = string
  default     = "emergency-admin"
}

# -----------------------------------------------------------------------------
# Section 2.1: Block Legacy Authentication
# -----------------------------------------------------------------------------

variable "legacy_auth_policy_state" {
  description = "State of the block legacy authentication policy (enabled or enabledForReportingButNotEnforced for testing)"
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "enabledForReportingButNotEnforced", "disabled"], var.legacy_auth_policy_state)
    error_message = "Policy state must be enabled, enabledForReportingButNotEnforced, or disabled."
  }
}

# -----------------------------------------------------------------------------
# Section 2.2: Require MFA for All Users
# -----------------------------------------------------------------------------

variable "mfa_policy_state" {
  description = "State of the require-MFA-for-all-users policy (enabled or enabledForReportingButNotEnforced for testing)"
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "enabledForReportingButNotEnforced", "disabled"], var.mfa_policy_state)
    error_message = "Policy state must be enabled, enabledForReportingButNotEnforced, or disabled."
  }
}

# -----------------------------------------------------------------------------
# Section 2.3: Require Compliant Devices for Admins (L2)
# -----------------------------------------------------------------------------

variable "admin_role_ids" {
  description = "List of directory role template IDs to target for device compliance policy (L2+)"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 2.4: Block High-Risk Sign-Ins (L2)
# -----------------------------------------------------------------------------

variable "high_risk_policy_state" {
  description = "State of the block high-risk sign-ins policy (L2+)"
  type        = string
  default     = "enabled"

  validation {
    condition     = contains(["enabled", "enabledForReportingButNotEnforced", "disabled"], var.high_risk_policy_state)
    error_message = "Policy state must be enabled, enabledForReportingButNotEnforced, or disabled."
  }
}

# -----------------------------------------------------------------------------
# Section 3.1: Just-In-Time Access for Admin Roles (L2)
# -----------------------------------------------------------------------------

variable "pim_eligible_user_ids" {
  description = "List of user object IDs to assign as PIM-eligible Global Administrators (L2+)"
  type        = list(string)
  default     = []
}

variable "pim_activation_max_hours" {
  description = "Maximum PIM activation duration in hours (L2+)"
  type        = number
  default     = 2

  validation {
    condition     = var.pim_activation_max_hours >= 1 && var.pim_activation_max_hours <= 8
    error_message = "PIM activation duration must be between 1 and 8 hours."
  }
}

variable "pim_eligibility_duration_days" {
  description = "PIM eligibility assignment duration in days (L2+)"
  type        = number
  default     = 365
}

# -----------------------------------------------------------------------------
# Section 3.2: Access Reviews (L2)
# -----------------------------------------------------------------------------

variable "access_review_reviewer_ids" {
  description = "List of user object IDs to serve as access review reviewers (L2+)"
  type        = list(string)
  default     = []
}

variable "access_review_frequency" {
  description = "Access review recurrence frequency: monthly or quarterly (L2+)"
  type        = string
  default     = "quarterly"

  validation {
    condition     = contains(["monthly", "quarterly"], var.access_review_frequency)
    error_message = "Access review frequency must be monthly or quarterly."
  }
}

# -----------------------------------------------------------------------------
# Section 4.1: Restrict User Consent to Applications
# -----------------------------------------------------------------------------

variable "admin_consent_reviewer_ids" {
  description = "List of user object IDs who can review admin consent requests"
  type        = list(string)
  default     = []
}

# -----------------------------------------------------------------------------
# Section 5.1: Sign-In and Audit Logging
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Azure Log Analytics workspace ID for diagnostic log export (empty to skip)"
  type        = string
  default     = ""
}
