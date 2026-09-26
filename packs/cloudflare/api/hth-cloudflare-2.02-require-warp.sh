#!/usr/bin/env bash
# HTH Cloudflare Control 2.2: Require WARP for Application Access
# Profile: L2 | NIST: AC-2(11) | CIS: 4.1, 6.4
# https://howtoharden.com/guides/cloudflare/#22-require-warp-for-application-access
#
# Read-only audit. Passes only when a WARP posture check exists AND at least
# one Access application policy requires it. A posture check that no policy
# references enforces nothing.
source "$(dirname "$0")/common.sh"

banner "2.2: Require WARP for Application Access"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "2.2 Checking device posture rules for WARP requirement..."

# HTH Guide Excerpt: begin api-check-warp-posture
# Check for a WARP device posture rule
POSTURE_RULES=$(cf_get "/accounts/${CF_ACCOUNT_ID}/devices/posture") || {
  fail "2.2 Unable to retrieve device posture rules"
  increment_failed
  summary
  exit 0
}

WARP_RULE_IDS=$(echo "${POSTURE_RULES}" | jq -c '[.result[] | select(.type == "warp") | .id]')
if [ "$(echo "${WARP_RULE_IDS}" | jq 'length')" = "0" ]; then
  fail "2.2 No WARP device posture check found -- add one under Posture checks"
  increment_failed
  summary
  exit 0
fi
info "2.2 WARP device posture check(s): $(echo "${WARP_RULE_IDS}" | jq 'length')"

# Is the WARP check actually required by any application policy?
APPS=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps") || {
  fail "2.2 Unable to retrieve Access applications"
  increment_failed
  summary
  exit 0
}

ENFORCING=0
FETCH_ERR=0
while IFS= read -r app_id; do
  APP_POLICIES=$(cf_get_all "/accounts/${CF_ACCOUNT_ID}/access/apps/${app_id}/policies") || { FETCH_ERR=1; continue; }
  HITS=$(echo "${APP_POLICIES}" | jq --argjson ids "${WARP_RULE_IDS}" \
    '[.result[].require[]? | select(.device_posture.integration_uid as $u | $ids | index($u))] | length')
  [ "${HITS}" -gt 0 ] && ENFORCING=$((ENFORCING + 1))
done < <(echo "${APPS}" | jq -r '.result[].id')
# HTH Guide Excerpt: end api-check-warp-posture

if [ "${FETCH_ERR}" = "1" ]; then
  fail "2.2 Audit incomplete -- one or more application policy lists could not be read"
  increment_failed
elif [ "${ENFORCING}" -gt 0 ]; then
  pass "2.2 ${ENFORCING} application(s) require the WARP posture check"
  increment_applied
else
  fail "2.2 The WARP posture check exists but no application policy requires it"
  increment_failed
fi

summary
