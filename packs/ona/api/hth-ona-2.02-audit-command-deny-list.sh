#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-2.2
#   guide:   https://howtoharden.com/guides/ona/#22-configure-the-agent-command-deny-list
#   profile: L1
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 2.2: Configure the Agent Command Deny List
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 2.7
# Source: https://howtoharden.com/guides/ona/#22-configure-the-agent-command-deny-list
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `ona_organization_policies` is a SINGLETON resource resolved from the token's
# own organization (import ID `current`), so Terraform can set the deny list —
# but only for an organization already adopted into state, and only on Linux
# amd64/arm64, the only platforms the beta provider publishes. Reading the live
# value needs GetOrganizationPolicies, whose write counterpart returns an EMPTY
# message and can never self-verify. There is no CLI verb for organization
# policies at all.
#
# ── TRAP 1: an absent commandDenyList is an EMPTY deny list ──────────────────
# Proto3 JSON omits default values, and on a real organization the policies read
# came back with no `agentPolicy.commandDenyList` key at all. A check that keys
# off "is the field present" reports a wide-open organization as configured. The
# only correct read is `(.agentPolicy.commandDenyList // [])` and the only
# correct interpretation of absence is zero entries.
#
# ── TRAP 2: the API contract documents NO wildcard syntax ───────────────────
# `command_deny_list` is typed "array of string" with no pattern constraint and
# no documented matching semantics anywhere in the API reference — wildcard
# behaviour is asserted only in the product documentation. This pack therefore
# reports entries verbatim and never tries to interpret, normalise or expand
# them. Do not build glob logic on top of a contract that does not define it.
#
# ── TRAP 3: the deny list is not the executable policy ──────────────────────
# 2.2 governs what the AGENT is allowed to run as a command; control 2.1's Veto
# executable policy governs what the ENVIRONMENT KERNEL admits. An entry here
# that names a binary protected by Veto's server-populated safelist still does
# nothing at the kernel layer. Read this pack together with 2.1.
#
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
# HTH Guide Excerpt: begin agent-command-deny-list-audit
# One field, one question — but the field is usually missing rather than empty,
# which is exactly the case a naive check gets wrong (TRAP 1).
audit() {
  get_policies
  echo "Ona 2.2 — agent command deny list"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  local deny count
  deny=$(jq -c '.agentPolicy.commandDenyList // []' <<<"${POLICIES}")
  count=$(jq 'length' <<<"${deny}")
  echo "  agentPolicy.commandDenyList: ${count} entr$( [ "${count}" -eq 1 ] && echo y || echo ies )" \
       "(absent in the JSON means empty, not unset)"

  # TRAP 2: verbatim, uninterpreted.
  if [ "${count}" -gt 0 ]; then
    jq -r '.[] | "    - \(.)"' <<<"${deny}"
  fi

  if [ "${count}" -eq 0 ]; then
    echo "FINDING: the agent command deny list is empty."
    echo "  Nothing stops an agent from invoking credential-reading, network-egress or"
    echo "  history-rewriting commands on its own initiative. Seed the list with the commands"
    echo "  your environments never legitimately need, then re-run this pack to confirm the"
    echo "  read-back — UpdateOrganizationPolicies returns an empty message and proves nothing."
    return 1
  fi
  echo "COMPLIANT: ${count} command(s) are denied to agents organization-wide."
  echo "           Cross-check against control 2.1 — a command denied here can still be reachable"
  echo "           if the corresponding binary sits on Veto's server-populated safelist (TRAP 3)."
  return 0
}
# HTH Guide Excerpt: end agent-command-deny-list-audit

audit
