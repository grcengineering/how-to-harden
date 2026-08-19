#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-3.2
#   guide:   https://howtoharden.com/guides/ona/#32-control-the-in-environment-web-browser
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 3.2: Control the In-Environment Web Browser
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 9.2
# Source: https://howtoharden.com/guides/ona/#32-control-the-in-environment-web-browser
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `ona_organization_policies` can set `web_browser_disabled`, but the singleton
# is resolved from the authenticated token's own organization and only exists in
# Terraform once you import it (`current`). Auditing an organization you do not
# manage as code means reading the live value, and
# `UpdateOrganizationPolicies` returns an EMPTY message, so even a Terraform-run
# org needs this read to prove the setting landed. No CLI verb exists.
#
# ── TRAP 1: absent means false means THE BROWSER IS AVAILABLE ───────────────
# Proto3 omits default values. On a real organization `webBrowserDisabled` was
# missing from the policies response entirely. The field is documented
# `required=true` on the message, which tempts a reader into assuming it will
# always be present — it is not, because "required" describes the proto contract,
# not the JSON encoding. `(.webBrowserDisabled // false)` is the only safe read.
#
# ── TRAP 2: this does NOT cover VS Code Browser ────────────────────────────
# Verbatim: "web_browser_disabled controls whether users can open the built-in
# web browser from environment pages. THIS DOES NOT AFFECT VS CODE BROWSER."
# Disabling it closes one browsing surface, not browsing. Anything the control
# claims beyond that is overstated, and the pack says so in its own output so the
# evidence cannot be quoted out of context.
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
# HTH Guide Excerpt: begin web-browser-policy-audit
audit() {
  get_policies
  echo "Ona 3.2 — in-environment web browser"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  # TRAP 1: `required=true` is a proto constraint, not a promise that the JSON
  # will carry the key. Absent == false == the browser is available.
  local disabled
  disabled=$(jq -r '.webBrowserDisabled // false' <<<"${POLICIES}")
  echo "  webBrowserDisabled: ${disabled} (absent in the JSON means false)"

  if [ "${disabled}" = "true" ]; then
    echo "COMPLIANT: the built-in web browser cannot be opened from environment pages."
    echo "  Scope note: this does NOT disable VS Code Browser (TRAP 2) — do not record this"
    echo "  evidence as 'browsing disabled in environments'."
    return 0
  fi
  echo "FINDING: the in-environment web browser is available to every member."
  echo "  It is a full browser inside the environment, so an agent-driven or human session can"
  echo "  reach an internal service, authenticate to it with environment-resident credentials,"
  echo "  and move data out without leaving the environment's network path."
  return 1
}
# HTH Guide Excerpt: end web-browser-policy-audit

audit
