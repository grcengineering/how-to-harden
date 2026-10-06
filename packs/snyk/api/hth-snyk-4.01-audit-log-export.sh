#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: snyk-4.1
#   guide:   https://howtoharden.com/guides/snyk/#41-audit-logs-enterprise
#   profile: L1
#   mode:    read-only
#   requires: SNYK_TOKEN(org.audit_log.read or group.audit.read), SNYK_ORG_ID and/or SNYK_GROUP_ID
# =============================================================================
# HTH Snyk Control 4.1: Audit Logs (Enterprise)
# Profile: L1 | NIST 800-53: AU-2, AU-3
# https://howtoharden.com/guides/snyk/#41-audit-logs-enterprise
#
# Exports Snyk audit logs for SIEM retention. Snyk keeps a rolling 90 days
# and the endpoints exclude login/logout events, so schedule this well inside
# the window and keep IdP logs as the sign-in system of record.
#
# Plan gate: audit logs are available only on Enterprise plans.
# Least privilege (the "Required permissions" of each endpoint in Snyk's REST spec):
#   GET /orgs/{org_id}/audit_logs/search      org.audit_log.read (Org Collaborator and above)
#   GET /groups/{group_id}/audit_logs/search  group.audit.read   (Group Admin)
# from/to must be RFC3339 (e.g. 2024-01-02T16:30:00Z); size max 100; results
# page by cursor (read from links.next, re-applied to the original query), and
# every page is read.
#
# Output: one NDJSON file per scope (one audit event per line). It is written
# as <file>.partial and renamed only after the last page arrives, so a SIEM
# forwarder never picks up a truncated or empty export from a failed run.
# Exit codes: 0 exported | 2 precondition (including an unwritable
#             SNYK_AUDIT_OUT_DIR), bad input, or a request that did not succeed
# Requires: curl, jq.
# Verified against:
#   https://docs.snyk.io/developer-tools/snyk-api/reference/audit-logs
#   https://docs.snyk.io/developer-tools/snyk-api/authentication-for-api
set -euo pipefail

command -v curl >/dev/null || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq >/dev/null || { echo "PRECONDITION: jq not found" >&2; exit 2; }

# HTH Guide Excerpt: begin api-snyk-rest-get-paginated
if [ -z "${SNYK_TOKEN:-}" ]; then
  echo "PRECONDITION: set SNYK_TOKEN - see the least-privilege note in this pack header" >&2; exit 2
fi
SNYK_API="${SNYK_API:-https://api.snyk.io}"
SNYK_API_VERSION="${SNYK_API_VERSION:-2024-10-15}"
UUID_RE='^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
MAX_PAGES="${SNYK_MAX_PAGES:-1000}"

# One GET that fails closed: a transport error or any HTTP status >= 400
# aborts the export instead of being read as an empty result.
snyk_get() {
  curl -sS -f \
    --header "Authorization: token ${SNYK_TOKEN}" \
    --header "Accept: application/vnd.api+json" \
    "$1"
}

# The next page is requested by re-issuing the ORIGINAL query plus the cursor
# taken from links.next (a string or {href}). Following the link verbatim
# would trust it to carry from/to; if it did not, page 2 would silently fall
# back to the API's default window. Only the cursor value is taken, so the
# token never goes anywhere but the configured API host.
next_cursor() {
  local next cursor
  next=$(printf '%s' "$1" | jq -r '.links.next // empty | if type == "object" then .href else . end') || return 1
  [ -n "${next}" ] || return 0
  cursor=$(printf '%s' "${next}" | sed -n 's/.*[?&]cursor=\([^&]*\).*/\1/p')
  [ -n "${cursor}" ] || { echo "ERROR: links.next carries no cursor parameter" >&2; return 1; }
  printf '%s' "${cursor}"
}
# HTH Guide Excerpt: end api-snyk-rest-get-paginated

# HTH Guide Excerpt: begin api-audit-log-export
# Collection window in UTC RFC3339, as the API requires. The default is the
# whole previous UTC day (from is inclusive, to is exclusive). Run at least
# daily: events age out after 90 days. GNU date first, BSD/macOS date second.
FROM="${SNYK_AUDIT_FROM:-$(date -u -d '1 day ago' +%Y-%m-%dT00:00:00Z 2>/dev/null || date -u -v-1d +%Y-%m-%dT00:00:00Z)}"
TO="${SNYK_AUDIT_TO:-$(date -u +%Y-%m-%dT00:00:00Z)}"
RFC3339_RE='^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$'
if ! [[ "${FROM}" =~ ${RFC3339_RE} && "${TO}" =~ ${RFC3339_RE} ]]; then
  echo "ERROR: SNYK_AUDIT_FROM and SNYK_AUDIT_TO must be UTC RFC3339, e.g. 2026-01-02T00:00:00Z" >&2
  exit 2
fi
OUT_DIR="${SNYK_AUDIT_OUT_DIR:-./snyk-audit-logs}"

# Export one scope: "orgs <org_id>" or "groups <group_id>".
export_audit_logs() {
  local scope="$1" scope_id="$2" base url page cursor count=0 pages=0 n
  local out="${OUT_DIR}/${scope}-${scope_id}-${FROM//:/}_${TO//:/}.ndjson"
  base="${SNYK_API}/rest/${scope}/${scope_id}/audit_logs/search?version=${SNYK_API_VERSION}&from=${FROM}&to=${TO}&size=100&sort_order=ASC"
  url="${base}"
  : >"${out}.partial" \
    || { echo "ERROR: cannot write to SNYK_AUDIT_OUT_DIR (${OUT_DIR})" >&2; return 2; }
  while [ -n "${url}" ]; do
    page=$(snyk_get "${url}") \
      || { rm -f "${out}.partial"; echo "ERROR: audit-log request did not succeed for ${scope}/${scope_id}" >&2; return 2; }
    printf '%s' "${page}" | jq -e '.data.items | type == "array"' >/dev/null \
      || { rm -f "${out}.partial"; echo "ERROR: response is not the documented audit-log shape" >&2; return 2; }
    printf '%s' "${page}" | jq -c '.data.items[]' >>"${out}.partial" \
      || { rm -f "${out}.partial"; return 2; }
    n=$(printf '%s' "${page}" | jq '.data.items | length')
    count=$((count + n))
    pages=$((pages + 1))
    [ "${n}" -gt 0 ] || break
    [ "${pages}" -lt "${MAX_PAGES}" ] \
      || { rm -f "${out}.partial"; echo "ERROR: pagination did not end after ${MAX_PAGES} pages" >&2; return 2; }
    cursor=$(next_cursor "${page}") || { rm -f "${out}.partial"; return 2; }
    if [ -n "${cursor}" ]; then url="${base}&cursor=${cursor}"; else url=""; fi
  done
  mv "${out}.partial" "${out}" \
    || { rm -f "${out}.partial"; echo "ERROR: cannot write to SNYK_AUDIT_OUT_DIR (${OUT_DIR})" >&2; return 2; }
  echo "Exported ${count} event(s) for ${scope}/${scope_id} ${FROM}..${TO} -> ${out}"
}
# HTH Guide Excerpt: end api-audit-log-export

# HTH Guide Excerpt: begin api-audit-log-export-run
# Pull group-level events (role, policy, membership changes) and each org's
# events, then point the SIEM forwarder at the finished .ndjson files.
if [ -z "${SNYK_GROUP_ID:-}" ] && [ -z "${SNYK_ORG_ID:-}" ]; then
  echo "ERROR: set SNYK_GROUP_ID and/or SNYK_ORG_ID - nothing to export" >&2; exit 2
fi
mkdir -p "${OUT_DIR}" \
  || { echo "ERROR: cannot create SNYK_AUDIT_OUT_DIR (${OUT_DIR})" >&2; exit 2; }
for scope in groups orgs; do
  if [ "${scope}" = groups ]; then scope_id="${SNYK_GROUP_ID:-}"; else scope_id="${SNYK_ORG_ID:-}"; fi
  [ -n "${scope_id}" ] || continue
  [[ "${scope_id}" =~ ${UUID_RE} ]] || { echo "ERROR: the ${scope} id is not a UUID" >&2; exit 2; }
  export_audit_logs "${scope}" "${scope_id}"
done
# HTH Guide Excerpt: end api-audit-log-export-run
