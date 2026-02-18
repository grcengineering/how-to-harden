# =============================================================================
# CrowdStrike Falcon Hardening Code Pack - Variables
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
# CrowdStrike Provider Configuration
# -----------------------------------------------------------------------------

variable "crowdstrike_client_id" {
  description = "CrowdStrike API client ID (OAuth2)"
  type        = string
  sensitive   = true
}

variable "crowdstrike_client_secret" {
  description = "CrowdStrike API client secret (OAuth2)"
  type        = string
  sensitive   = true
}

variable "crowdstrike_cloud" {
  description = "Falcon cloud region (us-1, us-2, eu-1, us-gov-1, us-gov-2, or autodiscover)"
  type        = string
  default     = "us-2"
}

# -----------------------------------------------------------------------------
# Section 3.1: Sensor Anti-Tamper
# -----------------------------------------------------------------------------

variable "uninstall_protection_enabled" {
  description = "Enable uninstall protection on sensor update policies (prevents unauthorized sensor removal)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Section 3.2: Prevention Policy Hardening
# -----------------------------------------------------------------------------

variable "prevention_policy_windows_name" {
  description = "Name for the hardened Windows prevention policy"
  type        = string
  default     = "HTH Hardened Windows Policy"
}

variable "prevention_policy_linux_name" {
  description = "Name for the hardened Linux prevention policy"
  type        = string
  default     = "HTH Hardened Linux Policy"
}

variable "prevention_policy_mac_name" {
  description = "Name for the hardened Mac prevention policy"
  type        = string
  default     = "HTH Hardened Mac Policy"
}

# -----------------------------------------------------------------------------
# Section 3.3: Host Group Strategy
# -----------------------------------------------------------------------------

variable "canary_group_assignment_rule" {
  description = "Dynamic assignment rule for the canary host group (e.g., tags:'SensorGroupingTags/canary')"
  type        = string
  default     = "tags:'SensorGroupingTags/canary'"
}

variable "production_critical_assignment_rule" {
  description = "Dynamic assignment rule for production-critical hosts (e.g., tags:'SensorGroupingTags/production-critical')"
  type        = string
  default     = "tags:'SensorGroupingTags/production-critical'"
}

variable "production_standard_assignment_rule" {
  description = "Dynamic assignment rule for production-standard hosts (e.g., tags:'SensorGroupingTags/production-standard')"
  type        = string
  default     = "tags:'SensorGroupingTags/production-standard'"
}

variable "workstation_assignment_rule" {
  description = "Dynamic assignment rule for workstation hosts (e.g., tags:'SensorGroupingTags/workstation')"
  type        = string
  default     = "tags:'SensorGroupingTags/workstation'"
}

# -----------------------------------------------------------------------------
# Section 4.1: Staged Content Deployment
# -----------------------------------------------------------------------------

variable "canary_content_delay_hours" {
  description = "Hours to delay content updates for canary ring (0 = immediate)"
  type        = number
  default     = 0
}

variable "early_adopter_content_delay_hours" {
  description = "Hours to delay content updates for early-adopter ring"
  type        = number
  default     = 4
}

variable "production_content_delay_hours" {
  description = "Hours to delay content updates for production ring (24-48 recommended)"
  type        = number
  default     = 24
}

variable "critical_content_delay_hours" {
  description = "Hours to delay content updates for production-critical ring (48-72 recommended)"
  type        = number
  default     = 48
}

# -----------------------------------------------------------------------------
# Section 4.2: Sensor Update Rollback
# -----------------------------------------------------------------------------

variable "sensor_update_canary_build" {
  description = "Sensor build version for canary ring (latest/N). Leave empty to use data source."
  type        = string
  default     = ""
}

variable "sensor_update_production_build" {
  description = "Sensor build version for production ring (N-1 recommended). Leave empty to use data source."
  type        = string
  default     = ""
}

variable "sensor_update_schedule_timezone" {
  description = "Timezone for sensor update maintenance windows"
  type        = string
  default     = "Etc/UTC"
}

# -----------------------------------------------------------------------------
# Section 5.1: Detection Tuning - Response Policy
# -----------------------------------------------------------------------------

variable "response_policy_name" {
  description = "Name for the hardened Real Time Response policy"
  type        = string
  default     = "HTH Hardened RTR Policy"
}
