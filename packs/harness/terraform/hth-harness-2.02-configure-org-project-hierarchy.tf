# =============================================================================
# HTH Harness Control 2.2: Configure Organization/Project Hierarchy
# Profile Level: L2 (Hardened)
# Frameworks: CIS 5.4, NIST AC-6
# Source: https://howtoharden.com/guides/harness/#22-configure-organizationproject-hierarchy
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Organizations for business unit isolation (L2+)
resource "harness_platform_organization" "org" {
  for_each = var.profile_level >= 2 ? var.organizations : {}

  identifier  = each.key
  name        = each.value.name
  description = each.value.description != "" ? each.value.description : "Organization managed by HTH Code Pack (Control 2.2)"
}

# Projects within organizations for environment isolation (L2+)
resource "harness_platform_project" "project" {
  for_each = var.profile_level >= 2 ? var.projects : {}

  identifier = each.key
  name       = each.value.name
  org_id     = each.value.org_id
  color      = each.value.color

  depends_on = [harness_platform_organization.org]
}

# Resource group scoped to organization level for org-level access control
resource "harness_platform_resource_group" "org_scoped" {
  for_each = var.profile_level >= 2 ? var.organizations : {}

  identifier  = "hth_org_${each.key}"
  name        = "${each.value.name} Resources"
  description = "Organization-scoped resource group for ${each.value.name} (HTH Control 2.2)"
  account_id  = var.harness_account_id
  org_id      = each.key

  included_scopes {
    filter     = "INCLUDING_CHILD_SCOPES"
    org_id     = each.key
  }

  resource_filter {
    include_all_resources = true
  }

  depends_on = [harness_platform_organization.org]
}
# HTH Guide Excerpt: end terraform
