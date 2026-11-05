# HTH Pack Contract: v1
#   control: statsig-3.1
#   guide: https://howtoharden.com/guides/statsig/#31-require-independent-production-reviews
#   profile: L1
#   mode: mutating
#   requires: Terraform 1.7+, statsig-io/statsig 2.2.1, approved review-flag snapshot, protected state
# HTH Statsig 3.1 — Require Independent Production Reviews; NIST CM-3; SOC 2 CC8.1
# Source: https://github.com/statsig-io/terraform-provider-statsig/blob/v2.2.1/docs/resources/settings_reviews.md
# All other flags must be reviewed explicitly; per-role/environment bypass is separate.

# HTH Guide Excerpt: begin require-reviewed-config-changes
variable "reviewed_other_review_flags" {
  type = object({
    deployment_model                           = string
    is_metric_review_required                  = bool
    is_metric_review_required_on_verified_only = bool
    is_whn_analysis_only_review_required       = bool
    is_whn_source_review_required              = bool
  })
  default  = null
  nullable = true
  validation {
    condition = var.reviewed_other_review_flags == null ? true : (
      contains(["cloud", "warehouse"], var.reviewed_other_review_flags.deployment_model) &&
      (var.reviewed_other_review_flags.deployment_model == "warehouse" ||
      (!var.reviewed_other_review_flags.is_whn_analysis_only_review_required && !var.reviewed_other_review_flags.is_whn_source_review_required))
    )
    error_message = "Declare cloud/warehouse; Warehouse Native-only flags must be false for a Cloud project."
  }
}

resource "statsig_settings_reviews" "reviewed" {
  for_each = var.reviewed_other_review_flags == null ? {} : { reviews = var.reviewed_other_review_flags }

  is_config_review_required                  = true
  is_metric_review_required                  = each.value.is_metric_review_required
  is_metric_review_required_on_verified_only = each.value.is_metric_review_required_on_verified_only
  is_whn_analysis_only_review_required       = each.value.is_whn_analysis_only_review_required
  is_whn_source_review_required              = each.value.is_whn_source_review_required

  lifecycle {
    prevent_destroy = true
  }
}
# HTH Guide Excerpt: end require-reviewed-config-changes
