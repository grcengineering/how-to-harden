#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-2.3
#   guide:   https://howtoharden.com/guides/ona/#23-restrict-mcp-server-access
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 2.3: Restrict MCP Server Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 2.5
# Source: https://howtoharden.com/guides/ona/#23-restrict-mcp-server-access
# Dependencies: curl, jq
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

set -euo pipefail

: "${ONA_TOKEN:?set ONA_TOKEN — an Ona personal access token (Read-only is enough) or service account token}"

# TRAP (base URL). The documented base is https://app.ona.com/api. That host
# answers 308 to app.gitpod.io, and `curl -L` DROPS the Authorization header
# across the cross-host hop, so a valid token comes back 401. Default to the
# host that actually answers; override only for a custom management-plane
# domain (tokens must be minted on that same domain).
ONA_API_BASE="${ONA_API_BASE:-https://app.gitpod.io/api}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

RPC_BODY=""; RPC_CODE=""; ORG_ID=""; ORG_TIER=""; PAGE_ITEMS="[]"
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-ona.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT

# Connect-RPC unary call. Every Ona method is a POST, but no -X flag is written:
# curl already implies POST when a body is supplied, which keeps this pack
# honestly read-only under scripts/validate-packs.sh check 14.
api() {
  set +e
  RPC_CODE=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' \
    "${ONA_API_BASE}/gitpod.v1.$1" \
    -H "Authorization: Bearer ${ONA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2" 2>/dev/null)
  local rc=$?
  set -e
  [ "${rc}" -eq 0 ] || RPC_CODE="000"
  RPC_BODY=$(cat "${BODY_FILE}" 2>/dev/null || echo '{}')
}

rpc_err() { printf '%s' "${RPC_BODY}" | jq -r '.code // "unknown"' 2>/dev/null || echo unknown; }
rpc_msg() { printf '%s' "${RPC_BODY}" | jq -r '.message // "no message"' 2>/dev/null || echo "no message"; }

# Fatal classifier. Connect errors carry {"code": "...", "message": "..."}.
# Plan gating, auth failure and transport failure are all preconditions (exit 2),
# never findings — a control cannot be judged non-compliant on evidence that was
# never returned.
api_strict() {
  api "$1" "$2"
  if [ "${RPC_CODE}" = "200" ]; then return 0; fi
  case "${RPC_CODE}:$(rpc_err)" in
    400:failed_precondition)
      echo "PRECONDITION: $1 — $(rpc_msg)" >&2 ;;
    401:*|403:*)
      echo "PRECONDITION: $1 returned HTTP ${RPC_CODE} ($(rpc_err)) — $(rpc_msg)" >&2
      echo "  The token is invalid, expired, or lacks the permission this method requires." >&2 ;;
    000:*)
      echo "PRECONDITION: $1 — no HTTP response (network, DNS, or TLS failure)." >&2 ;;
    *)
      echo "PRECONDITION: $1 returned HTTP ${RPC_CODE} ($(rpc_err)) — $(rpc_msg)" >&2 ;;
  esac
  exit 2
}

# Follows pagination.nextToken to exhaustion. pageSize is capped at 100 by the
# API (int32.lte=100); the 200-page ceiling is a runaway guard, not a limit.
paginate() { # paginate <Service/Method> <base-json> <response-array-field>
  local method="$1" base="$2" field="$3" token="" req pages=0 tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/hth-ona-page.XXXXXX")"
  while :; do
    req=$(jq -nc --argjson base "${base}" --arg t "${token}" \
      '$base + {pagination: ({pageSize: 100} + (if $t == "" then {} else {token: $t} end))}')
    api_strict "${method}" "${req}"
    printf '%s' "${RPC_BODY}" | jq -c --arg f "${field}" '.[$f][]?' >> "${tmp}"
    token=$(printf '%s' "${RPC_BODY}" | jq -r '.pagination.nextToken // ""')
    pages=$((pages + 1))
    [ -n "${token}" ] && [ "${pages}" -lt 200 ] || break
  done
  PAGE_ITEMS=$(jq -s '.' "${tmp}")
  rm -f "${tmp}"
}

# Organization id: explicit override, else derived from the token's own identity.
resolve_org() {
  if [ -n "${ONA_ORGANIZATION_ID:-}" ]; then ORG_ID="${ONA_ORGANIZATION_ID}"; ORG_TIER="(not read)"; return 0; fi
  api_strict "IdentityService/GetAuthenticatedIdentity" '{}'
  ORG_ID=$(printf '%s' "${RPC_BODY}" | jq -r '.organizationId // ""')
  ORG_TIER=$(printf '%s' "${RPC_BODY}" | jq -r '.organizationTier // "(unset)"')
  [ -n "${ORG_ID}" ] || { echo "PRECONDITION: GetAuthenticatedIdentity returned no organizationId" >&2; exit 2; }
}

# GetOrganizationPolicies is the single read anchor for every org-wide control.
# Proto3 JSON omits defaults, so callers must read every field with a `// false`,
# `// 0`, `// []` or `// "*_UNSPECIFIED"` fallback — absence is the default
# value, not an error and not compliance.
get_policies() {
  resolve_org
  api_strict "OrganizationService/GetOrganizationPolicies" \
    "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')"
  POLICIES=$(printf '%s' "${RPC_BODY}" | jq -c '.policies // {}')
}
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
    return 0
  fi
  echo "FINDING: MCP is enabled organization-wide, with ${mcp_enabled} enabled MCP-capable integration(s)."
  echo "  There is no org-level MCP allow-list (TRAP 2): the only settings that exist are this"
  echo "  boolean and each integration's own enabled flag. Either set mcpDisabled=true, or treat"
  echo "  the ${mcp_enabled} enabled integration(s) above as a standing compensating review —"
  echo "  each one is a tool surface an agent can reach without a human in the loop."
  return 1
}
# HTH Guide Excerpt: end mcp-policy-audit

audit
