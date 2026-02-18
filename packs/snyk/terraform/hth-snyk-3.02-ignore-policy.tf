# =============================================================================
# HTH Snyk Control 3.2: Ignore Policy
# Profile Level: L2 (Hardened)
# Frameworks: NIST CM-7, RA-5, SOC 2 CC7.2, ISO 27001 A.12.6, PCI DSS 6.1
# Source: https://howtoharden.com/guides/snyk/#32-ignore-policy
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Enforce governance around vulnerability ignores.
# Uncontrolled ignores hide real risk -- require a documented reason
# and set an expiration date so ignored issues get re-evaluated.

# This control is L2 (Hardened) and only applied at profile_level >= 2.
resource "snyk_organization" "ignore_policy" {
  count = var.profile_level >= 2 ? 1 : 0

  id   = var.snyk_org_id
  name = data.snyk_organization.current.name

  lifecycle {
    ignore_changes = [name]
  }
}

# Note: The Snyk Terraform provider (v0.1.x) does not expose a
# dedicated ignore policy resource. Ignore governance is enforced
# via the Snyk REST API and organization policy settings:
#
#   PATCH https://api.snyk.io/rest/orgs/{org_id}
#   {
#     "data": {
#       "attributes": {
#         "ignore_policy": {
#           "require_reason": true,
#           "default_expiry_days": 90
#         }
#       }
#     }
#   }
#
# Ignore policy best practices (L2+):
# - Require a documented reason for every ignore
# - Set maximum ignore expiration to ${var.ignore_expiration_days} days
# - Audit ignored vulnerabilities monthly
# - Re-evaluate expired ignores within 7 days
# - Critical/High severity ignores require approval from security team
#
# Use the companion API script for full ignore policy enforcement:
#   bash packs/snyk/api/hth-snyk-3.02-ignore-policy.sh
# HTH Guide Excerpt: end terraform
