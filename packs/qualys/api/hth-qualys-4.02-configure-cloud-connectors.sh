#!/usr/bin/env bash
# HTH Qualys Control 4.2: Configure Cloud Connector Security
# Profile: L1 | NIST: CM-8
# https://howtoharden.com/guides/qualys/#42-configure-cloud-connector-security
source "$(dirname "$0")/common.sh"

banner "4.2: Configure Cloud Connector Security"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.2 Auditing cloud connector configurations..."

# HTH Guide Excerpt: begin api-audit-cloud-connectors
# Search for cloud assets via the v3 Asset Management API
# Cloud connectors (AWS, Azure, GCP) sync assets automatically
CLOUD_ASSETS=$(ql_v3_post "/search/am/asset" '{
  "filters": [
    {
      "field": "sourceCategory",
      "operator": "IN",
      "value": "cloud"
    }
  ],
  "preferences": {
    "startFromOffset": 0,
    "limitResults": 10
  }
}' 2>/dev/null) || {
  warn "4.2 Failed to query cloud assets (v3 API)"
  CLOUD_ASSETS=""
}

if [ -n "${CLOUD_ASSETS}" ]; then
  CLOUD_COUNT=$(echo "${CLOUD_ASSETS}" | grep -oP '"count"\s*:\s*\K[0-9]+' | head -1 || echo "0")
  info "4.2 Cloud-sourced assets: ${CLOUD_COUNT}"

  if [ "${CLOUD_COUNT}" -gt 0 ]; then
    pass "4.2 Cloud connectors are active (${CLOUD_COUNT} assets synced)"
  else
    warn "4.2 No cloud assets found -- configure AWS/Azure/GCP connectors"
  fi
fi
# HTH Guide Excerpt: end api-audit-cloud-connectors

# HTH Guide Excerpt: begin api-audit-connector-activity
# Check activity log for recent connector sync events
ACTIVITY_XML=$(ql_get "/activity_log/?action=list&truncation_limit=50" 2>/dev/null) || {
  warn "4.2 Failed to retrieve activity log"
  ACTIVITY_XML=""
}

if [ -n "${ACTIVITY_XML}" ]; then
  # Look for cloud connector-related activity
  CONNECTOR_EVENTS=$(echo "${ACTIVITY_XML}" | grep -ci "connector\|cloud\|aws\|azure\|gcp" || echo "0")
  info "4.2 Cloud connector activity events (last 50): ${CONNECTOR_EVENTS}"

  if [ "${CONNECTOR_EVENTS}" -gt 0 ]; then
    pass "4.2 Recent cloud connector activity detected"
  else
    warn "4.2 No recent cloud connector activity -- verify connectors are scheduled"
  fi
fi
# HTH Guide Excerpt: end api-audit-connector-activity

# HTH Guide Excerpt: begin api-check-unscanned-cloud
# Identify cloud assets that have not been scanned
UNSCANNED_CLOUD=$(ql_v3_post "/search/am/asset" '{
  "filters": [
    {
      "field": "sourceCategory",
      "operator": "IN",
      "value": "cloud"
    },
    {
      "field": "lastVulnScan",
      "operator": "NONE",
      "value": ""
    }
  ],
  "preferences": {
    "startFromOffset": 0,
    "limitResults": 10
  }
}' 2>/dev/null) || {
  UNSCANNED_CLOUD=""
}

if [ -n "${UNSCANNED_CLOUD}" ]; then
  UNSCANNED_COUNT=$(echo "${UNSCANNED_CLOUD}" | grep -oP '"count"\s*:\s*\K[0-9]+' | head -1 || echo "0")
  if [ "${UNSCANNED_COUNT}" -gt 0 ]; then
    warn "4.2 ${UNSCANNED_COUNT} cloud asset(s) have not been vulnerability scanned"
  else
    pass "4.2 All cloud assets have been scanned"
  fi
fi
# HTH Guide Excerpt: end api-check-unscanned-cloud

if [ -n "${CLOUD_ASSETS}" ] && [ "${CLOUD_COUNT:-0}" -gt 0 ]; then
  pass "4.2 Cloud connector security audit complete"
  increment_applied
else
  warn "4.2 Cloud connectors may not be configured -- verify in Qualys console"
  increment_applied
fi

summary
