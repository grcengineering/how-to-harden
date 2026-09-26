#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: asana-2.3
#   guide:   https://howtoharden.com/guides/asana/#23-configure-scim-provisioning
#   profile: L2
#   mode:    read-only
#   requires: ASANA_SERVICE_ACCOUNT_PAT(service account with Scoped permissions > User provisioning (SCIM); Enterprise domain), ASANA_IDP_ACTIVE_USERS_FILE(one email per line, exported from the IdP)
# =============================================================================
# HTH Asana Control 2.3: Configure SCIM Provisioning
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 5.3 | NIST 800-53 AC-2
# Source: https://howtoharden.com/guides/asana/#23-configure-scim-provisioning
# Dependencies: bash, curl (7.55+ for -H @file), jq
# API (verified against https://developers.asana.com/docs/scim, 2026-09-24):
#   Base https://app.asana.com/api/1.0/scim
#   GET /Users: "Return full list of users in the domain. Does not return Asana
#   guest users." Accepted query parameter: filter for userName.
#   "Only Service Accounts in Enterprise Domains can access SCIM endpoints."
#
# ── TRAP 1: the IdP push is not the proof ───────────────────────────────────
# The guide's Step 4 asks you to verify after offboarding that the user is no
# longer active in Asana "rather than assuming the IdP push succeeded". This pack
# is that check: an Asana user whose SCIM `active` is true but who is absent from
# the IdP's active-user export is an orphaned account with standing access.
#
# ── TRAP 2: guests are invisible here ───────────────────────────────────────
# GET /Users does not return guest users, so this reconciliation covers members
# only. Guest population is audited from the membership list in 3.1.
#
# ── TRAP 3: a short page is not the whole domain ────────────────────────────
# Asana documents GET /Users as the full list and documents no paging
# parameters. If totalResults ever exceeds the Resources returned, the pack
# exits 2 instead of reconciling against a partial list, and an empty domain
# (totalResults 0) also exits 2: a scan that saw nobody proves nothing.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, tier, network, bad input, partial scan)
# =============================================================================

set -eEuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO}" >&2; exit 2' ERR

# A missing input is a precondition (exit 2), never a finding (exit 1).
need() { if [ -z "${!1:-}" ]; then echo "PRECONDITION: set $1 — $2" >&2; exit 2; fi; }
need ASANA_SERVICE_ACCOUNT_PAT "service account token scoped to User provisioning (SCIM)"
need ASANA_IDP_ACTIVE_USERS_FILE "path to the IdP export of active user emails, one per line"
ASANA_SCIM_BASE="${ASANA_SCIM_BASE:-https://app.asana.com/api/1.0/scim}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }
if [ ! -r "${ASANA_IDP_ACTIVE_USERS_FILE}" ]; then
  echo "PRECONDITION: cannot read ASANA_IDP_ACTIVE_USERS_FILE" >&2; exit 2
fi

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-203.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT
FINDINGS=0

# One GET. Fails closed: anything but HTTP 200 with a JSON object body exits 2.
# The token reaches curl through a process-substitution header file, never argv.
scim_get() {
  local code rc=0
  code=$(curl -sS --max-time 120 -o "${BODY_FILE}" -w '%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "${ASANA_SERVICE_ACCOUNT_PAT}") \
    "${ASANA_SCIM_BASE}$1" 2>/dev/null) || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${1} got no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET ${1} returned HTTP ${code}" >&2
    echo "  SCIM requires a service account token on an Enterprise domain, scoped to User provisioning (SCIM)." >&2
    exit 2
  fi
  if ! jq -e 'type == "object"' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET ${1} returned a non-JSON body" >&2; exit 2
  fi
}

# HTH Guide Excerpt: begin scim-orphan-reconciliation
scim_get "/Users"
if ! jq -e '(.Resources | type == "array") and (.totalResults | type == "number")' "${BODY_FILE}" >/dev/null 2>&1; then
  echo "PRECONDITION: /Users is not a SCIM ListResponse (no Resources array or totalResults)" >&2; exit 2
fi
total=$(jq '.totalResults' "${BODY_FILE}")
returned=$(jq '.Resources | length' "${BODY_FILE}")
if [ "${total}" -eq 0 ] || [ "${returned}" -eq 0 ]; then
  echo "PRECONDITION: SCIM /Users returned no users; nothing was reconciled (TRAP 3)" >&2; exit 2
fi
if [ "${total}" -gt "${returned}" ]; then
  echo "PRECONDITION: SCIM returned ${returned} of ${total} users; refusing to reconcile a partial list (TRAP 3)" >&2; exit 2
fi

# Lower-cased userName of every user SCIM reports as active.
asana_active=$(jq -c '[.Resources[] | select(.active == true) | .userName // empty | ascii_downcase] | unique' "${BODY_FILE}")
idp_active=$(jq -Rsc '[split("\n")[] | gsub("^\\s+|\\s+$"; "") | ascii_downcase | select(length > 0)] | unique' "${ASANA_IDP_ACTIVE_USERS_FILE}")
if [ "$(jq -n --argjson i "${idp_active}" '$i | length')" -eq 0 ]; then
  echo "PRECONDITION: ASANA_IDP_ACTIVE_USERS_FILE lists no users" >&2; exit 2
fi

echo "Asana 2.3 — SCIM user reconciliation (members only; guests are not returned, TRAP 2)"
echo "  SCIM users: ${total} (active $(jq '[.Resources[] | select(.active == true)] | length' "${BODY_FILE}"), deprovisioned $(jq '[.Resources[] | select(.active != true)] | length' "${BODY_FILE}"))"
echo "  IdP active users: $(jq -n --argjson i "${idp_active}" '$i | length')"

orphans=$(jq -nc --argjson a "${asana_active}" --argjson i "${idp_active}" '$a - $i')
unprovisioned=$(jq -nc --argjson a "${asana_active}" --argjson i "${idp_active}" '$i - $a')
if [ "$(jq -n --argjson o "${orphans}" '$o | length')" -gt 0 ]; then
  echo "FINDING: active in Asana but not active in the IdP (orphaned, TRAP 1):"
  jq -nr --argjson o "${orphans}" '$o[] | "    - \(.)"'
  FINDINGS=$((FINDINGS + 1))
fi
if [ "$(jq -n --argjson u "${unprovisioned}" '$u | length')" -gt 0 ]; then
  echo "  info: $(jq -n --argjson u "${unprovisioned}" '$u | length') IdP-active users have no active Asana account (not assigned the app, or pending)."
fi
# HTH Guide Excerpt: end scim-orphan-reconciliation

if [ "${FINDINGS}" -gt 0 ]; then
  exit 1
fi
echo "COMPLIANT: every active Asana member is active in the IdP."
exit 0
