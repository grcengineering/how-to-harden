# =============================================================================
# HTH Vercel Control 1.3: Enforce Least-Privilege RBAC
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6
# Source: https://howtoharden.com/guides/vercel/#13-enforce-least-privilege-rbac
# =============================================================================

# HTH Guide Excerpt: begin terraform

# --- L1: Manage team members with least-privilege roles ---
resource "vercel_team_member" "members" {
  for_each = var.team_members

  team_id = var.vercel_team_id
  email   = each.value.email
  role    = each.value.role
}

# --- L2: Create Access Groups for project-level permissions (Enterprise) ---
resource "vercel_access_group" "groups" {
  for_each = var.profile_level >= 2 ? var.access_groups : {}

  team_id = var.vercel_team_id
  name    = each.key
}

# --- L2: Link Access Groups to projects ---
resource "vercel_access_group_project" "assignments" {
  for_each = var.profile_level >= 2 ? var.access_group_projects : {}

  team_id         = var.vercel_team_id
  access_group_id = vercel_access_group.groups[each.value.group_name].id
  project_id      = each.value.project_id
  role            = each.value.role
}

# HTH Guide Excerpt: end terraform
