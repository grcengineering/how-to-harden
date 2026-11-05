# HTH Pack Contract: v1
#   control: statsig-1.2
#   guide: https://howtoharden.com/guides/statsig/#12-close-projects-and-restrict-roles
#   profile: L1
#   mode: mutating
#   requires: Terraform 1.7+, statsig-io/statsig 2.2.1, approved existing project, protected state
# HTH Statsig 1.2 — Close Projects and Restrict Roles; NIST AC-3, AC-6; SOC 2 CC6.1
# Source: https://github.com/statsig-io/terraform-provider-statsig/blob/v2.2.1/docs/resources/settings_project.md
# Create updates the existing KEY-SCOPED project. v2.2.1 has no ImportState method.
# This recipe requires an existing nonempty default unit type; otherwise use the console.

# HTH Guide Excerpt: begin close-reviewed-project
variable "reviewed_project" {
  type = object({
    name              = string
    default_unit_type = string
  })
  default  = null
  nullable = true
  validation {
    condition = var.reviewed_project == null ? true : (
      length(trimspace(var.reviewed_project.name)) > 0 &&
      length(trimspace(var.reviewed_project.default_unit_type)) > 0
    )
    error_message = "Supply the reviewed existing name/default unit type; this pack does not invent or clear them."
  }
}

resource "statsig_settings_project" "reviewed" {
  for_each = var.reviewed_project == null ? {} : { project = var.reviewed_project }

  name              = each.value.name
  visibility        = "CLOSED"
  default_unit_type = each.value.default_unit_type

  lifecycle {
    prevent_destroy = true
  }
}
# HTH Guide Excerpt: end close-reviewed-project
