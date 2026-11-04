# HTH Pack Contract: v1
#   control: tailscale-2.1
#   guide: https://howtoharden.com/guides/tailscale/#21-replace-broad-allows-with-least-privilege-grants
#   profile: L1
#   mode: mutating
#   requires: official provider credentials(policy_file plus devices:core:read and devices:posture_attributes for apply), TAILSCALE_TAILNET, reviewed_policy_file
# HTH Tailscale 2.1 — Replace Broad Allows with Least-Privilege Grants; NIST AC-3, AC-4; SOC 2 CC6.1
# Sources: https://github.com/tailscale/terraform-provider-tailscale/blob/main/docs/resources/acl.md
# https://github.com/tailscale/terraform-provider-tailscale/blob/main/docs/data-sources/acl.md (available; 2026-11-04)
# This owns the ENTIRE policy. Import existing policy first; never bulk-apply fragments.
# HTH Guide Excerpt: begin reviewed-policy
data "tailscale_acl" "review" {
  count = var.collect_inventory ? 1 : 0
}

output "policy_for_review" {
  value     = data.tailscale_acl.review
  sensitive = true
}

variable "reviewed_policy_file" {
  description = "Path to the complete reviewed HuJSON policy. Null means no managed policy."
  type        = string
  default     = null
  validation {
    condition     = var.reviewed_policy_file == null ? true : fileexists(var.reviewed_policy_file)
    error_message = "The reviewed policy file must exist."
  }
}

resource "tailscale_acl" "reviewed" {
  for_each                   = var.reviewed_policy_file == null ? {} : { policy = var.reviewed_policy_file }
  acl                        = file(each.value)
  overwrite_existing_content = false
  reset_acl_on_destroy       = false
  lifecycle {
    prevent_destroy = true
  }
}
# HTH Guide Excerpt: end reviewed-policy
