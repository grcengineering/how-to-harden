#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-2.3
#   guide:   https://howtoharden.com/guides/ona/#23-restrict-mcp-server-access
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 2; sibling common.sh
# =============================================================================
# HTH Ona Control 2.3: Restrict MCP Server Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 2.5
# Source: https://howtoharden.com/guides/ona/#23-restrict-mcp-server-access
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 2
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# The provider ships both `ona_organization_policies` (which carries the MCP
# kill-switch) and `ona_integration`. Neither answers the question this control
# actually asks, which is a JOIN: with MCP left enabled, HOW MANY MCP-category
# integrations are live right now? That needs ListIntegrations filtered on a
# category enum at read time, against an organization nobody has adopted into
# Terraform state. No CLI verb reads organization policies.
#
# ── TRAP 1: mcpDisabled absent == false == MCP IS ENABLED ────────────────────
# Proto3 omits false. On a real organization `agentPolicy.mcpDisabled` was
# missing entirely from the policies read. Absent is the permissive value, and
# `(.agentPolicy.mcpDisabled // false)` is the only correct read.
#
# ── TRAP 2: the toggle is ALL-OR-NOTHING — there is no MCP allow-list ────────
# The API exposes exactly one org-level MCP control: a boolean. There is no
# field, anywhere in the organization policy object, that constrains WHICH MCP
# servers may be used, and nothing in the API reference constrains a repo-local
# `.ona/mcp-config.json`. So "restrict MCP" has only two truthful outcomes:
# disabled outright, or enabled with a compensating review of every integration
# that carries the MCP capability. This pack reports exactly that, which is why
# it prints an inventory instead of pretending a partial state can pass.
#
# ── TRAP 3: two different signals mark an MCP integration ───────────────────
# `Integration.categories[]` may contain INTEGRATION_CATEGORY_MCP (7), and
# `Integration.capabilities.mcp` (type IntegrationMCPCapability) may be present.
# They are separate fields on separate messages and an integration can carry one
# without the other, so both are counted and the union is what matters.
#
# ── TRAP 4: `enabled` is per-integration and also omitted when false ─────────
# Same proto3 rule. An integration object with no `enabled` key is DISABLED, and
# counting it as live would overstate the exposure. `(.enabled // false)`.
#
# Exit codes: 0 compliant | 1 finding (MCP enabled — compensating review) | 2 precondition
# =============================================================================

set +x
set -euo pipefail
# Download the complete api directory; common.sh is required.
# Use same-domain tokens. Custom HTTPS bases also require matching
# ONA_REVIEWED_API_BASE. Stdout is staged until completion; keep it private.
# shellcheck source=packs/ona/api/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
ona_init 2
# HTH Guide Excerpt: begin mcp-policy-audit
# The org kill-switch, then — because it is all-or-nothing (TRAP 2) — the
# inventory that a reviewer needs when the switch is left off.
audit() {
  get_policies
  echo "Ona 2.3 — MCP organization policy"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  # TRAP 1: absent == false == enabled.
  local disabled
  disabled=$(jq -r '.agentPolicy.mcpDisabled // false' <<<"${POLICIES}")
  echo "  agentPolicy.mcpDisabled: ${disabled} (absent in the JSON means false — MCP enabled)"

  paginate "IntegrationService/ListIntegrations" '{}' "integrations"
  local ints="${PAGE_ITEMS}" mcp_total mcp_enabled
  # TRAP 3: union of the category enum and the capability message.
  # TRAP 4: absent enabled == false.
  mcp_total=$(jq '[.[] | select(((.categories // []) | index("INTEGRATION_CATEGORY_MCP")) != null
                                or (.capabilities.mcp != null))] | length' <<<"${ints}")
  mcp_enabled=$(jq '[.[] | select(((.categories // []) | index("INTEGRATION_CATEGORY_MCP")) != null
                                  or (.capabilities.mcp != null))
                         | select((.enabled // false) == true)] | length' <<<"${ints}")
  echo "  integrations: total=$(jq 'length' <<<"${ints}") mcp-capable=${mcp_total} mcp-capable AND enabled=${mcp_enabled}"
  jq -r '.[] | select(((.categories // []) | index("INTEGRATION_CATEGORY_MCP")) != null or (.capabilities.mcp != null))
         | "    - id=…\(((.id // "unknown")[-6:])) enabled=\(.enabled // false)" +
           " host=\(if (.host // "") == "" then "(none)" else .host end)" +
           " viaCategory=\(((.categories // []) | index("INTEGRATION_CATEGORY_MCP")) != null)" +
           " viaCapability=\(.capabilities.mcp != null)"' <<<"${ints}"

  if [ "${disabled}" = "true" ]; then
    echo "COMPLIANT: agentPolicy.mcpDisabled is true — the organization-wide MCP kill-switch is on."
    ona_complete
    return 0
  fi
  echo "FINDING: MCP is enabled organization-wide, with ${mcp_enabled} enabled MCP-capable integration(s)."
  echo "  There is no org-level MCP allow-list (TRAP 2): the only settings that exist are this"
  echo "  boolean and each integration's own enabled flag. Either set mcpDisabled=true, or treat"
  echo "  the ${mcp_enabled} enabled integration(s) above as a standing compensating review —"
  echo "  each one is a tool surface an agent can reach without a human in the loop."
  ona_complete
  return 1
}
# HTH Guide Excerpt: end mcp-policy-audit

audit
