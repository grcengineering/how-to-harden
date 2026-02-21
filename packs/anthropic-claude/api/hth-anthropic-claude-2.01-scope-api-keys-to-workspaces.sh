#!/usr/bin/env bash
# HTH Anthropic Claude Control 2.1: Scope API Keys to Workspaces
# Profile: L1 | NIST: AC-3, AC-6 | SOC 2: CC6.1, CC6.3
# https://howtoharden.com/guides/anthropic-claude/#21-scope-api-keys-to-workspaces
source "$(dirname "$0")/common.sh"

banner "2.1: Scope API Keys to Workspaces"
require_admin_key

# HTH Guide Excerpt: begin api-audit-keys
# List all API keys across the organization, grouped by workspace
info "Auditing API keys across all workspaces..."
API_KEYS=$(anthropic_list_all "/v1/organizations/api_keys?status=active") || {
  fail "2.1 Failed to list API keys"
  summary; exit 0
}

KEY_COUNT=$(echo "${API_KEYS}" | jq 'length')
info "Found ${KEY_COUNT} active API keys"

# Group by workspace
echo "${API_KEYS}" | jq -r 'group_by(.workspace_id) | .[] |
  "Workspace: \(.[0].workspace_id)\n" +
  ([ .[] | "  Key: \(.name // "unnamed") | Status: \(.status) | Created: \(.created_at)" ] | join("\n"))
'

# Flag unnamed keys
UNNAMED=$(echo "${API_KEYS}" | jq '[.[] | select(.name == null or .name == "")] | length')
if [[ "${UNNAMED}" -gt 0 ]]; then
  warn "2.1 ${UNNAMED} API keys have no name — add descriptive names for auditability"
else
  pass "2.1 All API keys have descriptive names"
fi

# Flag keys in default workspace
DEFAULT_WS_KEYS=$(echo "${API_KEYS}" | jq '[.[] | select(.workspace_id == null)] | length')
if [[ "${DEFAULT_WS_KEYS}" -gt 0 ]]; then
  warn "2.1 ${DEFAULT_WS_KEYS} keys are in the default workspace — consider scoping to dedicated workspaces"
fi
# HTH Guide Excerpt: end api-audit-keys

# HTH Guide Excerpt: begin api-disable-key
# Disable an API key by setting status to inactive
# Usage: Set KEY_ID before running
if [[ -n "${KEY_ID:-}" ]]; then
  info "Disabling API key ${KEY_ID}..."
  anthropic_post "/v1/organizations/api_keys/${KEY_ID}" \
    '{"status": "inactive"}' || {
    fail "2.1 Failed to disable API key"
    summary; exit 0
  }
  pass "2.1 API key ${KEY_ID} disabled"
fi
# HTH Guide Excerpt: end api-disable-key

summary
