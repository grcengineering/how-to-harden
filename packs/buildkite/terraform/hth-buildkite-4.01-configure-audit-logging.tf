# =============================================================================
# HTH Buildkite Control 4.1: Configure Audit Logging
# Profile Level: L1 (Baseline)
# Frameworks: CIS 8.2 | NIST AU-2
# Source: https://howtoharden.com/guides/buildkite/#41-configure-audit-logging
#
# NOTE: Buildkite audit logging is enabled by default on Enterprise plans.
# The Terraform provider does not manage audit log settings directly.
# However, API IP restrictions (via buildkite_organization) can limit
# who can access audit data programmatically.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Restrict API access to known IP addresses (L3)
# This limits which networks can query audit logs and other API endpoints
resource "buildkite_organization" "api_restrictions" {
  count = var.profile_level >= 3 && length(var.allowed_api_ip_addresses) > 0 ? 1 : 0

  allowed_api_ip_addresses = var.allowed_api_ip_addresses
}

# Audit log monitoring is performed via the Buildkite API.
# Key events to monitor:
#   - User authentication (login/logout)
#   - Pipeline changes (create/update/delete)
#   - Permission modifications (team/member changes)
#   - Agent token usage (create/revoke)
#   - Organization setting changes
#
# Query audit events via GraphQL:
#
# query {
#   organization(slug: "your-org") {
#     auditEvents(first: 50) {
#       edges {
#         node {
#           type
#           occurredAt
#           actor {
#             name
#           }
#           subject {
#             name
#             type
#           }
#         }
#       }
#     }
#   }
# }
# HTH Guide Excerpt: end terraform
