#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: anthropic-claude-2.2
#   guide:   https://howtoharden.com/guides/anthropic-claude/#22-integration-risk-assessment
#   profile: L2
#   mode:    read-only
#   requires: ANTHROPIC_ADMIN_KEY(Console Admin API key; Console admin keys have no selectable scopes)
# =============================================================================
# HTH Anthropic Claude Control 2.2: Integration Risk Assessment — API key scope inventory
# (section 6.02 continues the pre-split numbering; it renders at hub control 2.2)
# Profile: L2 | NIST: RA-3, SA-9 | SOC 2: CC3.2, CC9.2
# Sources: platform.claude.com/docs/en/api/admin/api_keys/list
#          platform.claude.com/docs/en/api/admin/workspaces/list
#          platform.claude.com/docs/en/manage-claude/workspaces
#
# The risk SCORE stays a human judgement (data sensitivity, application trust,
# key storage). This pack supplies the one factor the Admin API can prove: the
# matrix's Key Scope — where each active key can act.
#
# TRAP: the top-level `workspace_id` on an API key is deprecated and is null for
# TWO different things: a key in the Default Workspace, and a principal-bound
# key with no workspace at all. The `scope` object tells them apart
# ({"type":"workspace","workspace_id":...} vs {"type":"organization"}), so this
# pack reads `scope` and uses the null top-level field only to name the Default
# Workspace, which List Workspaces omits. A Default Workspace key is flagged
# because "You cannot set limits on the Default Workspace" (workspaces doc).
# Exit codes: 0 inventory built | 1 missing key or failed API call
source "$(dirname "$0")/common.sh"

banner "2.2: Integration Risk Assessment (API key scope inventory)"
require_admin_key

# HTH Guide Excerpt: begin api-integration-key-inventory
# Inventory every ACTIVE API key by where it can act (the matrix's Key Scope).
info "Listing active API keys and workspaces..."
KEYS=$(anthropic_list_all "/v1/organizations/api_keys?status=active") || {
  fail "2.2 Failed to list API keys"
  summary; exit 1
}
WORKSPACES=$(anthropic_list_all "/v1/organizations/workspaces") || {
  fail "2.2 Failed to list workspaces"
  summary; exit 1
}

# Label each key: a named workspace, the Default Workspace, or ORGANIZATION
# (principal-bound, no workspace). Only scope.type decides the tier.
INVENTORY=$(echo "${KEYS}" | jq -c --argjson ws "${WORKSPACES}" '
  ($ws | map({key: .id, value: .name}) | from_entries) as $names
  | map(
      (.scope.workspace_id // "") as $wid
      | (if .scope.type == "organization" then "organization"
       elif .scope.type == "workspace" and ($names | has($wid)) then "workspace"
       elif .scope.type == "workspace" and .workspace_id == null then "default"
       elif .scope.type == "workspace" then "workspace"
       else "unknown" end) as $tier
      | {
          name: (.name // "unnamed"),
          principal: (.principal.type // "unbound"),
          expires: (.expires_at // "never"),
          tier: $tier,
          where: (if $tier == "organization" then "ORGANIZATION (no workspace)"
                  elif $tier == "default" then "Default Workspace"
                  elif $tier == "workspace" then ($names[$wid] // $wid)
                  else "UNKNOWN (no scope field)" end)
        })')

TOTAL=$(echo "${INVENTORY}" | jq 'length')
ORG_SCOPED=$(echo "${INVENTORY}" | jq '[.[] | select(.tier == "organization")] | length')
DEFAULT_WS=$(echo "${INVENTORY}" | jq '[.[] | select(.tier == "default")] | length')
UNKNOWN=$(echo "${INVENTORY}" | jq '[.[] | select(.tier == "unknown")] | length')
NEVER_EXPIRE=$(echo "${INVENTORY}" | jq '[.[] | select(.expires == "never")] | length')
info "Active keys: ${TOTAL} (organization-scoped=${ORG_SCOPED}, default-workspace=${DEFAULT_WS}, never-expiring=${NEVER_EXPIRE})"

{
  printf 'WHERE\tKEY NAME\tPRINCIPAL\tEXPIRES\n'
  echo "${INVENTORY}" | jq -r 'sort_by(.where) | .[] | "\(.where)\t\(.name)\t\(.principal)\t\(.expires)"'
} | column -t -s $'\t'

# Shared workspaces are the matrix's Medium tier: one workspace, several consumers
echo "${INVENTORY}" | jq -r '[.[] | select(.tier == "workspace" or .tier == "default")]
  | group_by(.where) | map(select(length > 1)) | .[]
  | "  shared: \(.[0].where) holds \(length) active keys"'

if [[ "${ORG_SCOPED}" -gt 0 || "${DEFAULT_WS}" -gt 0 || "${UNKNOWN}" -gt 0 ]]; then
  warn "2.2 ${ORG_SCOPED} organization-scoped, ${DEFAULT_WS} Default Workspace, ${UNKNOWN} unclassified key(s) — give each consumer a dedicated workspace with its own limits"
else
  pass "2.2 Every active key belongs to a named workspace"
fi
# HTH Guide Excerpt: end api-integration-key-inventory

summary
