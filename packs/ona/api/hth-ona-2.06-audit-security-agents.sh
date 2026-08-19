#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-2.6
#   guide:   https://howtoharden.com/guides/ona/#26-deploy-runtime-edr-to-agent-environments
#   profile: L3
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 2.6: Deploy Runtime EDR to Agent Environments
# Profile Level: L3 (Run)
# Frameworks: CIS Controls 10.1, 13.7
# Source: https://howtoharden.com/guides/ona/#26-deploy-runtime-edr-to-agent-environments
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `ona_organization_policies` can declare the security-agent block, but the read
# side is where this control lives: an EDR policy that exists and is not
# `enabled` deploys nothing, and only GetOrganizationPolicies shows the live
# value. See TRAP 1 for the reason that read has to be written defensively.
#
# ── TRAP 1: the READ-BACK TYPE IS UNDOCUMENTED (census D12) ──────────────────
# `OrganizationPolicies.securityAgentPolicy.crowdstrike` is typed
# `CrowdStrikeConfig`, and NO page in the 259-page API reference expands a
# `CrowdStrikeConfig` accordion — the string appears only as an unlinked type
# reference on the two policies pages. The only fully documented shape is the
# WRITE-side `UpdateCrowdStrikeConfig` { enabled, image, cidSecretId, tags,
# additionalOptions }. Every field access below is therefore defensive: presence
# of the `crowdstrike` object is treated as the primary signal, `enabled` is read
# with `// false` and reported as INFERRED, and no other field is depended on.
# If a future doc revision publishes the type, tighten this — do not guess now.
#
# ── TRAP 2: cidSecretId points at a secret; never resolve it ────────────────
# Verbatim: "cid_secret_id references an organization secret containing the
# Customer ID (CID)". This pack reports only whether the reference is set.
# `SecretService/GetSecretValue` returns plaintext and is never called.
#
# ── TRAP 3: customAgents needs read-then-write, so read it before you write ──
# `UpdateSecurityAgentPolicy.customAgents` carries the verbatim warning "Callers
# must read-then-write the full list." A PATCH-shaped update silently deletes
# every custom agent it omits. That is a remediation hazard, and the count this
# pack prints is the input that remediation needs.
#
# ── TRAP 4: absent securityAgentPolicy is NOT an error ──────────────────────
# The field is optional (Required: No) and proto3 omits it entirely when unset.
# Absent means no security agent is deployed to any environment — the finding,
# not a failure to read.
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
# HTH Guide Excerpt: begin security-agent-policy-audit
# TRAP 1 governs the whole function: the read-back type is undocumented, so the
# checks lean on presence and on the one field name the write side shares.
audit() {
  get_policies
  echo "Ona 2.6 — runtime EDR (security agent) policy"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  local sap present cs cs_present enabled custom
  sap=$(jq -c '.securityAgentPolicy // null' <<<"${POLICIES}")
  if [ "${sap}" = "null" ]; then
    present="absent"
    sap='{}'
  else
    present="present"
  fi
  echo "  securityAgentPolicy: ${present} (absent means no security agent deploys to any environment)"

  cs=$(jq -c '.crowdstrike // null' <<<"${sap}")
  if [ "${cs}" = "null" ]; then
    cs_present="absent"
    cs='{}'
  else
    cs_present="present"
  fi
  # TRAP 1: `enabled` is read defensively and labelled INFERRED — the response
  # type is not published, so this is the write-side field name, not a contract.
  enabled=$(jq -r '.enabled // false' <<<"${cs}")
  echo "  securityAgentPolicy.crowdstrike: ${cs_present}; enabled=${enabled} [INFERRED — CrowdStrikeConfig is undocumented on the read path]"
  # TRAP 2: report the reference, never resolve it.
  echo "    cidSecretId: $(jq -r 'if (.cidSecretId // "") == "" then "(unset)" else "(set — an organization secret holds the CID; not resolved here)" end' <<<"${cs}")"
  echo "    image:       $(jq -r 'if (.image // "") == "" then "(default)" else "(pinned)" end' <<<"${cs}")"

  # TRAP 3: the count remediation must preserve.
  custom=$(jq '(.customAgents // []) | length' <<<"${sap}")
  echo "  securityAgentPolicy.customAgents: ${custom}"
  if [ "${custom}" -gt 0 ]; then
    jq -r '(.customAgents // [])[] | "    - name=\(.name // "(unnamed)") enabled=\(.enabled // false)"' <<<"${sap}"
    echo "    Any update MUST resend this whole list — omitting an entry deletes it (TRAP 3)."
  fi

  if [ "${cs_present}" = "present" ] && [ "${enabled}" = "true" ]; then
    echo "COMPLIANT: a CrowdStrike Falcon security agent is configured and reads back enabled."
    return 0
  fi
  if [ "${custom}" -gt 0 ]; then
    local custom_enabled
    custom_enabled=$(jq '[(.customAgents // [])[] | select((.enabled // false) == true)] | length' <<<"${sap}")
    if [ "${custom_enabled}" -gt 0 ]; then
      echo "FINDING: CrowdStrike is not enabled; ${custom_enabled} custom security agent(s) are."
      echo "  A custom agent may well be the right answer — but this control asserts the documented"
      echo "  CrowdStrike path, so record the custom agent as a compensating control explicitly"
      echo "  rather than letting it pass silently."
      return 1
    fi
  fi
  echo "FINDING: no security agent is enabled for this organization."
  echo "  Agent environments run untrusted, model-selected code with no runtime detection."
  echo "  When enabled, security agents are deployed automatically to ALL environments — so this"
  echo "  is one write that covers the whole estate rather than a per-environment rollout."
  return 1
}
# HTH Guide Excerpt: end security-agent-policy-audit

audit
