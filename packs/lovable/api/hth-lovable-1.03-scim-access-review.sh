#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: lovable-1.3
#   guide:   https://howtoharden.com/guides/lovable/#13-automate-joinerleaver-flow-with-scim
#   profile: L2
#   mode:    read-only
#   requires: LOVABLE_SCIM_TOKEN(SCIM API key; Lovable issues no read-only variant — this pack only GETs), LOVABLE_SCIM_BASE(optional)
# Control: 1.3 Automate Joiner/Leaver Flow with SCIM
# Profile Level: L2 (Walk) | Plan: Enterprise only
# Frameworks: NIST 800-53 AC-2/AC-2(3) | CIS Controls v8 5.1/5.3/6.1
# Interface: Lovable SCIM 2.0 API — https://docs.lovable.dev/features/business/scim
#   Base URL: https://api.lovable.dev/scim/v2
#   Token:    Settings -> Access -> Identity -> SCIM provisioning (copyable only on the setup screen; "Rotate API key" to reissue)
#
# NOTE ON SCOPE: Lovable's public REST API (https://api.lovable.dev/v1, GA 2026-09-11)
# covers workspace settings, members/groups, projects, publishing and security scans;
# SCIM remains the only surface for user/group provisioning. This pack reads SCIM only.
#
# Exit codes: 0 review printed / leaver absent | 1 leaver still present | 2 partial or unreadable response
set -euo pipefail

# Explicit guard (exit 2): a bare ${VAR:?} exits 1, which would read as "leaver still present".
[ -n "${LOVABLE_SCIM_TOKEN:-}" ] || { echo "PRECONDITION: set LOVABLE_SCIM_TOKEN (Settings -> Access -> Identity -> SCIM provisioning)" >&2; exit 2; }
SCIM_BASE="${LOVABLE_SCIM_BASE:-https://api.lovable.dev/scim/v2}"

# Never put the token in the URL — Bearer header only (URLs leak to logs/history/referrers).
scim_get() {
  curl -fsS -X GET "${SCIM_BASE}$1" \
    -H "Authorization: Bearer ${LOVABLE_SCIM_TOKEN}" \
    -H "Accept: application/scim+json"
}

# A listing is complete only when it carries a Resources array and totalResults does
# not exceed what came back. Anything else is a partial or unreadable listing.
scim_complete() {
  jq -e '(.Resources | type) == "array" and (.totalResults | type) == "number" and .totalResults <= (.Resources | length)' >/dev/null
}

# HTH Guide Excerpt: begin scim-user-review
# Access review: list every SCIM-provisioned user with active state and role-bearing groups.
# Reconcile this against your IdP; anyone here who is inactive in the IdP is a deprovisioning gap.
USERS_JSON=$(scim_get "/Users?count=200") || { echo "ERROR 1.3: GET /Users failed — review INCOMPLETE" >&2; exit 2; }
printf '%s' "${USERS_JSON}" | scim_complete || {
  echo "ERROR 1.3: /Users returned a partial or unreadable listing (over 200 users, or an unexpected body) — review INCOMPLETE" >&2
  exit 2
}
printf '%s' "${USERS_JSON}" | jq -r '
  ["ACTIVE","USERNAME","DISPLAY_NAME","GROUPS"],
  (.Resources[] | [
      (.active | tostring),
      .userName,
      (.displayName // "-"),
      ([.groups[]?.display] | join(",") // "-")
  ]) | @tsv' | column -t -s$'\t'
# HTH Guide Excerpt: end scim-user-review

# HTH Guide Excerpt: begin scim-group-role-map
# Group -> role mapping review. Lovable assigns workspace roles (viewer/editor/admin) via
# SCIM group membership; when a user is in several mapped groups the HIGHEST role wins.
# Flag any group mapped to admin and confirm its IdP membership is deliberately small.
GROUPS_JSON=$(scim_get "/Groups?count=200") || { echo "ERROR 1.3: GET /Groups failed — review INCOMPLETE" >&2; exit 2; }
printf '%s' "${GROUPS_JSON}" | scim_complete || {
  echo "ERROR 1.3: /Groups returned a partial or unreadable listing — review INCOMPLETE" >&2
  exit 2
}
printf '%s' "${GROUPS_JSON}" | jq -r '
  .Resources[] | [
      .displayName,
      ((.members // []) | length | tostring)
  ] | @tsv' | column -t -s$'\t'
# HTH Guide Excerpt: end scim-group-role-map

# HTH Guide Excerpt: begin scim-deprovision-check
# Leaver verification: confirm a departed user is gone. IdP deactivation should remove them
# from the workspace and block login. An "active: true" result here means the leaver still
# has workspace access — investigate the IdP assignment before closing the offboarding ticket.
LEAVER_EMAIL="${1:-}"
if [ -n "${LEAVER_EMAIL}" ]; then
  ENCODED=$(printf '%s' "userName eq \"${LEAVER_EMAIL}\"" | jq -sRr @uri)
  RESULT=$(scim_get "/Users?filter=${ENCODED}") || { echo "ERROR 1.3: SCIM search for ${LEAVER_EMAIL} failed; leaver status UNKNOWN" >&2; exit 2; }
  # Fail closed: only a numeric totalResults that is consistent with Resources is evidence
  # that a search actually ran. An error envelope, {} or a null count means UNKNOWN, never PASS.
  COUNT=$(printf '%s' "${RESULT}" | jq -er 'select((.totalResults | type) == "number" and ((.Resources // []) | length) <= .totalResults) | .totalResults') || {
    echo "ERROR 1.3: unexpected SCIM response for ${LEAVER_EMAIL}; leaver status UNKNOWN" >&2
    exit 2
  }
  if [ "${COUNT}" = "0" ]; then
    echo "PASS 1.3: ${LEAVER_EMAIL} is not provisioned in the workspace."
  else
    printf '%s' "${RESULT}" | jq -r '.Resources[] | "FAIL 1.3: \(.userName) still present (active=\(.active))"'
    exit 1
  fi
fi
# HTH Guide Excerpt: end scim-deprovision-check
