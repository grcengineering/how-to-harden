# =============================================================================
# HTH Buildkite Control 2.3: Limit Admin Access
# Profile Level: L1 (Baseline)
# Frameworks: CIS 5.4 | NIST AC-6(1)
# Source: https://howtoharden.com/guides/buildkite/#23-limit-admin-access
#
# NOTE: Buildkite admin/owner assignment cannot be managed via Terraform.
# Admin roles are assigned through the Buildkite UI:
#   Organization Settings > Members > [User] > Role
#
# This file documents the control requirement and provides a validation
# approach using the Buildkite API.
# =============================================================================

# HTH Guide Excerpt: begin terraform
# Admin access is managed via the Buildkite UI, not Terraform.
# This control requires:
#   1. Limit organization owners/admins to 2-3 users
#   2. Require SSO and 2FA for all admin accounts
#   3. Review admin membership quarterly
#
# Validation: Query organization members via Buildkite GraphQL API
#
# query {
#   organization(slug: "your-org") {
#     members(first: 100, role: ADMIN) {
#       edges {
#         node {
#           user {
#             name
#             email
#           }
#         }
#       }
#     }
#   }
# }
#
# Expected: No more than 3 admin users returned
# HTH Guide Excerpt: end terraform
