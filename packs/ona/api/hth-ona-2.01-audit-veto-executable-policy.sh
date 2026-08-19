#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-2.1
#   guide:   https://howtoharden.com/guides/ona/#21-enforce-an-executable-policy-with-veto
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 2.1: Enforce an Executable Policy with Veto
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 2.5, 2.7
# Source: https://howtoharden.com/guides/ona/#21-enforce-an-executable-policy-with-veto
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `gitpod-io/ona` ships `ona_security_policy` and a `security_policies` data
# source, so Terraform can author the policy. What it cannot show you is the ONE
# fact that decides this control: which policy id sits in
# `OrganizationPolicies.securityPolicyId`. A policy can be perfectly written,
# applied by Terraform, and still be doing nothing — see TRAP 1. Proving the
# assignment needs GetOrganizationPolicies, and no CLI verb reads organization
# policies either.
#
# ── TRAP 1: a created SecurityPolicy is INERT until it is assigned ───────────
# Verbatim from CreateSecurityPolicy: "Creation stores an INACTIVE definition;
# assigning it as the organization default validates materializability." The
# assignment is a separate write — `UpdateOrganizationPolicies.securityPolicyId`.
# Counting policies is therefore not evidence of anything. This pack fails when
# `securityPolicyId` is empty no matter how many beautiful policies exist.
#
# ── TRAP 2: TWO coexisting Veto surfaces, with DIFFERENT enums ───────────────
# (a) `SecurityService` policy objects: `spec.executables.defaultEffect` +
#     `rules[]{path, effect}` with EFFECT_ALLOW(1)/EFFECT_BLOCK(2)/EFFECT_AUDIT(3).
# (b) the legacy inline `OrganizationPolicies.vetoExecPolicy`:
#     `{enabled, executables[], action}` with KERNEL_CONTROLS_ACTION_BLOCK(1) /
#     _AUDIT(2), where UNSPECIFIED defaults to BLOCK.
# They are not aliases and they are not the same enum. Both are read below so a
# reviewer sees the whole enforcement picture instead of one half of it.
#
# ── TRAP 3: vetoExecPolicy.safelist is OUTPUT-ONLY and server-populated ──────
# Verbatim: "Executable paths that are protected by the safelist and cannot be
# blocked by the denylist. Populated by the server from the built-in default
# safelist. IGNORED ON UPDATE REQUESTS." A deny entry naming a safelisted binary
# silently does nothing. The safelist size is reported so the gap is visible.
#
# ── TRAP 4: defaultEffect EFFECT_ALLOW is CORRECT, not a weakness ────────────
# Verbatim: "For Veto Exec, omit this field or set it to EFFECT_ALLOW.
# EFFECT_UNSPECIFIED is normalized to EFFECT_ALLOW." Veto Exec is a deny-list
# model. Flagging EFFECT_ALLOW as a finding would push operators toward a value
# the GA contract does not accept.
#
# ── TRAP 5: the vendor's own cURL example ships a deprecated enum ────────────
# The CreateSecurityPolicy page's example sets
# `spec.ports.maxAdmissionLevel: ADMISSION_LEVEL_OWNER_ONLY`, and the same page's
# enum table marks OWNER_ONLY "Deprecated. Use ADMISSION_LEVEL_CREATOR_ONLY".
# Copying that example verbatim ships a deprecated value; this pack warns when it
# reads one back.
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
# HTH Guide Excerpt: begin veto-exec-policy-audit
# Control 2.1 is a two-part question: is there a policy worth enforcing, and is
# it actually the organization default (TRAP 1)?
audit() {
  get_policies
  echo "Ona 2.1 — Veto executable policy"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  paginate "SecurityService/ListSecurityPolicies" \
           "$(jq -nc --arg o "${ORG_ID}" '{filter: {organizationId: $o}}')" "securityPolicies"
  local pols="${PAGE_ITEMS}"
  echo "  security policies defined: $(jq 'length' <<<"${pols}")"

  # TRAP 2(a) + TRAP 4: report defaultEffect, do not fail on EFFECT_ALLOW.
  jq -r '.[] |
    ((.spec.executables.rules // [])) as $r |
    "    - name=\(.metadata.name // "(unnamed)") id=…\(((.id // "unknown")[-6:]))" +
    " defaultEffect=\(.spec.executables.defaultEffect // "EFFECT_UNSPECIFIED (normalized to EFFECT_ALLOW)")" +
    " rules=\($r | length)" +
    " block=\([$r[] | select((.effect // "") == "EFFECT_BLOCK")] | length)" +
    " audit=\([$r[] | select((.effect // "") == "EFFECT_AUDIT")] | length)" +
    " ports.maxAdmissionLevel=\(.spec.ports.maxAdmissionLevel // "ADMISSION_LEVEL_UNSPECIFIED (no cap)")"' <<<"${pols}"

  # TRAP 5: warn on the deprecated enum the vendor's own example uses.
  local deprecated
  deprecated=$(jq '[.[] | select((.spec.ports.maxAdmissionLevel // "") == "ADMISSION_LEVEL_OWNER_ONLY")] | length' <<<"${pols}")
  if [ "${deprecated}" -gt 0 ]; then
    echo "  WARNING: ${deprecated} policy/policies use ADMISSION_LEVEL_OWNER_ONLY, which is deprecated."
    echo "           Use ADMISSION_LEVEL_CREATOR_ONLY — the vendor's own cURL example is stale."
  fi

  # TRAP 1: the assignment, not the definition, is the control.
  local assigned assigned_name
  assigned=$(jq -r '.securityPolicyId // ""' <<<"${POLICIES}")
  if [ -n "${assigned}" ]; then
    assigned_name=$(jq -r --arg id "${assigned}" '.[] | select(.id == $id) | .metadata.name // "(unnamed)"' <<<"${pols}")
    [ -n "${assigned_name}" ] || assigned_name="(id not in this organization's policy list)"
    echo "  organization default securityPolicyId: …${assigned: -6} name=${assigned_name}"
  else
    echo "  organization default securityPolicyId: (absent — no policy is assigned)"
  fi

  # TRAP 2(b) + TRAP 3: the legacy inline surface, still live and still settable.
  local veto
  veto=$(jq -c '.vetoExecPolicy // {}' <<<"${POLICIES}")
  echo "  legacy vetoExecPolicy: enabled=$(jq -r '.enabled // false' <<<"${veto}")" \
       "action=$(jq -r '.action // "KERNEL_CONTROLS_ACTION_UNSPECIFIED (defaults to BLOCK)"' <<<"${veto}")" \
       "executables=$(jq '(.executables // []) | length' <<<"${veto}")" \
       "safelist=$(jq '(.safelist // []) | length' <<<"${veto}")"
  echo "    safelist entries are server-populated and CANNOT be blocked by the deny list (TRAP 3)."

  if [ -z "${assigned}" ]; then
    echo "FINDING: no SecurityPolicy is assigned as the organization default."
    echo "  Creation stores an inactive definition; only assignment to"
    echo "  OrganizationPolicies.securityPolicyId materializes it into new environments."
    echo "  Until then every policy listed above enforces nothing."
    return 1
  fi
  echo "COMPLIANT: a SecurityPolicy is assigned as the organization default and will materialize"
  echo "           into newly created environments."
  return 0
}
# HTH Guide Excerpt: end veto-exec-policy-audit

audit
