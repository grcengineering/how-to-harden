#!/usr/bin/env bash
# HTH Sentry Control 2.3: Limit Admin Access
# Profile: L1 | CIS Controls: 5.4 | NIST 800-53: AC-6(1)
# https://howtoharden.com/guides/sentry/#23-limit-admin-access
#
# Inventories organization members by role via the Sentry Web API and flags
# an oversized privileged population and stale pending invites.
# Requires: curl, jq, an org auth token with member:read scope.
# Verified against: https://docs.sentry.io/api/organizations/list-an-organizations-members/
set -euo pipefail

command -v curl >/dev/null || { echo "ERROR: curl not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq not found" >&2; exit 1; }

# HTH Guide Excerpt: begin api-admin-access-audit
: "${SENTRY_AUTH_TOKEN:?Set SENTRY_AUTH_TOKEN to an auth token with member:read}"
SENTRY_ORG="${SENTRY_ORG:?Set SENTRY_ORG to your organization slug}"
SENTRY_URL="${SENTRY_URL:-https://sentry.io}"
MAX_OWNERS="${MAX_OWNERS:-3}"

MEMBERS=$(curl -sf \
  -H "Authorization: Bearer ${SENTRY_AUTH_TOKEN}" \
  "${SENTRY_URL}/api/0/organizations/${SENTRY_ORG}/members/")

echo "== Members by organization role =="
echo "${MEMBERS}" | jq -r 'group_by(.orgRole) | .[] |
  "\(.[0].orgRole): \(length) member(s)"'

echo ""
echo "== Privileged members (owner / manager) =="
echo "${MEMBERS}" | jq -r '.[] |
  select((.orgRole | ascii_downcase) == "owner" or (.orgRole | ascii_downcase) == "manager") |
  [ .email, .orgRole, .dateCreated ] | @tsv'

OWNER_COUNT=$(echo "${MEMBERS}" | jq '[.[] | select((.orgRole | ascii_downcase) == "owner")] | length')
if [ "${OWNER_COUNT}" -gt "${MAX_OWNERS}" ]; then
  echo "FAIL: ${OWNER_COUNT} owners exceeds the ${MAX_OWNERS}-owner ceiling (guide: limit owners to 2-3)"
else
  echo "PASS: ${OWNER_COUNT} owner(s) within the ${MAX_OWNERS}-owner ceiling"
fi
# HTH Guide Excerpt: end api-admin-access-audit

# HTH Guide Excerpt: begin api-stale-invite-audit
# Pending invites are standing access waiting to be claimed — expire or
# revoke any that were never accepted.
echo "== Pending invites =="
echo "${MEMBERS}" | jq -r '.[] |
  select(.pending == true) |
  [ .email, .inviteStatus, .dateCreated ] | @tsv'
# HTH Guide Excerpt: end api-stale-invite-audit
