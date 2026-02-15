#!/usr/bin/env bash
# HTH Okta Control 5.5: Monitor for Cross-Tenant Impersonation
# Profile: L1 | NIST: SI-4, AU-6
# https://howtoharden.com/guides/okta/#55-monitor-for-cross-tenant-impersonation
source "$(dirname "$0")/common.sh"

banner "5.5: Monitor for Cross-Tenant Impersonation"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "5.5 Auditing identity providers for cross-tenant impersonation risk..."

# HTH Guide Excerpt: begin api-list-identity-providers
# Audit all configured identity providers
info "5.5 Listing all configured identity providers..."
IDPS=$(okta_get "/api/v1/idps" 2>/dev/null || echo "[]")
IDP_COUNT=$(echo "${IDPS}" | jq 'length' 2>/dev/null || echo "0")
# HTH Guide Excerpt: end api-list-identity-providers

if [ "${IDP_COUNT}" -eq 0 ]; then
  pass "5.5 No external identity providers configured"
  increment_applied
  summary
  exit 0
fi

info "5.5 Found ${IDP_COUNT} identity provider(s):"
echo "${IDPS}" | jq -r '.[] | "  - \(.name) (type: \(.type), status: \(.status), created: \(.created), protocol: \(.protocol.type))"' 2>/dev/null || true

# HTH Guide Excerpt: begin api-check-idp-discovery
# Audit IDP discovery (routing) policies
info "5.5 Auditing IDP discovery (routing) policies..."
IDP_POLICIES=$(okta_get "/api/v1/policies?type=IDP_DISCOVERY" 2>/dev/null || echo "[]")
IDP_POLICY_COUNT=$(echo "${IDP_POLICIES}" | jq 'length' 2>/dev/null || echo "0")

if [ "${IDP_POLICY_COUNT}" -gt 0 ]; then
  info "5.5 Found ${IDP_POLICY_COUNT} IDP discovery policy/policies:"
  echo "${IDP_POLICIES}" | jq -r '.[] | "  - \(.name) (status: \(.status), lastUpdated: \(.lastUpdated))"' 2>/dev/null || true

  # Get rules for each IDP discovery policy
  for POLICY_ID in $(echo "${IDP_POLICIES}" | jq -r '.[].id' 2>/dev/null); do
    info "5.5 Routing rules for policy ${POLICY_ID}:"
    okta_get "/api/v1/policies/${POLICY_ID}/rules" 2>/dev/null \
      | jq -r '.[] | "    - Rule: \(.name)"' 2>/dev/null || true
  done
fi
# HTH Guide Excerpt: end api-check-idp-discovery

# HTH Guide Excerpt: begin api-check-idp-events
# Search system log for recent IdP lifecycle events (last 7 days)
info "5.5 Checking for recent IdP lifecycle events (last 7 days)..."
SINCE=$(date -d '7 days ago' -u +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null \
  || date -v-7d -u +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || echo "")

if [ -n "${SINCE}" ]; then
  IDP_EVENTS=$(okta_get "/api/v1/logs?filter=eventType+sw+%22system.idp.lifecycle%22&since=${SINCE}" 2>/dev/null || echo "[]")
  EVENT_COUNT=$(echo "${IDP_EVENTS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${EVENT_COUNT}" -gt 0 ]; then
    warn "5.5 Found ${EVENT_COUNT} IdP lifecycle event(s) in the last 7 days -- INVESTIGATE IMMEDIATELY"
    echo "${IDP_EVENTS}" | jq -r '.[] | "  - \(.eventType): \(.actor.displayName) -> \(.target[0].displayName // "unknown") at \(.published)"' 2>/dev/null || true
  else
    pass "5.5 No IdP lifecycle events in the last 7 days"
  fi
else
  warn "5.5 Unable to compute date range -- skipping log check"
fi
# HTH Guide Excerpt: end api-check-idp-events

warn "5.5 IMPORTANT: Configure SIEM alerts for system.idp.lifecycle.* events"
pass "5.5 Cross-tenant impersonation audit complete"
increment_applied

summary
