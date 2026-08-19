#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-3.4
#   guide:   https://howtoharden.com/guides/ona/#34-restrict-environment-creation
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 3.4: Restrict Environment Creation
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 4.1
# Source: https://howtoharden.com/guides/ona/#34-restrict-environment-creation
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# All four booleans sit on the `ona_organization_policies` singleton, so
# Terraform can declare them — for an organization already imported as `current`,
# on Linux amd64/arm64, the only platforms the beta provider publishes. The read
# is what proves them, and the write method returns an EMPTY message so it can
# never prove itself. No CLI verb reads organization policies.
#
# ── TRAP 1: all four are omitted when false, and false is permissive ────────
# `disableFromScratch`, `membersRequireProjects`, `membersCreateProjects` and
# `allowLocalRunners` are all documented `required=true` on the proto message and
# all four were ABSENT from a real organization's policies response. "Required"
# constrains the proto, not the JSON encoding. Absent == false, and for the first
# two, false is the permissive value.
#
# ── TRAP 2: the four booleans do not all point the same way ────────────────
# disableFromScratch=true and membersRequireProjects=true are RESTRICTIONS.
# membersCreateProjects=true and allowLocalRunners=true are PERMISSIONS. A
# reviewer who reads the block as "more true is more hardened" gets two of the
# four backwards. Each is printed with its direction spelled out.
#
# ── TRAP 3: this is a non-admin control ────────────────────────────────────
# Verbatim: "disable_from_scratch controls whether NON-ADMIN users can create
# blank environments without a Git or URL initializer." Organization admins are
# unaffected, so the evidence is about the member population — which is why
# control 1.3's admin count is part of this control's real blast radius.
#
# ── TRAP 4: allowLocalRunners belongs to 5.1 as well ───────────────────────
# The same boolean is the org-wide half of the self-hosted-runner control. It is
# reported here for completeness and scored in pack 5.01, so the two packs cannot
# disagree about which one owns the verdict.
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
# HTH Guide Excerpt: begin environment-creation-audit
audit() {
  get_policies
  echo "Ona 3.4 — environment creation restrictions"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  # TRAP 1: absent == false for every one of these.
  local scratch require_projects create_projects local_runners
  scratch=$(jq -r '.disableFromScratch // false' <<<"${POLICIES}")
  require_projects=$(jq -r '.membersRequireProjects // false' <<<"${POLICIES}")
  create_projects=$(jq -r '.membersCreateProjects // false' <<<"${POLICIES}")
  local_runners=$(jq -r '.allowLocalRunners // false' <<<"${POLICIES}")

  # TRAP 2: direction stated per field so nobody reads the block as a scoreboard.
  echo "  disableFromScratch:     ${scratch}   [restriction — true is hardened]"
  echo "  membersRequireProjects: ${require_projects}   [restriction — true is hardened]"
  echo "  membersCreateProjects:  ${create_projects}   [permission  — false is hardened]"
  echo "  allowLocalRunners:      ${local_runners}   [permission  — false is hardened; scored in pack 5.01]"
  echo "  (every value shown as false was absent from the JSON — absent means false, TRAP 1)"

  if [ "${require_projects}" != "true" ]; then
    echo "NOTE: membersRequireProjects is false — non-admin members can create environments outside"
    echo "  any project, so project-scoped policy and secret scoping do not apply to them."
  fi
  if [ "${create_projects}" = "true" ]; then
    echo "NOTE: membersCreateProjects is true — members can define their own projects, which means"
    echo "  they can also define the repository and configuration those projects carry."
  fi

  if [ "${scratch}" != "true" ]; then
    echo "FINDING: disableFromScratch is false — non-admin members can create blank environments"
    echo "  with no Git or URL initializer."
    echo "  A from-scratch environment has no reviewed repository behind it, so nothing ties the"
    echo "  workload to code anyone approved: it is a general-purpose compute and network foothold"
    echo "  inside the organization's runner. Admins are unaffected by this setting (TRAP 3), so"
    echo "  pair it with the administrator count from control 1.3."
    return 1
  fi
  echo "COMPLIANT: disableFromScratch is true — non-admin members must start from a Git or URL initializer."
  return 0
}
# HTH Guide Excerpt: end environment-creation-audit

audit
