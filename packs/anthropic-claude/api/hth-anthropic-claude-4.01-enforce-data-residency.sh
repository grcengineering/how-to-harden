#!/usr/bin/env bash
# HTH Anthropic Claude Control 4.1: Enforce Data Residency Restrictions
# Profile: L2 | NIST: SC-7, SA-9(5) | SOC 2: CC6.6, P6.1
# https://howtoharden.com/guides/anthropic-claude/#41-enforce-data-residency-restrictions
source "$(dirname "$0")/common.sh"

banner "4.1: Enforce Data Residency Restrictions"
require_admin_key

# HTH Guide Excerpt: begin api-audit-data-residency
# Audit data residency settings across all workspaces
info "Auditing data residency configuration per workspace..."
WORKSPACES=$(anthropic_list_all "/v1/organizations/workspaces") || {
  fail "4.1 Failed to list workspaces"
  summary; exit 0
}

echo "${WORKSPACES}" | jq -r '.[] | {
  name: .display_name,
  id: .id,
  workspace_geo: (.settings.workspace_geo // "not set"),
  default_inference_geo: (.settings.default_inference_geo // "not set"),
  allowed_inference_geos: (.settings.allowed_inference_geos // ["not restricted"])
} | "  \(.name) | Geo: \(.workspace_geo) | Default Inference: \(.default_inference_geo) | Allowed: \(.allowed_inference_geos | join(", "))"'

# Flag workspaces without data residency configured
UNCONFIGURED=$(echo "${WORKSPACES}" | jq '[.[] | select(
  .settings.workspace_geo == null or .settings.workspace_geo == ""
)] | length')

if [[ "${UNCONFIGURED}" -gt 0 ]]; then
  warn "4.1 ${UNCONFIGURED} workspaces have no explicit data residency setting"
else
  pass "4.1 All workspaces have data residency configured"
fi
# HTH Guide Excerpt: end api-audit-data-residency

# HTH Guide Excerpt: begin api-restrict-inference-geo
# Restrict a workspace to US-only inference
# Usage: Set WORKSPACE_ID before running
if [[ -n "${WORKSPACE_ID:-}" ]]; then
  info "Restricting workspace ${WORKSPACE_ID} to US-only inference..."
  anthropic_post "/v1/organizations/workspaces/${WORKSPACE_ID}" '{
    "settings": {
      "default_inference_geo": "us",
      "allowed_inference_geos": ["us"]
    }
  }' || {
    fail "4.1 Failed to update workspace data residency"
    summary; exit 0
  }
  pass "4.1 Workspace ${WORKSPACE_ID} restricted to US-only inference"
fi
# HTH Guide Excerpt: end api-restrict-inference-geo

summary
