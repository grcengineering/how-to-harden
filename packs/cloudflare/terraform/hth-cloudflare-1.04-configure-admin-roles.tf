# =============================================================================
# HTH Cloudflare Control 1.4: Configure Admin Role Restrictions
# Profile Level: L1 (Crawl)
# Frameworks: NIST AC-6(1) | CIS 5.4
# Source: https://howtoharden.com/guides/cloudflare/#14-configure-admin-role-restrictions
#
# Role names are Cloudflare's account role names
# (developers.cloudflare.com/fundamentals/manage-members/roles/):
# "Cloudflare Zero Trust" grants administrator access to Zero Trust products
# only; "Audit Logs Viewer" can only view Audit Logs.
#
# DEPRECATION: provider v5 marks data.cloudflare_account_roles deprecated in
# favour of cloudflare_account_permission_group. cloudflare_account_member
# still accepts legacy role IDs through `roles`; the permission-group route
# uses `policies` with a resource group ID instead. Migrate once the mapping
# has been confirmed against a live account.
# =============================================================================

# HTH Guide Excerpt: begin terraform
data "cloudflare_account_roles" "all" {
  account_id = var.cloudflare_account_id
}

locals {
  roles_by_name = {
    for role in data.cloudflare_account_roles.all.result :
    role.name => role
  }
}

resource "cloudflare_account_member" "zt_admin" {
  account_id = var.cloudflare_account_id
  email      = var.zt_admin_email
  roles      = [local.roles_by_name["Cloudflare Zero Trust"].id]
}

resource "cloudflare_account_member" "audit_viewer" {
  account_id = var.cloudflare_account_id
  email      = var.audit_viewer_email
  roles      = [local.roles_by_name["Audit Logs Viewer"].id]
}
# HTH Guide Excerpt: end terraform
