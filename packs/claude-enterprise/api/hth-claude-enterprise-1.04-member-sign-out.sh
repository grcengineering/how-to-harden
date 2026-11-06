#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: claude-enterprise-1.4
#   guide: https://howtoharden.com/guides/claude-enterprise/#14-contain-stolen-sessions-without-assuming-work-stops
#   profile: L2
#   mode: mutating
#   requires: ANTHROPIC_ADMIN_KEY(read:members and write:members; single organization), HTH_USER_ID
# Source: https://platform.claude.com/docs/en/manage-claude/user-management (beta)
set -euo pipefail
source "$(dirname "$0")/../../anthropic-claude/api/common.sh"
# HTH Guide Excerpt: begin guarded-member-sign-out
# Default: read target only. This never removes members or changes identity settings.
: "${HTH_USER_ID:?Use a verified member ID, never an unverified email lookup}"
[[ "${HTH_USER_ID}" =~ ^user_[A-Za-z0-9]+$ ]] || exit 2
ANTHROPIC_VERSION=2026-10-21
member=$(anthropic_get "/v1/organizations/users/${HTH_USER_ID}")
printf '%s' "${member}" | jq -e --arg id "${HTH_USER_ID}" '.type == "user" and .id == $id and (.role | type) == "string"' >/dev/null || exit 2
role=$(printf '%s' "${member}" | jq -r '.role')
[[ "${role}" != primary_owner ]] || { echo 'Primary owner sign-out is unsupported.' >&2; exit 2; }
if [[ "${HTH_APPLY:-0}" != 1 ]]; then
  echo 'Target verified; no sign-out sent. Review cross-account impact, then explicitly opt in with HTH_APPLY=1 and HTH_CONFIRM_USER_ID.'
  exit 0
fi
[[ "${HTH_CONFIRM_USER_ID:-}" == "${HTH_USER_ID}" ]] || exit 2
HTH_ANTHROPIC_BETA=admin-user-sign-out-2026-10-08
# No body. A 503 can mean partial completion: inspect activity before manual retry.
result=$(_anthropic_request POST "/v1/organizations/users/${HTH_USER_ID}/sign_out")
printf '%s' "${result}" | jq -e --arg id "${HTH_USER_ID}" '.type == "user" and .id == $id' >/dev/null || exit 2
echo 'Sign-out returned a member. Verify org_user_trusted_devices_revoked completion in the Activity Feed; API keys, linked computers, cloud sessions and routines may remain.'
# HTH Guide Excerpt: end guarded-member-sign-out
