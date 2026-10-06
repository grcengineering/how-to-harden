#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: asana-3.3
#   guide:   https://howtoharden.com/guides/asana/#33-configure-mobile-security
#   profile: L2
#   mode:    read-only
#   requires: ASANA_PAT(personal access token of an Admin or Super Admin; GET /roles is admin-only), ASANA_WORKSPACE_GID
# =============================================================================
# HTH Asana Control 3.3: Configure Mobile Security
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 13.7 | NIST 800-53 AC-19
# Source: https://howtoharden.com/guides/asana/#33-configure-mobile-security
# Dependencies: bash, curl (7.55+ for -H @file), jq
# API (verified against Asana's OpenAPI spec asana_oas.yaml and the Roles reference, 2026-09-24):
#   GET /roles?workspace={workspace_gid}   permissions.download_mobile_attachments
#   ("Controls whether users with this role can download attachments from mobile app")
#   https://developers.asana.com/reference/roles
#
# ── TRAP 1: one mobile control has an API, the rest do not ──────────────────
# Biometric login, screen capture, copy-paste and widgets are admin-console
# settings with no read or write endpoint; their changes surface only as
# workspace_mobile_app_* audit events (see 4.2). Attachment download is the one
# mobile control carried on the role, so it is the one this pack can prove.
#
# ── TRAP 2: unreported is not clean ─────────────────────────────────────────
# A member- or guest-based role that does not report download_mobile_attachments
# was not evaluated, and neither was a role whose base_role_type is missing or
# not one of guest, member, admin, super_admin. Either one keeps the pack from
# reporting compliant: it exits 2 unless it already has a finding to report.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (auth, tier, network, empty scan, unevaluated role, unexpected error)
# =============================================================================

set -eEuo pipefail
trap 'echo "PRECONDITION: unexpected failure at line ${LINENO}" >&2; exit 2' ERR

# A missing input is a precondition (exit 2), never a finding (exit 1).
need() { if [ -z "${!1:-}" ]; then echo "PRECONDITION: set $1 — $2" >&2; exit 2; fi; }
need ASANA_PAT "personal access token of an Asana Admin or Super Admin"
need ASANA_WORKSPACE_GID "the workspace gid of the organization"
ASANA_API_BASE="${ASANA_API_BASE:-https://app.asana.com/api/1.0}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-303.XXXXXX")"
ITEMS_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-asana-303i.XXXXXX")"
trap 'rm -f "${BODY_FILE}" "${ITEMS_FILE}"' EXIT

# One GET. Fails closed: anything but HTTP 200 with a JSON object body exits 2.
# The token reaches curl through a process-substitution header file, never argv.
asana_get() {
  local code rc=0
  code=$(curl -sS --max-time 60 -o "${BODY_FILE}" -w '%{http_code}' \
    -H @<(printf 'Authorization: Bearer %s\n' "${ASANA_PAT}") \
    -H 'Accept: application/json' "${ASANA_API_BASE}$1" 2>/dev/null) || rc=$?
  if [ "${rc}" -ne 0 ]; then
    echo "PRECONDITION: GET ${1%%\?*} got no HTTP response (curl exit ${rc})" >&2; exit 2
  fi
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: GET ${1%%\?*} returned HTTP ${code}: $(jq -r '[.errors[]?.message] | join("; ")' "${BODY_FILE}" 2>/dev/null || true)" >&2
    exit 2
  fi
  if ! jq -e 'type == "object"' "${BODY_FILE}" >/dev/null 2>&1; then
    echo "PRECONDITION: GET ${1%%\?*} returned a non-JSON body" >&2; exit 2
  fi
}

# Follows next_page.offset to exhaustion into ITEMS_FILE, one object per line.
asana_paginate() {  # asana_paginate <path> <query>
  local path="$1" query="$2" offset="" pages=0
  : > "${ITEMS_FILE}"
  while :; do
    if [ -n "${offset}" ]; then asana_get "${path}?${query}&offset=${offset}"; else asana_get "${path}?${query}"; fi
    if ! jq -e '.data | type == "array"' "${BODY_FILE}" >/dev/null 2>&1; then
      echo "PRECONDITION: ${path} response carries no data array" >&2; exit 2
    fi
    jq -c '.data[]' "${BODY_FILE}" >> "${ITEMS_FILE}"
    offset=$(jq -r '.next_page.offset // "" | @uri' "${BODY_FILE}")
    pages=$((pages + 1))
    [ -n "${offset}" ] || break
    if [ "${pages}" -ge 1000 ]; then echo "PRECONDITION: ${path} pagination exceeded 1000 pages" >&2; exit 2; fi
  done
}

# HTH Guide Excerpt: begin mobile-attachment-audit
asana_paginate "/roles" \
  "workspace=${ASANA_WORKSPACE_GID}&opt_fields=name,is_standard_role,base_role_type,permissions.download_mobile_attachments&limit=100"
roles=$(jq -s 'length' "${ITEMS_FILE}")
reported=$(jq -s '[.[] | select(.permissions.download_mobile_attachments != null)] | length' "${ITEMS_FILE}")
if [ "${roles}" -eq 0 ] || [ "${reported}" -eq 0 ]; then
  echo "PRECONDITION: GET /roles returned ${roles} role(s), none reporting download_mobile_attachments; not evaluated (TRAP 2)" >&2
  exit 2
fi
echo "Asana 3.3 — mobile attachment download permission"
echo "  roles scanned: ${roles}"
jq -r 'select(((.base_role_type // "") == "member" or (.base_role_type // "") == "guest")
              and .permissions.download_mobile_attachments == true)
       | "FINDING: role \"\(.name)\" (base \(.base_role_type)) can download attachments on the mobile app."' "${ITEMS_FILE}"
downloaders=$(jq -s '[.[] | select(((.base_role_type // "") == "member" or (.base_role_type // "") == "guest")
                                    and .permissions.download_mobile_attachments == true)] | length' "${ITEMS_FILE}")
# TRAP 2. Roles that could not be judged: unknown base type, or no value reported.
UNEVALUATED='def known: (.base_role_type // "") as $b | ["guest", "member", "admin", "super_admin"] | any(. == $b);
             def judged: .base_role_type == "member" or .base_role_type == "guest";
             select((known | not) or (judged and .permissions.download_mobile_attachments == null))'
jq -r "${UNEVALUATED}"' | "INCONCLUSIVE: role \"\(.name)\" (base \(.base_role_type // "unreported")) was not evaluated: no download_mobile_attachments value, or an unknown base type."' "${ITEMS_FILE}"
unevaluated=$(jq -s "[.[] | ${UNEVALUATED}] | length" "${ITEMS_FILE}")
# HTH Guide Excerpt: end mobile-attachment-audit

if [ "${downloaders}" -gt 0 ]; then
  exit 1
fi
if [ "${unevaluated}" -gt 0 ]; then
  echo "PRECONDITION: ${unevaluated} role(s) could not be evaluated, so the pack does not report compliant (TRAP 2)" >&2
  exit 2
fi
echo "COMPLIANT: no member- or guest-based role can download attachments on mobile."
exit 0
