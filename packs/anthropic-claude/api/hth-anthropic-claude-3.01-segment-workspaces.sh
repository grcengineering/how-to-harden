#!/usr/bin/env bash
# HTH Anthropic Claude Control 3.1: Segment Workspaces by Environment
# Profile: L1 | NIST: AC-4, SC-7 | SOC 2: CC6.6
# https://howtoharden.com/guides/anthropic-api/#21-segment-workspaces-by-environment
source "$(dirname "$0")/common.sh"

banner "3.1: Segment Workspaces by Environment"
require_admin_key

# HTH Guide Excerpt: begin api-list-workspaces
# List all workspaces and their configuration
info "Listing all workspaces..."
WORKSPACES=$(anthropic_list_all "/v1/organizations/workspaces?include_default=true") || {
  fail "3.1 Failed to list workspaces"
  summary; exit 0
}
WS_COUNT=$(echo "${WORKSPACES}" | jq 'length')
info "Found ${WS_COUNT} workspaces (limit: 100 per organization)"
echo "${WORKSPACES}" | jq -r '.[] |
  "  \(.name) | ID: \(.id) | Geo: \(.data_residency.workspace_geo // "default") | Archived: \(.archived_at // "no")"'
pass "3.1 Workspace inventory complete"
# HTH Guide Excerpt: end api-list-workspaces

# HTH Guide Excerpt: begin api-create-workspace
# Create a new workspace for environment segmentation
# Usage: Set WS_NAME and optionally WS_GEO before running
if [[ -n "${WS_NAME:-}" ]]; then
  [[ "${WS_GEO:-us}" == us ]] || { echo "Only the verified us storage geo is supported by this recipe." >&2; exit 2; }
  BODY=$(jq -cn --arg name "${WS_NAME}" '{name:$name}')
  if [[ -n "${WS_GEO:-}" ]]; then
    BODY=$(echo "${BODY}" | jq --arg geo "${WS_GEO}" '. + {data_residency: {workspace_geo: $geo}}')
  fi
  info "Creating workspace '${WS_NAME}'..."
  RESULT=$(anthropic_post "/v1/organizations/workspaces" "${BODY}") || {
    fail "3.1 Failed to create workspace"
    summary; exit 0
  }
  NEW_ID=$(echo "${RESULT}" | jq -r '.id')
  pass "3.1 Workspace created: ${NEW_ID}"
fi
# HTH Guide Excerpt: end api-create-workspace

summary
