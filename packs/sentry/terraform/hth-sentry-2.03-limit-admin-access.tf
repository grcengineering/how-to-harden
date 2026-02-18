# =============================================================================
# HTH Sentry Control 2.3: Limit Admin Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4, NIST AC-6(1)
# Source: https://howtoharden.com/guides/sentry/#23-limit-admin-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Manage admin/owner members explicitly via Terraform to enforce
# least-privilege and ensure only approved accounts hold elevated roles.
# Limit owners to 2-3 accounts maximum.
resource "sentry_organization_member" "admins" {
  for_each = var.admin_members

  organization = var.sentry_organization
  email        = each.key
  role         = each.value
}
# HTH Guide Excerpt: end terraform
