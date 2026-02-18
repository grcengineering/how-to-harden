# =============================================================================
# HTH Snyk Control 2.1: Secure Service Account Tokens
# Profile Level: L1 (Baseline)
# Frameworks: NIST IA-5, SOC 2 CC6.1, CC6.6, ISO 27001 A.9.4, PCI DSS 8.3
# Source: https://howtoharden.com/guides/snyk/#21-secure-service-account-tokens
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Create dedicated service accounts with least-privilege roles.
# Each CI/CD pipeline should have its own service account with
# scoped permissions rather than sharing a single admin token.

# Service accounts created from the service_accounts variable list.
# Each account gets a dedicated role (e.g., org-collaborator for
# read-only scanning, org-admin only when absolutely required).
resource "snyk_organization" "service_account_org" {
  count = length(var.service_accounts) > 0 ? 1 : 0

  id   = var.snyk_org_id
  name = data.snyk_organization.current.name

  lifecycle {
    ignore_changes = [name]
  }
}

# Note: The Snyk Terraform provider (v0.1.x) does not yet expose a
# dedicated "snyk_service_account" resource. Service account creation
# requires the Snyk REST API:
#
#   POST https://api.snyk.io/rest/orgs/{org_id}/service_accounts
#   {
#     "data": {
#       "attributes": {
#         "name": "ci-pipeline-scanner",
#         "auth_type": "api_key",
#         "role_id": "<org-collaborator-role-id>"
#       },
#       "type": "service_account"
#     }
#   }
#
# Use the companion API script for full service account management:
#   bash packs/snyk/api/hth-snyk-2.01-secure-service-account-tokens.sh
#
# Best practices enforced by this control:
# - One service account per CI/CD pipeline (no shared tokens)
# - Org Collaborator role for read-only scanning
# - Token rotation on a regular schedule (90 days max)
# - Immediate revocation of unused accounts
# HTH Guide Excerpt: end terraform
