#!/usr/bin/env bash
# HTH Anthropic Claude Control 2.2: Rotate API Keys Regularly
# Profile: L2 | NIST: IA-5(1) | SOC 2: CC6.1
# https://howtoharden.com/guides/anthropic-claude/#22-rotate-api-keys-regularly
source "$(dirname "$0")/common.sh"

banner "2.2: Rotate API Keys Regularly"
require_admin_key

# HTH Guide Excerpt: begin api-find-stale-keys
# Identify API keys that have not been rotated within 90 days
info "Checking for stale API keys (>90 days since creation)..."
API_KEYS=$(anthropic_list_all "/v1/organizations/api_keys?status=active") || {
  fail "2.2 Failed to list API keys"
  summary; exit 0
}

CUTOFF=$(date -d '90 days ago' '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || \
         date -v-90d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null)

STALE_KEYS=$(echo "${API_KEYS}" | jq --arg cutoff "${CUTOFF}" \
  '[.[] | select(.created_at < $cutoff)]')
STALE_COUNT=$(echo "${STALE_KEYS}" | jq 'length')

if [[ "${STALE_COUNT}" -gt 0 ]]; then
  warn "2.2 ${STALE_COUNT} API keys are older than 90 days:"
  echo "${STALE_KEYS}" | jq -r '.[] | "  \(.name // "unnamed") | Created: \(.created_at) | Workspace: \(.workspace_id)"'
else
  pass "2.2 All API keys are within 90-day rotation window"
fi
# HTH Guide Excerpt: end api-find-stale-keys

# HTH Guide Excerpt: begin api-archive-old-key
# Archive an old API key after rotation
# Usage: Set OLD_KEY_ID before running
if [[ -n "${OLD_KEY_ID:-}" ]]; then
  info "Archiving old API key ${OLD_KEY_ID}..."
  anthropic_post "/v1/organizations/api_keys/${OLD_KEY_ID}" \
    '{"status": "archived"}' || {
    fail "2.2 Failed to archive API key"
    summary; exit 0
  }
  pass "2.2 API key ${OLD_KEY_ID} archived"
fi
# HTH Guide Excerpt: end api-archive-old-key

summary
