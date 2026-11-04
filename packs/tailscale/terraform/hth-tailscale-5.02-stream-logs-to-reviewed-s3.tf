# HTH Pack Contract: v1
#   control: tailscale-5.2
#   guide: https://howtoharden.com/guides/tailscale/#52-export-flow-logs-and-verify-delivery
#   profile: L2
#   mode: mutating
#   requires: official provider credentials(log_streaming), TAILSCALE_TAILNET, existing S3 role and Tailscale external ID, reviewed_log_streams
# HTH Tailscale 5.2 — Export Flow Logs and Verify Delivery; NIST AU-12, AU-6; SOC 2 CC7.2
# Source: https://github.com/tailscale/terraform-provider-tailscale/blob/main/docs/resources/logstream_configuration.md (available; 2026-11-04)
# Uses an existing approved IAM role. No bucket, IAM role, access key or credential is created.
# HTH Guide Excerpt: begin stream-logs-to-s3
variable "reviewed_log_streams" {
  description = "configuration/network keys mapped to an existing approved S3 destination. Empty means no stream changes."
  type = map(object({
    bucket      = string
    region      = string
    role_arn    = string
    external_id = string
  }))
  default = {}
  validation {
    condition = alltrue([
      for kind, destination in var.reviewed_log_streams :
      contains(["configuration", "network"], kind) &&
      length(destination.bucket) > 2 && length(destination.region) > 0 &&
      can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", destination.role_arn)) &&
      length(destination.external_id) > 0
    ])
    error_message = "Use configuration/network and an approved bucket, region, role ARN and external ID."
  }
}

resource "tailscale_logstream_configuration" "reviewed" {
  for_each               = var.reviewed_log_streams
  log_type               = each.key
  destination_type       = "s3"
  s3_authentication_type = "rolearn"
  s3_bucket              = each.value.bucket
  s3_region              = each.value.region
  s3_role_arn            = each.value.role_arn
  s3_external_id         = each.value.external_id
  lifecycle {
    prevent_destroy = true
    precondition {
      condition     = var.hth_profile_level >= 2
      error_message = "Log streaming requires L2, plan entitlement and destination/privacy review."
    }
  }
}
# HTH Guide Excerpt: end stream-logs-to-s3
