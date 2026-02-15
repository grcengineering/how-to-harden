#!/usr/bin/env bash
# HTH Okta Control 5.4: Configure Behavior Detection Rules
# Profile: L2 | NIST: SI-4, AC-7
# https://howtoharden.com/guides/okta/#54-configure-behavior-detection-rules
source "$(dirname "$0")/common.sh"

banner "5.4: Configure Behavior Detection Rules"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "5.4 Configuring behavior detection rules..."

# HTH Guide Excerpt: begin api-list-behaviors
# List all configured behavior detection rules
info "5.4 Listing current behavior detection rules..."
BEHAVIORS=$(okta_get "/api/v1/behaviors" 2>/dev/null || echo "[]")
BEHAVIOR_COUNT=$(echo "${BEHAVIORS}" | jq 'length' 2>/dev/null || echo "0")
# HTH Guide Excerpt: end api-list-behaviors

if [ "${BEHAVIOR_COUNT}" -eq 0 ]; then
  warn "5.4 No behavior detection rules found -- may require Adaptive MFA license"
  increment_skipped
  summary
  exit 0
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
  # HTH Guide Excerpt: begin api-create-behavior-rule
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
  # HTH Guide Excerpt: end api-create-behavior-rule
else
  pass "5.4 Anomalous location detection already configured"
fi

pass "5.4 Behavior detection audit complete"
increment_applied

summary
