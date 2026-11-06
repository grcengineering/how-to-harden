#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-enterprise-1.3
#   guide: https://howtoharden.com/guides/claude-enterprise/#13-apply-least-privilege-roles-and-groups
#   profile: L1
#   mode: read-only
#   requires: ANTHROPIC_ADMIN_KEY(Enterprise read:members)
# Source: https://platform.claude.com/docs/en/manage-claude/user-management
set -euo pipefail
source "$(dirname "$0")/../../anthropic-claude/api/common.sh"
# HTH Guide Excerpt: begin role-permission-inventory
ANTHROPIC_VERSION=2026-10-21
evidence=$(anthropic_evidence_dir)
trap 'rm -f "${evidence}/roles.pending" "${evidence}/members.pending"' EXIT
anthropic_list_all /v1/organizations/users > "${evidence}/members.pending"
anthropic_page_token_all /v1/organizations/rbac_roles > "${evidence}/roles.pending"
jq -e 'all(.[]; .type == "user" and (.id | type) == "string" and (.role | type) == "string")' "${evidence}/members.pending" >/dev/null
jq -e 'all(.[]; (.id | type) == "string")' "${evidence}/roles.pending" >/dev/null
# Custom-role writes remain in the console. Enumerate permissions for each returned role.
while IFS= read -r role_id; do
  [[ "${role_id}" =~ ^[A-Za-z0-9_-]{1,200}$ ]] || exit 2
  anthropic_page_token_all "/v1/organizations/rbac_roles/${role_id}/permissions" > "${evidence}/${role_id}.json"
done < <(jq -r '.[].id' "${evidence}/roles.pending")
mv "${evidence}/members.pending" "${evidence}/members.json"
mv "${evidence}/roles.pending" "${evidence}/roles.json"
printf 'Private role evidence: %s; review blanket grants and actual Custom-role membership.\n' "${evidence}"
# HTH Guide Excerpt: end role-permission-inventory
