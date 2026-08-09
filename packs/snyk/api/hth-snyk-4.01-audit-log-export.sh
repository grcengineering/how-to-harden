#!/usr/bin/env bash
# HTH Snyk Control 4.1: Audit Logs (Enterprise)
# Profile: L1 | NIST 800-53: AU-2, AU-3
# https://howtoharden.com/guides/snyk/#41-audit-logs-enterprise
#
# Exports Snyk audit logs for SIEM retention. Snyk keeps a rolling 90 days
# and the endpoints exclude login/logout events, so schedule this well
# inside the window and keep IdP logs as the sign-in system of record.
# Requires: Enterprise plan, curl, jq, a Snyk token with admin access.
# Verified against:
#   https://docs.snyk.io/developer-tools/snyk-api/reference/audit-logs
#   https://docs.snyk.io/developer-tools/snyk-api/authentication-for-api
set -euo pipefail

command -v curl >/dev/null || { echo "ERROR: curl not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "ERROR: jq not found" >&2; exit 1; }

# HTH Guide Excerpt: begin api-audit-log-export
: "${SNYK_TOKEN:?Set SNYK_TOKEN to a Snyk API token with admin access}"
SNYK_API="${SNYK_API:-https://api.snyk.io}"
SNYK_API_VERSION="${SNYK_API_VERSION:-2024-06-10}"

# Collection window — run at least daily; events age out after 90 days.
FROM="${SNYK_AUDIT_FROM:-$(date -u -d '1 day ago' +%Y-%m-%d)}"
TO="${SNYK_AUDIT_TO:-$(date -u +%Y-%m-%d)}"
OUT_DIR="${SNYK_AUDIT_OUT_DIR:-./snyk-audit-logs}"
mkdir -p "${OUT_DIR}"

# Export one scope: "orgs <org_id>" or "groups <group_id>".
#   GET /rest/orgs/{org_id}/audit_logs/search
#   GET /rest/groups/{group_id}/audit_logs/search
# Optional params: from, to, size, cursor, events, exclude_events.
export_audit_logs() {
  local scope="$1" scope_id="$2"
  local out="${OUT_DIR}/${scope}-${scope_id}-${FROM}_${TO}.json"
  local url="${SNYK_API}/rest/${scope}/${scope_id}/audit_logs/search?version=${SNYK_API_VERSION}&from=${FROM}&to=${TO}&size=100"
  [ -n "${SNYK_AUDIT_CURSOR:-}" ] && url="${url}&cursor=${SNYK_AUDIT_CURSOR}"

  curl -sf \
    --header "Authorization: token ${SNYK_TOKEN}" \
    --header "Content-Type: application/vnd.api+json" \
    "${url}" | jq '.' > "${out}"

  echo "Exported ${scope}/${scope_id} audit logs ${FROM}..${TO} -> ${out}"
}

# Pull group-level events (role, policy, membership changes) and each
# org's events, then forward the JSON files to your SIEM.
[ -n "${SNYK_GROUP_ID:-}" ] && export_audit_logs "groups" "${SNYK_GROUP_ID}"
[ -n "${SNYK_ORG_ID:-}" ]   && export_audit_logs "orgs"   "${SNYK_ORG_ID}"
# HTH Guide Excerpt: end api-audit-log-export
