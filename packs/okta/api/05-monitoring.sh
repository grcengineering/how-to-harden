#!/usr/bin/env bash
# HTH Okta Code Pack -- Section 5: Monitoring & Detection
# Controls: 5.1, 5.2, 5.4, 5.5
# https://howtoharden.com/guides/okta/#5-monitoring--detection
source "$(dirname "$0")/common.sh"

banner "Section 5: Monitoring & Detection"

# ===========================================================================
# 5.1 Enable Comprehensive System Logging
# Profile: L1 | NIST: AU-2, AU-3, AU-6 | DISA STIG: V-273202 (HIGH)
# ===========================================================================
control_5_1() {
  should_apply 1 || { increment_skipped; return 0; }
  info "5.1 Verifying system logging configuration..."

  # Verify System Log API is accessible and returning events
  info "5.1 Testing System Log API access..."
  LOG_RESPONSE=$(okta_get "/api/v1/logs?limit=1" 2>/dev/null || echo "[]")
  LOG_COUNT=$(echo "${LOG_RESPONSE}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${LOG_COUNT}" -gt 0 ]; then
    LATEST_EVENT=$(echo "${LOG_RESPONSE}" | jq -r '.[0] | "\(.eventType) at \(.published)"' 2>/dev/null || echo "unknown")
    pass "5.1 System Log API accessible -- latest event: ${LATEST_EVENT}"
  else
    warn "5.1 System Log API returned no events -- verify API token has log read permissions"
  fi

  # Check for log streaming integrations
  info "5.1 Checking log streaming configuration..."
  LOG_STREAMS=$(okta_get "/api/v1/logStreams" 2>/dev/null || echo "[]")
  STREAM_COUNT=$(echo "${LOG_STREAMS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${STREAM_COUNT}" -gt 0 ]; then
    pass "5.1 Found ${STREAM_COUNT} log stream(s) configured"
    echo "${LOG_STREAMS}" | jq -r '.[] | "  - \(.name) (type: \(.type), status: \(.status))"' 2>/dev/null || true
  else
    warn "5.1 No log streaming configured -- set up SIEM integration via Reports > Log Streaming"
    warn "5.1 DISA STIG V-273202 (HIGH): Centralized audit logging is required"
  fi

  increment_applied
}

# ===========================================================================
# 5.2 Configure ThreatInsight
# Profile: L1
# ===========================================================================
control_5_2() {
  should_apply 1 || { increment_skipped; return 0; }
  info "5.2 Configuring ThreatInsight..."

  # Check current ThreatInsight settings
  THREAT_CONFIG=$(okta_get "/api/v1/threats/configuration" 2>/dev/null || echo "{}")
  CURRENT_ACTION=$(echo "${THREAT_CONFIG}" | jq -r '.action // "unknown"' 2>/dev/null || echo "unknown")

  info "5.2 Current ThreatInsight action: ${CURRENT_ACTION}"

  if [ "${CURRENT_ACTION}" = "block" ]; then
    pass "5.2 ThreatInsight already set to block"
    increment_applied
    return 0
  fi

  # Enable ThreatInsight with block action
  info "5.2 Setting ThreatInsight to block mode..."
  okta_post "/api/v1/threats/configuration" '{
    "action": "block"
  }' > /dev/null 2>&1 && {
    pass "5.2 ThreatInsight set to block mode"
    increment_applied
    return 0
  } || true

  # Try PUT instead (API may vary by Okta version)
  okta_put "/api/v1/threats/configuration" '{
    "action": "block"
  }' > /dev/null 2>&1 && {
    pass "5.2 ThreatInsight set to block mode"
    increment_applied
  } || {
    warn "5.2 Failed to configure ThreatInsight -- may require Adaptive MFA license"
    warn "5.2 Configure manually: Security > General > ThreatInsight > Block"
    increment_skipped
  }
}

# ===========================================================================
# 5.4 Configure Behavior Detection Rules
# Profile: L2 | NIST: SI-4, AC-7
# ===========================================================================
control_5_4() {
  should_apply 2 || { increment_skipped; return 0; }
  info "5.4 Configuring behavior detection rules..."

  # List all configured behavior detection rules
  info "5.4 Listing current behavior detection rules..."
  BEHAVIORS=$(okta_get "/api/v1/behaviors" 2>/dev/null || echo "[]")
  BEHAVIOR_COUNT=$(echo "${BEHAVIORS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${BEHAVIOR_COUNT}" -eq 0 ]; then
    warn "5.4 No behavior detection rules found -- may require Adaptive MFA license"
    increment_skipped
    return 0
  fi

  info "5.4 Found ${BEHAVIOR_COUNT} behavior detection rule(s):"
  echo "${BEHAVIORS}" | jq -r '.[] | "  - \(.name) (type: \(.type), status: \(.status))"' 2>/dev/null || true

  # Check for inactive rules
  INACTIVE_COUNT=$(echo "${BEHAVIORS}" | jq '[.[] | select(.status == "INACTIVE")] | length' 2>/dev/null || echo "0")
  if [ "${INACTIVE_COUNT}" -gt 0 ]; then
    warn "5.4 ${INACTIVE_COUNT} behavior detection rule(s) are INACTIVE -- consider activating"
  fi

  # Create new country detection rule if not present (idempotent)
  HAS_LOCATION=$(echo "${BEHAVIORS}" | jq '[.[] | select(.type == "ANOMALOUS_LOCATION")] | length' 2>/dev/null || echo "0")

  if [ "${HAS_LOCATION}" -eq 0 ]; then
    info "5.4 Creating new country detection rule..."
    okta_post "/api/v1/behaviors" '{
      "name": "New Country Detection",
      "type": "ANOMALOUS_LOCATION",
      "status": "ACTIVE",
      "settings": {
        "maxEventsUsedForEvaluation": 50
      }
    }' > /dev/null 2>&1 && {
      pass "5.4 New Country Detection behavior rule created"
    } || {
      warn "5.4 Failed to create behavior rule (may already exist with different name)"
    }
  else
    pass "5.4 Anomalous location detection already configured"
  fi

  pass "5.4 Behavior detection audit complete"
  increment_applied
}

# ===========================================================================
# 5.5 Monitor for Cross-Tenant Impersonation
# Profile: L1 | NIST: SI-4, AU-6
# ===========================================================================
control_5_5() {
  should_apply 1 || { increment_skipped; return 0; }
  info "5.5 Auditing identity providers for cross-tenant impersonation risk..."

  # Audit all configured identity providers
  info "5.5 Listing all configured identity providers..."
  IDPS=$(okta_get "/api/v1/idps" 2>/dev/null || echo "[]")
  IDP_COUNT=$(echo "${IDPS}" | jq 'length' 2>/dev/null || echo "0")

  if [ "${IDP_COUNT}" -eq 0 ]; then
    pass "5.5 No external identity providers configured"
    increment_applied
    return 0
  fi

  info "5.5 Found ${IDP_COUNT} identity provider(s):"
  echo "${IDPS}" | jq -r '.[] | "  - \(.name) (type: \(.type), status: \(.status), created: \(.created), protocol: \(.protocol.type))"' 2>/dev/null || true

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

  warn "5.5 IMPORTANT: Configure SIEM alerts for system.idp.lifecycle.* events"
  pass "5.5 Cross-tenant impersonation audit complete"
  increment_applied
}

# ===========================================================================
# Execute all controls
# ===========================================================================
control_5_1
control_5_2
control_5_4
control_5_5

summary
