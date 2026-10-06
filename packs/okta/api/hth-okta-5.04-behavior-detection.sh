#!/usr/bin/env bash
# HTH Okta Control 5.4: Configure Behavior Detection Rules
# Profile: L2 | NIST: SI-4, AC-7
# https://howtoharden.com/guides/okta/#54-configure-behavior-detection-rules
#
# Behavior shapes: Okta Management API, Behavior (BehaviorRuleAnomalousLocation
# requires settings.granularity). A behavior only defines what "new" means; the
# response is set in policy rules ("Behavior is" / "Risk is").
source "$(dirname "$0")/common.sh"

banner "5.4: Configure Behavior Detection Rules"

should_apply 2 || { increment_skipped; summary; exit 0; }
info "5.4 Configuring behavior detection rules..."

# HTH Guide Excerpt: begin api-list-behaviors
# List all configured behavior detection rules (a failed read stops the pack)
info "5.4 Listing current behavior detection rules..."
BEHAVIORS=$(okta_get "/api/v1/behaviors")
BEHAVIOR_COUNT=$(printf '%s' "${BEHAVIORS}" | jq 'length')
# HTH Guide Excerpt: end api-list-behaviors

info "5.4 Found ${BEHAVIOR_COUNT} behavior detection rule(s):"
printf '%s' "${BEHAVIORS}" | jq -r '.[] | "  - \(.name) (type: \(.type), status: \(.status))"'

# Check for inactive rules
INACTIVE_COUNT=$(printf '%s' "${BEHAVIORS}" | jq '[.[] | select(.status == "INACTIVE")] | length')
if [ "${INACTIVE_COUNT}" -gt 0 ]; then
  warn "5.4 ${INACTIVE_COUNT} behavior detection rule(s) are INACTIVE -- consider activating"
fi

# Create a country-level location rule if no location behavior exists (idempotent)
HAS_LOCATION=$(printf '%s' "${BEHAVIORS}" | jq '[.[] | select(.type == "ANOMALOUS_LOCATION")] | length')

if [ "${HAS_LOCATION}" -eq 0 ]; then
  # HTH Guide Excerpt: begin api-create-behavior-rule
  info "5.4 Creating new country detection rule..."
  if okta_post "/api/v1/behaviors" '{
    "name": "New Country Detection",
    "type": "ANOMALOUS_LOCATION",
    "status": "ACTIVE",
    "settings": {
      "granularity": "COUNTRY",
      "maxEventsUsedForEvaluation": 50
    }
  }' > /dev/null; then
    pass "5.4 New Country Detection behavior rule created"
  else
    fail "5.4 Failed to create the New Country Detection behavior rule"
    increment_failed
    summary
  fi
  # HTH Guide Excerpt: end api-create-behavior-rule
else
  pass "5.4 Anomalous location detection already configured"
fi

pass "5.4 Behavior detection audit complete"
increment_applied

summary
