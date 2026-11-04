# HTH Pack Contract: v1
#   control: tailscale-1.4
#   guide: https://howtoharden.com/guides/tailscale/#14-review-node-key-expiry-and-exceptions
#   profile: L1
#   mode: mutating
#   requires: official provider credentials(devices:core:read; devices:core for changes), TAILSCALE_TAILNET, reviewed_expiring_device_ids
# HTH Tailscale 1.4 — Review Node Key Expiry and Exceptions; NIST IA-5, IA-3; SOC 2 CC6.2
# Sources: https://github.com/tailscale/terraform-provider-tailscale/blob/main/docs/resources/device_key.md
# https://github.com/tailscale/terraform-provider-tailscale/blob/main/docs/data-sources/devices.md (available; 2026-11-04)
# HTH Guide Excerpt: begin review-device-key-expiry
data "tailscale_devices" "review" {
  count = var.collect_inventory ? 1 : 0
}

output "devices_for_review" {
  value     = data.tailscale_devices.review
  sensitive = true
}

variable "reviewed_expiring_device_ids" {
  description = "Explicit stable node IDs to manage after recovery testing. Empty means no changes."
  type        = set(string)
  default     = []
  validation {
    condition     = alltrue([for id in var.reviewed_expiring_device_ids : can(regex("^[A-Za-z0-9]+$", id))])
    error_message = "Use reviewed stable node IDs."
  }
}

resource "tailscale_device_key" "reviewed_expiry" {
  for_each            = var.reviewed_expiring_device_ids
  device_id           = each.value
  key_expiry_disabled = false
  lifecycle {
    prevent_destroy = true
  }
}
# HTH Guide Excerpt: end review-device-key-expiry
