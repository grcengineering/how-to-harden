#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-2.4
#   guide:   https://howtoharden.com/guides/ona/#24-govern-scm-tools-and-llm-provider-access
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 2.4: Govern SCM Tools and LLM Provider Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 2.5, 3.3
# Source: https://howtoharden.com/guides/ona/#24-govern-scm-tools-and-llm-provider-access
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# The provider ships `ona_organization_policies` and `ona_runner_llm_integration`
# so both halves are declarable. Neither is READABLE without adopting the org and
# every runner into Terraform state, and the LLM half is inherently a per-runner
# fan-out: there is no organization-scoped LLM method at all (see TRAP 4). A
# read-only sweep across every runner is the only way to see the whole model
# surface at once.
#
# ── TRAP 1: SCM tools are a THREE-state control from TWO fields ──────────────
# `agentPolicy.scmToolsDisabled` (boolean) × `agentPolicy.scmToolsAllowedGroupId`
# (string). Verbatim: "scm_tools_allowed_group_id restricts SCM tools access to
# members of this group. EMPTY MEANS NO RESTRICTION (all users can use SCM tools
# if not disabled)." So: disabled=true → off for everyone; disabled=false with a
# group id → that group only; disabled=false with no group id → EVERY member.
# Both fields are omitted from the JSON at their defaults, and their joint
# default is the most permissive of the three states.
#
# ── TRAP 2: allowedCodexModels is DEPRECATED in favour of codexModelPolicy ───
# `agentPolicy.allowedCodexModels` is marked "Deprecated: use codex_model_policy"
# on the policies page. A pack that reads only the legacy array reports "no model
# restrictions" on an organization that has them. Both are read here, and the
# per-model states in `codexModelPolicy.modelStates` are counted.
#
# ── TRAP 3: encryptedApiKey is safe to read; the endpoint is not safe to print ─
# `LLMIntegration.encryptedApiKey` is "the LLM provider's API key encrypted with
# the runner's public key" — the read path never returns plaintext, which is what
# makes List/Get usable as evidence. The `endpoint` URL, by contrast, can carry a
# key in its query string, so this pack prints the HOST only and drops scheme,
# path and query.
#
# ── TRAP 4: there is no org-scoped LLM method ───────────────────────────────
# `RESOURCE_TYPE_ORGANIZATION_LLM_INTEGRATION` (38) exists in the ResourceType
# enum, but every LLM method on RunnerConfigurationService is keyed by runnerId.
# Either that surface is unreleased or it is console-only. The fan-out below is
# not a stylistic choice — it is the only shape the API offers.
#
# ── TRAP 5: llmManagedByOna is deprecated ──────────────────────────────────
# The ListLLMIntegrations response carries `llmManagedByOna` marked "Deprecated:
# Use ona_intelligence_providers together with ...". Both are reported so the
# reading survives the field's removal.
#
# Tunable: ONA_SCM_TOOLS_EXPECT = disabled | group | all   (default: group)
#   disabled — only scmToolsDisabled=true passes
#   group    — disabled OR group-restricted passes (the default posture)
#   all      — accept unrestricted access; the check becomes informational
# Exit codes: 0 compliant | 1 finding | 2 precondition
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
ONA_SCM_TOOLS_EXPECT="${ONA_SCM_TOOLS_EXPECT:-group}"
case "${ONA_SCM_TOOLS_EXPECT}" in
  disabled|group|all) ;;
  *) echo "PRECONDITION: ONA_SCM_TOOLS_EXPECT must be disabled|group|all, got '${ONA_SCM_TOOLS_EXPECT}'" >&2; exit 2 ;;
esac

# HTH Guide Excerpt: begin scm-tools-and-llm-audit
# TRAP 1: collapse the two fields into the three states the product actually has.
scm_tools_state() {
  local disabled group
  disabled=$(jq -r '.agentPolicy.scmToolsDisabled // false' <<<"${POLICIES}")
  group=$(jq -r '.agentPolicy.scmToolsAllowedGroupId // ""' <<<"${POLICIES}")
  if [ "${disabled}" = "true" ]; then
    SCM_STATE="disabled"
  elif [ -n "${group}" ]; then
    SCM_STATE="group"
    SCM_GROUP="${group}"
  else
    SCM_STATE="all"
  fi
}

audit_llm() {
  paginate "RunnerService/ListRunners" '{}' "runners"
  local runners="${PAGE_ITEMS}" ids id
  echo "  runners: $(jq 'length' <<<"${runners}")"
  ids=$(jq -r '.[] | .runnerId // empty' <<<"${runners}")
  if [ -z "${ids}" ]; then
    echo "    (no runners — no LLM integration surface to read)"
    return 0
  fi
  # TRAP 4: fan out per runner; there is no org-scoped LLM read.
  while IFS= read -r id; do
    [ -n "${id}" ] || continue
    api_strict "RunnerConfigurationService/ListLLMIntegrations" \
      "$(jq -nc --arg r "${id}" '{filter: {runnerIds: [$r]}}')"
    local body
    body="${RPC_BODY}"
    echo "    runner …${id: -6}" \
         "llmManagedByOna=$(jq -r '.llmManagedByOna // false' <<<"${body}")" \
         "onaIntelligenceProviders=$(jq -r '((.onaIntelligenceProviders // []) | join(",")) | if . == "" then "(none)" else . end' <<<"${body}")" \
         "integrations=$(jq '(.integrations // []) | length' <<<"${body}")"
    # TRAP 3: host only — the endpoint can carry a key in its query string.
    jq -r '(.integrations // [])[] |
      "      - provider=\(.provider // "LLM_PROVIDER_UNSPECIFIED")" +
      " phase=\(.phase // "LLM_INTEGRATION_PHASE_UNSPECIFIED")" +
      " models=\((.models // []) | length)" +
      " endpointHost=\((.endpoint // "") | sub("^[a-zA-Z]+://";"") | sub("[/?#].*$";"") | if . == "" then "(none)" else . end)" +
      " apiKey=\(if (.encryptedApiKey // "") == "" then "(unset)" else "(encrypted, never returned in plaintext)" end)"' <<<"${body}"
  done <<<"${ids}"
}

audit() {
  get_policies
  echo "Ona 2.4 — SCM tools policy and LLM provider governance"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  scm_tools_state
  case "${SCM_STATE}" in
    disabled) echo "  SCM tools: DISABLED for all members (scmToolsDisabled=true)" ;;
    group)    echo "  SCM tools: restricted to group …${SCM_GROUP: -6} (scmToolsAllowedGroupId set)" ;;
    all)      echo "  SCM tools: available to EVERY member (scmToolsDisabled absent/false AND scmToolsAllowedGroupId empty)" ;;
  esac

  # TRAP 2: read both the current and the deprecated model-allowlist fields.
  echo "  agent/model policy:" \
       "allowedAgentIds=$(jq '(.agentPolicy.allowedAgentIds // []) | length' <<<"${POLICIES}")" \
       "codexModelPolicy.modelStates=$(jq '(.agentPolicy.codexModelPolicy.modelStates // {}) | length' <<<"${POLICIES}")" \
       "allowedCodexModels(deprecated)=$(jq '(.agentPolicy.allowedCodexModels // []) | length' <<<"${POLICIES}")" \
       "allowedCodexReasoningEfforts=$(jq '(.agentPolicy.allowedCodexReasoningEfforts // []) | length' <<<"${POLICIES}")" \
       "allowedCodexServiceTiers=$(jq '(.agentPolicy.allowedCodexServiceTiers // []) | length' <<<"${POLICIES}")" \
       "goalModeDisabled=$(jq -r '.agentPolicy.goalModeDisabled // false' <<<"${POLICIES}")"
  echo "    (every count of 0 means the field was absent — no allow-list, so nothing is constrained)"

  audit_llm

  if [ "${SCM_STATE}" = "all" ] && [ "${ONA_SCM_TOOLS_EXPECT}" != "all" ]; then
    echo "FINDING: SCM tools are unrestricted — every organization member can drive them through an agent."
    echo "  Expected posture ONA_SCM_TOOLS_EXPECT=${ONA_SCM_TOOLS_EXPECT}. Set scmToolsDisabled=true, or"
    echo "  name a group in scmToolsAllowedGroupId; an empty group id means NO restriction (TRAP 1)."
    return 1
  fi
  if [ "${SCM_STATE}" = "group" ] && [ "${ONA_SCM_TOOLS_EXPECT}" = "disabled" ]; then
    echo "FINDING: SCM tools are group-restricted but ONA_SCM_TOOLS_EXPECT=disabled was requested."
    return 1
  fi
  echo "COMPLIANT: SCM tools posture '${SCM_STATE}' satisfies ONA_SCM_TOOLS_EXPECT=${ONA_SCM_TOOLS_EXPECT}."
  return 0
}
# HTH Guide Excerpt: end scm-tools-and-llm-audit

SCM_STATE=""
SCM_GROUP=""
audit
