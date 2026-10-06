#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: cursor-2.2
#   guide:   https://howtoharden.com/guides/cursor/#22-govern-model-selection-with-cursor-router
#   profile: L2
#   mode:    read-only
#   requires: CURSOR_ADMIN_API_KEY(team Admin API key with models:read or admin:*; model access control is Enterprise), curl, jq
# =============================================================================
# HTH Cursor Control 2.2: Govern Model Selection with Cursor Router
# Profile Level: L2 (Walk) | NIST 800-53: SC-7, SA-9
# Source: https://howtoharden.com/guides/cursor/#22-govern-model-selection-with-cursor-router
#
# The router's own toggles (enable, routing preferences, underlying-model
# display, Impose Auto) have no API — they are dashboard-only. What the router
# RESPECTS is the team's model access policy, and that is readable:
#   GET /teams/model-access/configuration  -> state + defaults for new providers/models
#   GET /teams/model-access/providers      -> per-provider / per-model enabled flags
# (https://cursor.com/docs/account/teams/admin-api#model-access — routes are
# marked "in preview and may change"). Provider reads return 409 while the team
# is `unrestricted`, which is itself the finding: no model governance exists.
#
# Exit codes: 0 governed | 1 finding | 2 precondition (incl. 403 = plan lacks
# model access control, or an HTTP 200 without the documented state/providers)
# =============================================================================

set -euo pipefail

[ -n "${CURSOR_ADMIN_API_KEY:-}" ] || { echo "PRECONDITION: set CURSOR_ADMIN_API_KEY — a team Admin API key with models:read (cursor.com/dashboard > API Keys)" >&2; exit 2; }
CURSOR_API_BASE="${CURSOR_API_BASE:-https://api.cursor.com}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-cursor-202.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT

# GET <path>. The key reaches curl on stdin as a config line (-K -), never in argv.
api_get() {
  local code rc
  set +e
  code=$(printf 'user = "%s:"\n' "${CURSOR_ADMIN_API_KEY}" \
    | curl -sS -K - -o "${BODY_FILE}" -w '%{http_code}' "${CURSOR_API_BASE}$1" 2>/dev/null)
  rc=$?
  set -e
  if [ "${rc}" -ne 0 ]; then echo "PRECONDITION: GET $1 — no HTTP response (curl exit ${rc})" >&2; exit 2; fi
  case "${code}" in
    200) return 0 ;;
    401) echo "PRECONDITION: GET $1 returned HTTP 401 — invalid key or missing models:read scope" >&2; exit 2 ;;
    403) echo "PRECONDITION: GET $1 returned HTTP 403 — model access control is not available for this team" >&2; exit 2 ;;
    *)   echo "PRECONDITION: GET $1 returned HTTP ${code}" >&2; exit 2 ;;
  esac
}

# HTH Guide Excerpt: begin api-audit-model-access
FINDINGS=0
api_get "/teams/model-access/configuration"
# A 200 is not proof of data: refuse a body whose `state` is not one of the
# three documented values, rather than reporting it as a policy finding.
jq -e '.state | IN("unrestricted", "custom", "legacy")' "${BODY_FILE}" >/dev/null 2>&1 || {
  echo "PRECONDITION: GET /teams/model-access/configuration returned HTTP 200 without a documented state (unrestricted|custom|legacy) — nothing was audited" >&2
  exit 2
}
STATE=$(jq -r '.state' "${BODY_FILE}")
NEW_PROVIDER=$(jq -r '.newProviderDefault // "null"' "${BODY_FILE}")
NEW_MODEL=$(jq -r '.newModelDefault // "null"' "${BODY_FILE}")
echo "=== Model access policy: state=${STATE} newProviderDefault=${NEW_PROVIDER} newModelDefault=${NEW_MODEL} ==="

if [ "${STATE}" != "custom" ]; then
  echo "FINDING: no custom model-access policy (state=${STATE}) — every catalog model is selectable and routable"
  exit 1
fi

if [ "${NEW_PROVIDER}" = "enabled" ]; then
  echo "FINDING: newProviderDefault=enabled — a provider Cursor adds later is allowed before anyone reviews it"
  FINDINGS=$((FINDINGS + 1))
fi

api_get "/teams/model-access/providers"
# The PASS below means "a custom policy is in force; review this list" — an
# unreadable list must not stand in for an empty one.
jq -e '(.providers | type == "array") and all(.providers[]; (.models // []) | type == "array")' "${BODY_FILE}" >/dev/null 2>&1 || {
  echo "PRECONDITION: GET /teams/model-access/providers returned HTTP 200 without the documented providers array — nothing was audited" >&2
  exit 2
}
echo "=== Enabled providers and models (review against your approved-model register) ==="
jq -r '
  .providers[]
  | select(.enabled == true)
  | "  \(.id // .name):",
    ((.models // [])[] | select(.enabled == true) | "    - \(.id // .name)")' "${BODY_FILE}"

[ "${FINDINGS}" -eq 0 ] && { echo "PASS: custom policy in force; review the enabled list above"; exit 0; }
exit 1
# HTH Guide Excerpt: end api-audit-model-access
