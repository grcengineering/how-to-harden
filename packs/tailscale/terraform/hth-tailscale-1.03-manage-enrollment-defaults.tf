# HTH Pack Contract: v1
#   control: tailscale-1.3
#   guide: https://howtoharden.com/guides/tailscale/#13-review-new-device-enrollment
#   profile: L1
#   mode: mutating
#   requires: official provider credentials(feature_settings), TAILSCALE_TAILNET, reviewed_tailnet_settings
# HTH Tailscale 1.3 — Review New Device Enrollment; NIST IA-3, AC-3; SOC 2 CC6.1
# Source: https://github.com/tailscale/terraform-provider-tailscale/blob/main/docs/resources/tailnet_settings.md (available; 2026-11-04)
# One owner for the tailnet-settings resource. Import existing settings first.
# HTH Guide Excerpt: begin enrollment-defaults
variable "reviewed_tailnet_settings" {
  description = "Null creates no resource. Supply only reviewed fields; omitted fields remain unmanaged."
  type = object({
    devices_approval_on                         = optional(bool)
    devices_auto_updates_on                     = optional(bool)
    devices_key_duration_days                   = optional(number)
    network_flow_logging_on                     = optional(bool)
    users_role_allowed_to_join_external_tailnet = optional(string)
  })
  default = null
  validation {
    condition = var.reviewed_tailnet_settings == null ? true : (
      var.reviewed_tailnet_settings.devices_key_duration_days == null ? true :
      contains(range(1, 181), var.reviewed_tailnet_settings.devices_key_duration_days)
    )
    error_message = "Key duration must be a whole number from 1 to 180 days."
  }
  validation {
    condition = var.reviewed_tailnet_settings == null ? true : (
      var.reviewed_tailnet_settings.users_role_allowed_to_join_external_tailnet == null ? true :
      contains(["none", "admin", "member"], var.reviewed_tailnet_settings.users_role_allowed_to_join_external_tailnet)
    )
    error_message = "External-tailnet membership must be none, admin or member."
  }
}

variable "tailnet_lock_is_disabled" {
  description = "Set true only after verifying Tailnet Lock is disabled; required to enable device approval."
  type        = bool
  default     = false
}

resource "tailscale_tailnet_settings" "reviewed" {
  for_each = var.reviewed_tailnet_settings == null ? {} : { settings = var.reviewed_tailnet_settings }

  devices_approval_on                         = each.value.devices_approval_on
  devices_auto_updates_on                     = each.value.devices_auto_updates_on
  devices_key_duration_days                   = each.value.devices_key_duration_days
  network_flow_logging_on                     = each.value.network_flow_logging_on
  users_role_allowed_to_join_external_tailnet = each.value.users_role_allowed_to_join_external_tailnet

  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = each.value.devices_approval_on != true || var.tailnet_lock_is_disabled
      error_message = "Device approval and Tailnet Lock are mutually exclusive. Verify the chosen enrollment model first."
    }
    precondition {
      condition     = each.value.network_flow_logging_on == null || var.hth_profile_level >= 2
      error_message = "Network flow logging requires L2 and the appropriate plan/privacy review."
    }
    precondition {
      condition     = each.value.users_role_allowed_to_join_external_tailnet == null || var.hth_profile_level >= 2
      error_message = "External-tailnet membership settings require L2 and collaboration review."
    }
  }
}
# HTH Guide Excerpt: end enrollment-defaults
