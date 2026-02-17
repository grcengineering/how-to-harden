#!/usr/bin/env bash
# HTH AWS IAM Identity Center Control 4.1: Configure CloudTrail Logging
# Profile: L1 | NIST: AU-2 | Frameworks: SOC 2 CC7.2, ISO 27001 A.12.4.1
# https://howtoharden.com/guides/aws-iam-identity-center/#41-configure-cloudtrail-logging
source "$(dirname "$0")/common.sh"

banner "4.1: Configure CloudTrail Logging"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Verifying CloudTrail captures SSO events..."

# HTH Guide Excerpt: begin api-check-cloudtrail
# Verify at least one CloudTrail trail is logging management events
info "4.1 Listing CloudTrail trails..."
TRAILS=$(aws_json cloudtrail describe-trails) || {
  fail "4.1 Failed to describe CloudTrail trails"
  increment_failed
  summary
  exit 0
}

TRAIL_COUNT=$(echo "${TRAILS}" | jq '.trailList | length' 2>/dev/null || echo "0")

if [ "${TRAIL_COUNT}" -eq 0 ]; then
  fail "4.1 No CloudTrail trails found -- SSO events will not be logged (AU-2)"
  increment_failed
  summary
  exit 0
fi

LOGGING_TRAIL_COUNT=0
MGMT_EVENT_TRAIL_COUNT=0

for TRAIL_ARN in $(echo "${TRAILS}" | jq -r '.trailList[].TrailARN' 2>/dev/null); do
  TRAIL_NAME=$(echo "${TRAILS}" | jq -r --arg arn "${TRAIL_ARN}" '.trailList[] | select(.TrailARN == $arn) | .Name')

  # Check if trail is actually logging
  STATUS=$(aws_json cloudtrail get-trail-status --name "${TRAIL_ARN}" 2>/dev/null) || continue
  IS_LOGGING=$(echo "${STATUS}" | jq -r '.IsLogging' 2>/dev/null || echo "false")

  if [ "${IS_LOGGING}" = "true" ]; then
    LOGGING_TRAIL_COUNT=$((LOGGING_TRAIL_COUNT + 1))
  else
    warn "4.1 Trail '${TRAIL_NAME}' exists but is NOT logging"
    continue
  fi

  # Check if trail captures management events (which include SSO events)
  EVENT_SELECTORS=$(aws_json cloudtrail get-event-selectors --trail-name "${TRAIL_ARN}" 2>/dev/null) || continue

  # Check both basic and advanced event selectors
  HAS_MGMT=$(echo "${EVENT_SELECTORS}" | jq '
    (.EventSelectors // [] | any(.IncludeManagementEvents == true)) or
    (.AdvancedEventSelectors // [] | any(.FieldSelectors[] |
      select(.Field == "eventCategory") | .Equals[] == "Management"))
  ' 2>/dev/null || echo "false")

  if [ "${HAS_MGMT}" = "true" ]; then
    pass "4.1 Trail '${TRAIL_NAME}' is logging management events (includes SSO)"
    MGMT_EVENT_TRAIL_COUNT=$((MGMT_EVENT_TRAIL_COUNT + 1))
  else
    warn "4.1 Trail '${TRAIL_NAME}' does not capture management events"
  fi
done
# HTH Guide Excerpt: end api-check-cloudtrail

if [ "${MGMT_EVENT_TRAIL_COUNT}" -eq 0 ]; then
  fail "4.1 No trails are capturing management events -- SSO events are not logged (AU-2)"
  increment_failed
else
  pass "4.1 ${MGMT_EVENT_TRAIL_COUNT} trail(s) capturing SSO management events"
  increment_applied
fi

# HTH Guide Excerpt: begin api-verify-sso-events
# Verify recent SSO events are present in CloudTrail
info "4.1 Checking for recent SSO events in CloudTrail..."
SSO_EVENTS=$(aws_json cloudtrail lookup-events \
  --lookup-attributes "AttributeKey=EventSource,AttributeValue=sso.amazonaws.com" \
  --max-results 5 2>/dev/null) || {
  warn "4.1 Cannot query CloudTrail events -- verify cloudtrail:LookupEvents permission"
  summary
  exit 0
}

EVENT_COUNT=$(echo "${SSO_EVENTS}" | jq '.Events | length' 2>/dev/null || echo "0")

if [ "${EVENT_COUNT}" -gt 0 ]; then
  pass "4.1 Found ${EVENT_COUNT} recent SSO events in CloudTrail"
  echo "${SSO_EVENTS}" | jq -r '.Events[] | "  - \(.EventName) by \(.Username // "unknown") at \(.EventTime)"' 2>/dev/null || true
else
  warn "4.1 No recent SSO events found -- this may indicate a new deployment or logging gap"
fi
# HTH Guide Excerpt: end api-verify-sso-events

summary
