#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: replit-4.1
#   guide:   https://howtoharden.com/guides/replit/#41-set-deployment-access-to-private-workspace-or-invite-only
#   profile: L1
#   mode:    read-only
#   requires: REPLIT_ADMIN_API_KEY(Enterprise Admin API key, read-only access), REPLIT_PUBLIC_ALLOWLIST(optional file of project UUIDs approved to publish publicly)
# =============================================================================
# HTH Replit Control 4.1: Set Deployment Access to Private (Workspace or Invite Only)
# Profile Level: L1 (Crawl) | Plan: Enterprise for this pack (Admin API is beta, account admins only)
# Frameworks: NIST 800-53 AC-3/AC-14 | CIS Controls v8 3.3/4.2
# Sources: https://docs.replit.com/features/publishing/private-deployments
#          https://docs.replit.com/teams/admin-api   (endpoint reference: https://api.replit.com/docs)
# Dependencies: curl, jq
#
# WHAT THIS PROVES. GET /v1/deployments?workspaceId=… (scope read:*) returns every
# deployment in a team workspace with deploymentPrivacy — "Privacy of the current serving
# build": public | password | private. Anything not private that is not on your approved
# list is a finding. Password protection counts: it is a shared secret, not an identity.
# Also the programmatic answer to control 7.2's "what of ours is on the internet?".
#
# NOT COVERED: personal-workspace apps (the API excludes them) and changing access, which
# has no API — unpublish, pick Workspace only / Invite only, republish.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (nothing was verified)
# =============================================================================

set -Eeuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO} — nothing was verified" >&2; exit 2' ERR

REPLIT_API_BASE="${REPLIT_API_BASE:-https://api.replit.com/v1}"
[ -n "${REPLIT_ADMIN_API_KEY:-}" ] || { echo "PRECONDITION: set REPLIT_ADMIN_API_KEY (an Enterprise Admin API key, rpl_…; read-only access is enough)" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-replit.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
ACC_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-replit.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
ALL_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-replit.XXXXXX")" || { echo "PRECONDITION: mktemp failed" >&2; exit 2; }
trap 'rm -f "${BODY_FILE}" "${ACC_FILE}" "${ALL_FILE}"' EXIT

# One GET into BODY_FILE. Anything but a 200 carrying {data: [...], pagination: {...}} is a
# precondition (exit 2): a control is never judged on evidence that was not returned.
api_get() {
  local code rc=0
  code=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' --max-time 60 \
    -H "Authorization: Bearer ${REPLIT_ADMIN_API_KEY}" \
    -H "Accept: application/json" \
    "${REPLIT_API_BASE}$1") || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET $1 — no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET $1 returned HTTP ${code} ($(jq -r '.error.code // "unknown"' "${BODY_FILE}" 2>/dev/null || echo unknown))" >&2
    case "${code}" in 401|403) echo "  The key is invalid or revoked, or is not an Enterprise account-admin key." >&2 ;; esac
    exit 2
  fi
  if ! jq -e '(.data | type) == "array" and (.pagination.hasMore | type) == "boolean"' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET $1 — HTTP 200 without a {data, pagination} body; refusing to read it as an empty list" >&2; exit 2
  fi
}

# Follows pagination.cursor until hasMore is false; result lands in ITEMS (a JSON array).
paginate() { # paginate <path> [query]
  local query="${2:+$2&}" cursor="" pages=0
  : > "${ACC_FILE}"
  while :; do
    if [ -n "${cursor}" ]; then
      api_get "$1?${query}limit=100&cursor=$(jq -rn --arg c "${cursor}" '$c | @uri')"
    else
      api_get "$1?${query}limit=100"
    fi
    jq -c '.data[]' "${BODY_FILE}" >> "${ACC_FILE}"
    pages=$((pages + 1))
    if [ "$(jq -r '.pagination.hasMore' "${BODY_FILE}")" != "true" ]; then break; fi
    cursor=$(jq -r '.pagination.cursor' "${BODY_FILE}")
    if [ "${pages}" -ge 1000 ]; then echo "PRECONDITION: $1 did not finish paginating after 1000 pages" >&2; exit 2; fi
  done
  ITEMS=$(jq -s '.' "${ACC_FILE}")
}

# HTH Guide Excerpt: begin deployment-privacy-audit
# Every team-workspace deployment that is public or password protected, minus the
# approved list, is a finding. Suspended deployments are not serving and are skipped.
ALLOW='[]'
if [ -n "${REPLIT_PUBLIC_ALLOWLIST:-}" ]; then
  [ -r "${REPLIT_PUBLIC_ALLOWLIST}" ] || { echo "PRECONDITION: REPLIT_PUBLIC_ALLOWLIST is not readable" >&2; exit 2; }
  ALLOW=$(jq -R 'ascii_downcase | gsub("^\\s+|\\s+$"; "") | select(length > 0 and (startswith("#") | not))' \
            "${REPLIT_PUBLIC_ALLOWLIST}" | jq -s 'unique')
fi
paginate "/workspaces"
WS_IDS=$(printf '%s' "${ITEMS}" | jq -r '.[].id')
if [ -z "${WS_IDS}" ]; then echo "PRECONDITION: /workspaces returned no workspaces" >&2; exit 2; fi
if printf '%s\n' "${WS_IDS}" | grep -qvE '^[A-Za-z0-9]+$'; then
  echo "PRECONDITION: /workspaces returned an id outside ^[A-Za-z0-9]+$ — refusing to build URLs from it" >&2; exit 2
fi
: > "${ALL_FILE}"
for ws in ${WS_IDS}; do
  paginate "/deployments" "workspaceId=${ws}"
  printf '%s\n' "${ITEMS}" >> "${ALL_FILE}"
done
DEPLOYMENTS=$(jq -s 'add // []' "${ALL_FILE}")
EXPOSED=$(printf '%s' "${DEPLOYMENTS}" | jq -c --argjson allow "${ALLOW}" '
  [ .[] | select(.deploymentPrivacy != "private" and .status != "suspended")
        | select((.project.id | ascii_downcase) as $p | any($allow[]; . == $p) | not) ]')
echo "Replit 4.1 — deployment access across $(printf '%s\n' "${WS_IDS}" | wc -l | tr -d ' ') workspace(s)"
printf '%s' "${DEPLOYMENTS}" | jq -r 'group_by(.deploymentPrivacy) | .[] | "  \(.[0].deploymentPrivacy): \(length)"'
if [ "$(printf '%s' "${EXPOSED}" | jq 'length')" -gt 0 ]; then
  echo "FINDING: deployments reachable without a Replit identity and not on the approved list:"
  printf '%s' "${EXPOSED}" | jq -r '.[] | "    - \(.workspace.slug // "?")/\(.project.title) privacy=\(.deploymentPrivacy) status=\(.status) url=\(.url // "none") project=\(.project.id)"'
  echo "  Fix: Publishing tool -> unpublish -> Who can access your app -> Workspace only / Invite only -> publish."
  exit 1
fi
echo "COMPLIANT: every serving team-workspace deployment is private or explicitly approved."
exit 0
# HTH Guide Excerpt: end deployment-privacy-audit
