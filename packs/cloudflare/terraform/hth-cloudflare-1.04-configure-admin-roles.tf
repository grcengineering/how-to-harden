# =============================================================================
# HTH Cloudflare Control 1.4: Configure Admin Role Restrictions
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-6(1) | CIS 5.4
# Source: https://howtoharden.com/guides/cloudflare/#14-configure-admin-role-restrictions
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
  roles      = [local.roles_by_name["Administrator"].id]
}

resource "cloudflare_account_member" "audit_viewer" {
  account_id = var.cloudflare_account_id
  email      = var.audit_viewer_email
  roles      = [local.roles_by_name["Administrator Read Only"].id]
}
# HTH Guide Excerpt: end terraform
