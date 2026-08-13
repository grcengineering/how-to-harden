#!/usr/bin/env bash
# =============================================================================
# HTH Google Chat Control 2.6: Set the Default Space Access to Restricted
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3 | NIST 800-53 AC-3, AC-6
# Guide: https://howtoharden.com/guides/google-chat/#26-set-the-default-space-access-to-restricted
#
# INTERFACE: `gws` — the Google Workspace CLI (github.com/googleworkspace/cli)
#
# TOOL STATUS: `gws` is Google-published but its README states verbatim
#   "This is not an officially supported Google product." Pre-1.0; breaking
#   changes expected. GAM is not used here because it is community-maintained
#   rather than vendor-published.
#
# WHY THIS IS AN AUDIT, NOT AN ENFORCEMENT:
#   The space access DEFAULT is an Admin Console setting exposed read-only via
#   the Policy API (`chat.space_access_default`). What this pack does instead is
#   answer the question the default cannot: which spaces that ALREADY EXIST are
#   discoverable beyond their intended membership.
#
# Requires: "Manage Chat and Spaces conversation" admin privilege
#   Scope: https://www.googleapis.com/auth/chat.admin.spaces.readonly
# =============================================================================
set -euo pipefail

# HTH Guide Excerpt: begin cli-gws-space-inventory
# Org-wide space inventory via admin access. Both `customer` and `spaceType`
# are REQUIRED by the API, and each currently accepts exactly one value:
#   customer  = "customers/my_customer"
#   spaceType = "SPACE"
gws chat spaces search \
  --params '{"useAdminAccess":true,"query":"customer = \"customers/my_customer\" AND spaceType = \"SPACE\""}' \
  --page-all --format json
# HTH Guide Excerpt: end cli-gws-space-inventory

# HTH Guide Excerpt: begin cli-gws-space-stale
# Dormant spaces still carry their full message history and shared files, so an
# abandoned space is standing exposure. Find spaces with no activity since a
# cutoff, then review before deleting.
CUTOFF="2026-01-01T00:00:00+00:00"

gws chat spaces search \
  --params "{\"useAdminAccess\":true,\"query\":\"customer = \\\"customers/my_customer\\\" AND spaceType = \\\"SPACE\\\" AND lastActiveTime < \\\"${CUTOFF}\\\"\"}" \
  --page-all --format json

# List the members of a specific space to identify external members and
# confirm the space still has an owner/manager.
gws chat spaces members list \
  --params '{"parent":"spaces/SPACE_ID","useAdminAccess":true}' \
  --format json
# HTH Guide Excerpt: end cli-gws-space-stale
