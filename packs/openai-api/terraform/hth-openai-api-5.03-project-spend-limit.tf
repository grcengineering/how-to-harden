# HTH Pack Contract: v1
#   control: openai-api-5.3
#   guide: https://howtoharden.com/guides/openai-api/#53-enforce-reviewed-spend-and-rate-limits
#   profile: L1
#   mode: mutating
#   requires: OPENAI_ADMIN_KEY, Terraform, approved production interruption/recovery plan
# Source: https://github.com/openai/terraform-provider-openai/blob/main/docs/resources/project_spend_limit.md
# NIST 800-53 SC-5. The threshold is USD cents; enforcement is not instantaneous.
variable "monthly_limit_cents" {
  type = number
  validation {
    condition     = var.monthly_limit_cents > 0 && floor(var.monthly_limit_cents) == var.monthly_limit_cents
    error_message = "Supply a positive integer number of USD cents."
  }
}
# HTH Guide Excerpt: begin project-spend-limit
resource "openai_project_spend_limit" "application" {
  project_id       = var.project_id
  threshold_amount = var.monthly_limit_cents
  currency         = "USD"
  interval         = "month"
}
# This is a hard limit. At the threshold affected requests return 429;
# configure earlier spend alerts and recovery ownership separately.
# HTH Guide Excerpt: end project-spend-limit
