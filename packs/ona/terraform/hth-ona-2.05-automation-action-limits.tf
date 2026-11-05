# HTH Pack Contract: v1
#   control: ona-2.5
#   guide: https://howtoharden.com/guides/ona/#25-constrain-automations
#   profile: L2
#   mode: mutating
#   requires: ONA_TOKEN; Terraform>=1.14, Linux; shared versions.tf
# Source: https://raw.githubusercontent.com/gitpod-io/terraform-provider-ona/v0.5.1/docs/resources/automation.md
# Fetched 2026-11-05. No live validation. Review/import/plan before any application.
# Per-Automation limits, NOT preview organization-wide automationPolicy.
# New automations require a permitted USER credential, not a service account.
# Omitted executor defaults to the creating user; review the actual run identity.
# Disabled by default: automatic and manual starts are disabled.
variable "automation_project_id" {
  type        = string
  description = "Approved existing project UUID; inherited project secrets/configuration apply."
}
# HTH Guide Excerpt: begin terraform
resource "ona_automation" "reviewed" {
  name     = "hth-reviewed-task"
  agent    = "codex"
  disabled = true
  triggers = [{
    manual  = {}
    context = { projects = { project_ids = [var.automation_project_id] } }
  }]
  action = {
    limits = { max_parallel = 1, max_total = 1, max_time = "10m" }
    steps  = [{ task = { command = "printf 'Review and replace this harmless task before enabling.\\n'" } }]
  }
}
# HTH Guide Excerpt: end terraform
