#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-1.2
#   guide:   https://howtoharden.com/guides/ona/#12-enforce-scim-provisioning-and-restrict-account-creation
#   profile: L1
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 1.2: Enforce SCIM Provisioning and Restrict Account Creation
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.3, 6.2
# Source: https://howtoharden.com/guides/ona/#12-enforce-scim-provisioning-and-restrict-account-creation
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# The `gitpod-io/ona` provider does ship `ona_scim_configuration` and the
# singleton `ona_organization_policies` (import ID `current`), so Terraform can
# SET both halves of this control. It cannot PROVE them. Three reasons this
# evidence pack exists alongside any terraform/ pack:
#   1. `terraform plan` only speaks about an organization already adopted into
#      state. Auditing an org you do not manage with Terraform would mean
#      importing a singleton that governs the whole organization — a change to
#      the management model, not an audit.
#   2. `UpdateOrganizationPolicies` returns an EMPTY message
#      (`UpdateOrganizationPoliciesResponse` has no fields), so no write is ever
#      self-verifying. GetOrganizationPolicies is the only proof that exists.
#   3. The provider is BETA (0.4.0-beta.1) and publishes **Linux amd64/arm64
#      packages only** — no macOS, no Windows. An evidence sweep run from an
#      auditor's laptop cannot use it at all. curl and jq run everywhere.
# The `ona` CLI is not an option either: there is no `ona scim` and no CLI verb
# for organization policies (verified against the published command reference).
#
# ── TRAP 1: absence IS false, and false is the insecure value ────────────────
# Proto3 JSON omits default values. On a real organization the policies read
# came back with `restrictAccountCreationToScim` simply MISSING. A check that
# treats a missing key as an error, or worse as "nothing to see", passes an
# organization where anyone matching the SSO domain can self-provision. Every
# read here uses `// false`.
#
# ── TRAP 2: ListSCIMConfigurations takes NO organizationId ───────────────────
# Unlike ListSSOConfigurations, `ListSCIMConfigurationsRequest` carries only
# `pagination` — scoping is implicit from the token. Sending an organizationId
# would be rejected (the API rejects unknown fields), so this pack does not.
#
# ── TRAP 3: `enabled` cannot be set at creation ──────────────────────────────
# `CreateSCIMConfigurationRequest` has no `enabled` field; only
# UpdateSCIMConfiguration does. A one-call provisioning script therefore leaves
# SCIM created-but-not-enabled, which reads as configured in the console list and
# provisions nothing. That is exactly the state this pack is built to catch, so
# the check asserts `enabled == true`, not "a configuration exists".
#
# ── TRAP 4: the restriction without SCIM is inert ────────────────────────────
# The field's own description: "When true AND SCIM is configured for the
# organization, only users provisioned via SCIM can create accounts." Setting the
# boolean while no SCIM configuration is enabled buys nothing, so both halves are
# asserted and either one missing is a finding.
#
# ── NOTE: tokenExpiresAt is reported, never the token ────────────────────────
# The SCIM bearer token is returned once, at creation/regeneration, and is not on
# any read path. This pack reads `tokenExpiresAt` only.
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
# HTH Guide Excerpt: begin scim-restriction-audit
# Two independent facts make control 1.2: at least one SCIM configuration with
# enabled == true (TRAP 3), and restrictAccountCreationToScim == true (TRAP 1).
# Neither is sufficient alone (TRAP 4).
audit_scim() {
  # TRAP 2: no organizationId on this request — the token scopes it.
  paginate "OrganizationService/ListSCIMConfigurations" '{}' "scimConfigurations"
  local scim="${PAGE_ITEMS}" total enabled
  total=$(jq 'length' <<<"${scim}")
  enabled=$(jq '[.[] | select((.enabled // false) == true)] | length' <<<"${scim}")

  echo "  scim configurations: total=${total} enabled=${enabled}"
  jq -r '.[] |
    "    - enabled=\(.enabled // false)" +
    " ssoConfiguration=\(if (.ssoConfigurationId // "") == "" then "unlinked" else "linked" end)" +
    " tokenExpiresAt=\(.tokenExpiresAt // "(none)")" +
    " allowUnverifiedEmailAccountLinking=\(.allowUnverifiedEmailAccountLinking // false)"' <<<"${scim}"

  local unverified
  unverified=$(jq '[.[] | select((.allowUnverifiedEmailAccountLinking // false) == true)] | length' <<<"${scim}")
  if [ "${unverified}" -gt 0 ]; then
    echo "  NOTE: ${unverified} configuration(s) allow SCIM to link accounts on an UNVERIFIED email."
    echo "        That weakens the identity binding SCIM is supposed to guarantee — review it."
  fi

  SCIM_ENABLED_COUNT="${enabled}"
}

audit() {
  get_policies
  echo "Ona 1.2 — SCIM provisioning and account-creation restriction"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  audit_scim

  # TRAP 1. Absent boolean == false. Never treat a missing key as compliant.
  local restrict
  restrict=$(jq -r '.restrictAccountCreationToScim // false' <<<"${POLICIES}")
  echo "  restrictAccountCreationToScim: ${restrict} (absent in the JSON means false)"

  local rc=0
  if [ "${SCIM_ENABLED_COUNT}" -eq 0 ]; then
    echo "FINDING: no SCIM configuration has enabled == true."
    echo "  Joiner/mover/leaver events are not propagated from the IdP, so deprovisioning is manual."
    rc=1
  fi
  if [ "${restrict}" != "true" ]; then
    echo "FINDING: restrictAccountCreationToScim is false."
    echo "  Anyone who can authenticate through the IdP can self-provision an account that the"
    echo "  IdP never assigned to this organization."
    rc=1
  fi
  if [ "${rc}" -eq 0 ]; then
    echo "COMPLIANT: SCIM is enabled and account creation is restricted to SCIM-provisioned users."
  fi
  return "${rc}"
}
# HTH Guide Excerpt: end scim-restriction-audit

SCIM_ENABLED_COUNT=0
audit
