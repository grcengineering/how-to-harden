#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: okta-2.2
#   guide:   https://howtoharden.com/guides/okta/#22-restrict-admin-console-access-by-ip
#   profile: L1
#   mode:    read-only
#   requires: OKTA_DOMAIN, OKTA_API_TOKEN(SSWS token owned by a Read-only Administrator), HTH_PROFILE_LEVEL(optional)
# HTH Okta Control 2.2: Restrict Admin Console Access by IP
# Profile: L1 | NIST: AC-3(7)
# https://howtoharden.com/guides/okta/#22-restrict-admin-console-access-by-ip
#
# Read-only audit. A token owned by a Read-Only Administrator is sufficient.
# Admin Console IP restriction lives in the Okta Admin Console app sign-in
# policy: an ALLOW rule scoped to a network zone (conditions.network.connection
# "ZONE") above a catch-all rule whose access is DENY (Okta Management API,
# Policy: AccessPolicyRule, PolicyNetworkCondition). This pack never edits that
# policy -- a wrong zone there locks every administrator out.
source "$(dirname "$0")/common.sh"

banner "2.2: Restrict Admin Console Access by IP"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.2 Auditing network restrictions on the Okta Admin Console policy..."

# HTH Guide Excerpt: begin api-check-admin-console-network
# The Okta Admin Console is the app named "saasure" (a failed read stops the pack)
ADMIN_APP=$(okta_get "/api/v1/apps?filter=name%20eq%20%22saasure%22" | jq -c '.[0] // empty')
if [ -z "${ADMIN_APP}" ]; then
  fail "2.2 Okta Admin Console app (saasure) not returned -- cannot audit its policy"
  increment_failed
  summary
fi
POLICY_ID=$(printf '%s' "${ADMIN_APP}" | jq -r '._links.accessPolicy.href | split("/") | last')
RULES=$(okta_get "/api/v1/policies/${POLICY_ID}/rules")

ZONED_ALLOW=$(printf '%s' "${RULES}" | jq '[.[] | select(.status == "ACTIVE"
  and .actions.appSignOn.access == "ALLOW"
  and .conditions.network.connection == "ZONE"
  and ((.conditions.network.include // []) | length > 0))] | length')
OPEN_ALLOW=$(printf '%s' "${RULES}" | jq '[.[] | select(.status == "ACTIVE"
  and .actions.appSignOn.access == "ALLOW"
  and ((.conditions.network.connection // "ANYWHERE") == "ANYWHERE"))] | length')
# HTH Guide Excerpt: end api-check-admin-console-network

printf '%s' "${RULES}" | jq -r '.[] | "  - \(.name) (priority \(.priority)): access=\(.actions.appSignOn.access), network=\(.conditions.network.connection // "ANYWHERE")"'

if [ "${ZONED_ALLOW}" -gt 0 ] && [ "${OPEN_ALLOW}" -eq 0 ]; then
  pass "2.2 Admin Console access is allowed only from network zones (${ZONED_ALLOW} zoned ALLOW rule(s), no ALLOW from anywhere)"
else
  warn "2.2 Admin Console allows access from anywhere (${OPEN_ALLOW} unzoned ALLOW rule(s), ${ZONED_ALLOW} zoned) -- see Section 2.2"
fi
increment_applied

summary
