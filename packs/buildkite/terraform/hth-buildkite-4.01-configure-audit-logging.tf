# =============================================================================
# HTH Buildkite Control 4.1: Configure Audit Logging
# Profile Level: L1 (Crawl)
# Frameworks: CIS 8.2 | NIST AU-2
# Source: https://howtoharden.com/guides/buildkite/#41-configure-audit-logging
#
# NOTE: Buildkite audit logging is enabled by default on Enterprise plans.
# The Terraform provider does not manage audit log settings directly.
# However, API IP restrictions (via buildkite_organization) can limit
# who can access audit data programmatically.
#
# LOCKOUT WARNING. allowed_api_ip_addresses is a hard allowlist on API access.
# A CIDR that omits the network you automate from will sever your own REST and
# GraphQL access the moment it applies — including the access needed to undo it
# from a machine outside the list. Confirm your egress address is covered BEFORE
# applying, and keep a path in from an allowlisted network. Recovery is via the
# organizationApiIpAllowlistUpdate GraphQL mutation, which itself requires API
# access, so an incorrect list can be self-sealing.
#
# PREREQUISITE — plan gate. This resource requires a plan that includes the API
# IP allowlist feature; see the note in pack 1.02 for the exact create-time error.
#
# SINGLETON CONFLICT. This declares buildkite_organization a SECOND time; pack
# 1.02 declares buildkite_organization.hardened against the same single remote
# object. Applying both makes two Terraform resources manage one organization,
# producing perpetual drift. Adopt one, or merge them into a single resource.
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
