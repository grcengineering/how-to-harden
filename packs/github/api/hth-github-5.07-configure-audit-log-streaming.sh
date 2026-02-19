#!/usr/bin/env bash
# HTH GitHub Control 5.07: Configure Audit Log Streaming
# Profile: L2 | NIST: AU-2, AU-6
# https://howtoharden.com/guides/github/#71-enable-audit-log-streaming-to-siem
source "$(dirname "$0")/common.sh"

banner "5.07: Configure Audit Log Streaming"
should_apply 2 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin api-configure-streaming
# Enable audit log streaming via API (Enterprise Cloud)
info "5.07 Configuring audit log streaming for ${GITHUB_ORG}..."
STREAM_RESPONSE=$(gh_post "/orgs/${GITHUB_ORG}/audit-log/streams" "{
  \"enabled\": true,
  \"stream_type\": \"Splunk\",
  \"vendor_specific\": {
    \"domain\": \"${SPLUNK_HEC_ENDPOINT:-https://splunk.example.com:8088}\",
    \"token\": \"${SPLUNK_HEC_TOKEN:-YOUR_HEC_TOKEN}\"
  }
}") || {
  fail "5.07 Failed to configure audit log streaming"
  increment_failed
  summary
  exit 0
}
pass "5.07 Audit log streaming configured"
# HTH Guide Excerpt: end api-configure-streaming

increment_applied

summary
