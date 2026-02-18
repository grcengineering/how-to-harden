# =============================================================================
# HTH Snyk Control 1.2: Role-Based Access
# Profile Level: L1 (Baseline)
# Frameworks: NIST AC-3, AC-6, SOC 2 CC6.1, ISO 27001 A.9.2, PCI DSS 8.3
# Source: https://howtoharden.com/guides/snyk/#12-role-based-access
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enforce least-privilege roles for organization members.
# Snyk roles: org-admin, org-collaborator, org-custom (Enterprise).
# Map users to their appropriate roles to enforce separation of duties.

# Apply role assignments from the restricted_roles variable map.
# Each entry maps a user email to their intended Snyk organization role.
resource "snyk_organization" "rbac_settings" {
  count = length(var.restricted_roles) > 0 ? 1 : 0

  id   = var.snyk_org_id
  name = data.snyk_organization.current.name

  lifecycle {
    ignore_changes = [name]
  }
}

# Note: Individual user role assignments require the Snyk REST API.
# Use the companion API script for per-user role enforcement:
#   bash packs/snyk/api/hth-snyk-1.02-role-based-access.sh
#
# The Snyk Terraform provider does not yet expose a dedicated
# "snyk_organization_member" resource for granular role management.
# This file establishes the organizational baseline; use API scripts
# or SCIM provisioning for per-user role assignment.
# HTH Guide Excerpt: end terraform
