# HTH Pack Contract: v1
#   control: devin-2.1
#   guide: https://howtoharden.com/guides/devin/#21-restrict-inbound-access-with-ip-access-lists
#   profile: L2
#   mode: mutating
#   requires: DEVIN_TOKEN(enterprise service user with Manage IP Whitelist), approved_cidrs, independent_access_verified
# NIST 800-53 AC-3/SC-7. Source (available in 0.5.0):
# https://github.com/CognitionAI/terraform-provider-devin/blob/v0.5.0/docs/resources/ip_access_list.md
# DANGER: singleton; apply REPLACES the whole enterprise list. Provider destruction
# clears restrictions. prevent_destroy protects only while this block remains present.
# No apply performed by HTH. First GET/export the current list using the API pack,
# merge approved operator/automation egress, and prove an independent admin route.
# If that backup route is unproven, STOP. Never use documentation/test CIDRs here.
# Copy providers.tf and this file into a separate, access-controlled state directory.
# HTH Guide Excerpt: begin inbound-policy
variable "approved_cidrs" {
  type        = list(string)
  description = "Complete approved enterprise IPv4/IPv6 CIDRs, including operator and recovery egress; no defaults."
  validation {
    condition = length(var.approved_cidrs) > 0 && alltrue([
      for cidr in var.approved_cidrs : can(cidrhost(cidr, 0)) && !endswith(cidr, "/0")
    ])
    error_message = "Supply nonempty, valid CIDRs; unrestricted /0 is forbidden."
  }
}
variable "independent_access_verified" {
  type        = bool
  description = "True only after an independent administrator proves an allowed recovery route."
  default     = false
}
resource "devin_ip_access_list" "hth_approved" {
  ip_ranges = var.approved_cidrs
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.independent_access_verified
      error_message = "STOP: prove a separate allowed administrative recovery route before planning a replacement."
    }
  }
}
# HTH Guide Excerpt: end inbound-policy
