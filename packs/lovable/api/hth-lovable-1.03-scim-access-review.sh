#!/usr/bin/env bash
# Control: 1.3 Automate Joiner/Leaver Flow with SCIM
# Profile Level: L2 (Walk) | Plan: Enterprise only
# Frameworks: NIST 800-53 AC-2/AC-2(3) | CIS Controls v8 5.1/5.3/6.1
# Guide: https://howtoharden.com/guides/lovable/#13-automate-joinerleaver-flow-with-scim
# Interface: Lovable SCIM 2.0 API — https://docs.lovable.dev/features/business/scim
#   Base URL: https://api.lovable.dev/scim/v2
#   Token:    Settings -> Access -> Identity -> SCIM provisioning (shown ONCE; "Rotate" to reissue)
#
# NOTE ON SCOPE (do not extend this pack): Lovable publishes NO admin/management REST API.
# SCIM is the ONLY documented programmatic admin surface. Workspace security settings,
# audit logs, and project controls are console-only — audit logs export as JSONL by hand.
# Do not invent api.lovable.dev management endpoints.
set -euo pipefail

: "${LOVABLE_SCIM_TOKEN:?Set LOVABLE_SCIM_TOKEN (Settings -> Access -> Identity -> SCIM provisioning)}"
SCIM_BASE="${LOVABLE_SCIM_BASE:-https://api.lovable.dev/scim/v2}"

# Never put the token in the URL — Bearer header only (URLs leak to logs/history/referrers).
scim_get() {
  curl -fsS -X GET "${SCIM_BASE}$1" \
    -H "Authorization: Bearer ${LOVABLE_SCIM_TOKEN}" \
    -H "Accept: application/scim+json"
}

# HTH Guide Excerpt: begin scim-user-review
# Access review: list every SCIM-provisioned user with active state and role-bearing groups.
# Reconcile this against your IdP; anyone here who is inactive in the IdP is a deprovisioning gap.
scim_get "/Users?count=200" | jq -r '
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
scim_get "/Groups?count=200" | jq -r '
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
  RESULT=$(scim_get "/Users?filter=${ENCODED}")
  COUNT=$(printf '%s' "${RESULT}" | jq -r '.totalResults // 0')
  if [ "${COUNT}" = "0" ]; then
    echo "PASS 1.3: ${LEAVER_EMAIL} is not provisioned in the workspace."
  else
    printf '%s' "${RESULT}" | jq -r '.Resources[] | "FAIL 1.3: \(.userName) still present (active=\(.active))"'
  fi
fi
# HTH Guide Excerpt: end scim-deprovision-check
