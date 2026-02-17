#!/usr/bin/env bash
# HTH Qualys Control 4.1: Configure Asset Discovery
# Profile: L1 | NIST: CM-8
# https://howtoharden.com/guides/qualys/#41-configure-asset-discovery
source "$(dirname "$0")/common.sh"

banner "4.1: Configure Asset Discovery"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Auditing asset inventory for completeness..."

# HTH Guide Excerpt: begin api-audit-asset-inventory
# Retrieve asset host list and check inventory health
HOSTS_XML=$(ql_get "/asset/host/?action=list&truncation_limit=0" 2>/dev/null) || {
  fail "4.1 Failed to retrieve host list"
  increment_failed
  summary
  exit 1
}

TOTAL_HOSTS=$(echo "${HOSTS_XML}" | xml_count "HOST")
info "4.1 Total hosts in inventory: ${TOTAL_HOSTS}"

# Check for hosts with no last scan date (never scanned)
UNSCANNED=$(echo "${HOSTS_XML}" | grep -c "<LAST_VULN_SCAN_DATETIME/>" || echo "0")
if [ "${UNSCANNED}" -gt 0 ]; then
  warn "4.1 ${UNSCANNED} host(s) have never been vulnerability scanned"
else
  pass "4.1 All hosts have been scanned at least once"
fi
# HTH Guide Excerpt: end api-audit-asset-inventory

# HTH Guide Excerpt: begin api-audit-asset-tags
# Use v3 API to check asset tagging for organization
TAGS_JSON=$(ql_v3_get "/get/am/tag" 2>/dev/null) || {
  warn "4.1 Failed to retrieve asset tags (v3 API)"
  TAGS_JSON=""
}

if [ -n "${TAGS_JSON}" ]; then
  TAG_COUNT=$(echo "${TAGS_JSON}" | grep -oP '"count"\s*:\s*\K[0-9]+' | head -1 || echo "0")
  info "4.1 Asset tags defined: ${TAG_COUNT}"
  if [ "${TAG_COUNT}" -lt 1 ]; then
    warn "4.1 No asset tags defined -- create tags to organize assets by environment/criticality"
  else
    pass "4.1 Asset tagging is configured (${TAG_COUNT} tag(s))"
  fi
fi
# HTH Guide Excerpt: end api-audit-asset-tags

# HTH Guide Excerpt: begin api-check-host-detections
# Check for hosts with active detections to verify scanning coverage
DETECTIONS_XML=$(ql_get "/asset/host/vm/detection/?action=list&truncation_limit=10" 2>/dev/null) || {
  warn "4.1 Failed to retrieve host detections"
  DETECTIONS_XML=""
}

if [ -n "${DETECTIONS_XML}" ]; then
  DETECTION_COUNT=$(echo "${DETECTIONS_XML}" | xml_count "DETECTION")
  info "4.1 Sample detection count: ${DETECTION_COUNT}"
  if [ "${DETECTION_COUNT}" -gt 0 ]; then
    pass "4.1 Vulnerability detections present -- scanning is active"
  else
    warn "4.1 No detections found -- verify scanner appliances are functioning"
  fi
fi
# HTH Guide Excerpt: end api-check-host-detections

if [ "${TOTAL_HOSTS}" -gt 0 ] && [ "${UNSCANNED}" -eq 0 ]; then
  pass "4.1 Asset discovery healthy: ${TOTAL_HOSTS} hosts, all scanned"
  increment_applied
elif [ "${TOTAL_HOSTS}" -gt 0 ]; then
  warn "4.1 Asset discovery partially healthy: ${UNSCANNED}/${TOTAL_HOSTS} hosts unscanned"
  increment_applied
else
  fail "4.1 No hosts in asset inventory -- configure asset discovery"
  increment_failed
fi

summary
