# =============================================================================
# Jamf Pro Hardening Code Pack - Variables
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
# Jamf Pro Provider Configuration
# -----------------------------------------------------------------------------

variable "jamfpro_instance_fqdn" {
  description = "Jamf Pro instance FQDN (e.g., yourorg.jamfcloud.com)"
  type        = string
}

variable "jamfpro_client_id" {
  description = "OAuth2 client ID for Jamf Pro API authentication"
  type        = string
}

variable "jamfpro_client_secret" {
  description = "OAuth2 client secret for Jamf Pro API authentication"
  type        = string
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Section 1.1: Console Access - API Roles & Privilege Sets
# -----------------------------------------------------------------------------

variable "helpdesk_privileges" {
  description = "JSS object privileges for the Help Desk role"
  type        = list(string)
  default = [
    "Read Computers",
    "Read Mobile Devices",
    "Read Users"
  ]
}

variable "deployment_privileges" {
  description = "JSS object privileges for the Deployment role"
  type        = list(string)
  default = [
    "Read Computers",
    "Read Mobile Devices",
    "Read Users",
    "Read macOS Configuration Profiles",
    "Create macOS Configuration Profiles",
    "Update macOS Configuration Profiles",
    "Read iOS Configuration Profiles",
    "Create iOS Configuration Profiles",
    "Update iOS Configuration Profiles",
    "Read Packages",
    "Create Packages",
    "Update Packages"
  ]
}

variable "security_privileges" {
  description = "JSS object privileges for the Security role"
  type        = list(string)
  default = [
    "Read Computers",
    "Read Mobile Devices",
    "Read Users",
    "Read macOS Configuration Profiles",
    "Create macOS Configuration Profiles",
    "Update macOS Configuration Profiles",
    "Delete macOS Configuration Profiles",
    "Read iOS Configuration Profiles",
    "Create iOS Configuration Profiles",
    "Update iOS Configuration Profiles",
    "Delete iOS Configuration Profiles",
    "Read Disk Encryption Configurations",
    "Create Disk Encryption Configurations",
    "Update Disk Encryption Configurations",
    "Read Smart Computer Groups",
    "Create Smart Computer Groups",
    "Update Smart Computer Groups",
    "Read Scripts",
    "Create Scripts",
    "Update Scripts"
  ]
}

# -----------------------------------------------------------------------------
# Section 1.2: API Integration Accounts
# -----------------------------------------------------------------------------

variable "api_integration_name" {
  description = "Display name for the dedicated API integration account"
  type        = string
  default     = "HTH Security Automation"
}

variable "api_integration_privileges" {
  description = "Authorization scopes for the API integration"
  type        = list(string)
  default = [
    "Read Computers",
    "Read Mobile Devices",
    "Read macOS Configuration Profiles",
    "Read Smart Computer Groups"
  ]
}

# -----------------------------------------------------------------------------
# Section 2.1: Password Policy
# -----------------------------------------------------------------------------

variable "password_min_length" {
  description = "Minimum device passcode length (12 for L1, 14+ for L2)"
  type        = number
  default     = 12
}

variable "password_max_age_days" {
  description = "Maximum passcode age in days (90 for L1, 0 to disable for L3)"
  type        = number
  default     = 90
}

variable "password_history_count" {
  description = "Number of previous passwords to remember"
  type        = number
  default     = 5
}

variable "auto_lock_minutes" {
  description = "Auto-lock screen timeout in minutes (5 for L1, 2 for L2)"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# Section 2.2: FileVault Encryption
# -----------------------------------------------------------------------------

variable "filevault_escrow_enabled" {
  description = "Whether to escrow FileVault personal recovery keys to Jamf Pro"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 2.3: Firewall
# -----------------------------------------------------------------------------

variable "firewall_stealth_mode" {
  description = "Enable macOS firewall stealth mode"
  type        = bool
  default     = true
}

variable "firewall_block_all_incoming" {
  description = "Block all incoming connections (recommended only for L3)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Section 2.4: Software Updates
# -----------------------------------------------------------------------------

variable "software_update_deferral_days" {
  description = "Number of days to defer major OS updates (L2: 30-90 days)"
  type        = number
  default     = 30
}

variable "security_update_deferral_days" {
  description = "Number of days to defer security updates (L2: 0-7 days)"
  type        = number
  default     = 0
}

# -----------------------------------------------------------------------------
# Section 3.1: CIS Benchmark Profiles (L2)
# -----------------------------------------------------------------------------

variable "cis_gatekeeper_enabled" {
  description = "Enforce Gatekeeper via CIS benchmark profile"
  type        = bool
  default     = true
}

variable "cis_screen_saver_idle_time" {
  description = "Screen saver idle time in seconds (CIS 2.3.1)"
  type        = number
  default     = 600
}

variable "cis_disable_remote_login" {
  description = "Disable SSH/Remote Login (CIS 3.3)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 3.2: CIS Compliance Monitoring (L2)
# -----------------------------------------------------------------------------

variable "cis_compliance_ea_script" {
  description = "Script contents for CIS compliance extension attribute (leave empty for default)"
  type        = string
  default     = ""
}

# -----------------------------------------------------------------------------
# Section 4.1: Audit Logging
# -----------------------------------------------------------------------------

variable "siem_webhook_url" {
  description = "SIEM webhook URL for forwarding Jamf Pro audit events"
  type        = string
  default     = ""
}

variable "siem_webhook_auth_type" {
  description = "Authentication type for SIEM webhook (None, BASIC, or HEADER)"
  type        = string
  default     = "None"
}

variable "siem_webhook_username" {
  description = "Username for SIEM webhook basic authentication"
  type        = string
  default     = ""
}

variable "siem_webhook_password" {
  description = "Password for SIEM webhook basic authentication"
  type        = string
  default     = ""
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Scope Configuration
# -----------------------------------------------------------------------------

variable "scope_all_computers" {
  description = "Whether to scope hardening profiles to all computers"
  type        = bool
  default     = true
}

variable "scope_computer_group_ids" {
  description = "Computer group IDs to scope hardening profiles (when not scoping to all)"
  type        = list(number)
  default     = []
}
