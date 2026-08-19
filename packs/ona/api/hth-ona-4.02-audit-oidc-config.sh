#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-4.2
#   guide:   https://howtoharden.com/guides/ona/#42-use-oidc-workload-identity-for-keyless-cloud-access
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 4.2: Use OIDC Workload Identity for Keyless Cloud Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 16.9
# Source: https://howtoharden.com/guides/ona/#42-use-oidc-workload-identity-for-keyless-cloud-access
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `gitpod-io/ona` ships `ona_oidc_config`, so Terraform can select the version
# and the extra sub fields. It cannot tell you whether an organization that is
# NOT managed as code has OIDC configured at all — and "not configured" is the
# single most common state of this control, returned as a 404 that a plan diff
# never surfaces (TRAP 1).
#
# ── TRAP 1: an unconfigured organization returns HTTP 404, not empty ────────
# `GetOIDCConfig` answers 404 `not_found` "OIDC config not found" when nothing is
# configured. That is a FINDING, not a precondition and not a crash: the control
# is "use OIDC", and the honest report for a missing config is "not configured,
# exit 1". A pack that lets a 404 fall through its error handler reports a
# transport failure and hides the real answer.
#
# ── TRAP 2: v2 vs v3 is a `oneof`, so exactly one key is present ────────────
# `OIDCConfig` carries `v2` (OIDCConfigV2 — a message with NO fields) or `v3`
# (OIDCConfigV3 { extraSubFields[] }). Because V2 has no fields, its JSON is the
# empty object `{}` — which a truthiness test reads as absent. Presence of the
# KEY is the only reliable discriminator.
#
# ── TRAP 3: extraSubFields is what makes a cloud trust policy tight ─────────
# v3 is "the default for new organizations", but v3 with an EMPTY extraSubFields
# is barely better than v2: the `sub` claim carries nothing to pin a condition
# against, so the AWS/GCP trust policy can only say "this organization" — and any
# environment, any project and any runner in it satisfies that. Valid keys
# include account_id, user_id, organization_id, project_id, runner_id,
# environment_id, creator_id, creator_email, creator_idp, plus dot-notation keys
# such as `creator_idp_claims.groups`. Max 50, unique, min_len 1.
#
# ── TRAP 4: GetIDToken is NOT called ───────────────────────────────────────
# `IdentityService/GetIDToken` would mint a real OIDC JWT for an audience of your
# choosing. It is a credential-minting method and an evidence pack has no
# business calling it — reading the CONFIG proves the claim shape without
# creating a token that could be replayed.
#
# Exit codes: 0 compliant (v3 with >=1 extraSubFields) | 1 finding | 2 precondition
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
# HTH Guide Excerpt: begin oidc-config-audit
audit() {
  resolve_org
  echo "Ona 4.2 — OIDC workload identity configuration"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  # TRAP 1: 404 is the answer, not an error — handle it before the strict classifier.
  api "OrganizationService/GetOIDCConfig" "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')"
  if [ "${RPC_CODE}" = "404" ]; then
    echo "  oidcConfig: NOT CONFIGURED (HTTP 404 $(rpc_err) — $(rpc_msg))"
    echo "FINDING: this organization has no OIDC configuration."
    echo "  Every cloud credential an environment uses must therefore be a long-lived static key"
    echo "  stored as a secret — the thing OIDC workload identity exists to remove."
    return 1
  fi
  if [ "${RPC_CODE}" != "200" ]; then
    api_strict "OrganizationService/GetOIDCConfig" "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')"
  fi

  local cfg version fields count
  cfg=$(printf '%s' "${RPC_BODY}" | jq -c '.oidcConfig // {}')
  # TRAP 2: V2 is an EMPTY message, so test for the KEY, never for truthiness.
  if jq -e 'has("v3")' >/dev/null <<<"${cfg}"; then
    version="v3"
  elif jq -e 'has("v2")' >/dev/null <<<"${cfg}"; then
    version="v2"
  else
    version="(neither v2 nor v3 present)"
  fi
  fields=$(jq -c '.v3.extraSubFields // []' <<<"${cfg}")
  count=$(jq 'length' <<<"${fields}")
  echo "  oidcConfig version: ${version}"
  echo "  v3.extraSubFields:  ${count}"
  if [ "${count}" -gt 0 ]; then
    jq -r '.[] | "    - \(.)"' <<<"${fields}"
  fi

  if [ "${version}" = "v2" ]; then
    echo "FINDING: this organization issues V2 OIDC tokens."
    echo "  V2 has no sub-claim customisation at all (OIDCConfigV2 is an empty message), so a cloud"
    echo "  trust policy cannot scope beyond the organization. V3 is the default for new"
    echo "  organizations — migrate, then add extraSubFields."
    return 1
  fi
  if [ "${version}" != "v3" ]; then
    echo "FINDING: GetOIDCConfig returned neither a v2 nor a v3 member."
    echo "  Treat the configuration as unproven rather than assuming a safe default."
    return 1
  fi
  if [ "${count}" -eq 0 ]; then
    echo "FINDING: V3 is selected but extraSubFields is empty (TRAP 3)."
    echo "  The sub claim carries nothing to pin an AWS/GCP condition against, so any environment,"
    echo "  project or runner in the organization satisfies the trust policy equally. Add the keys"
    echo "  your condition needs — project_id, runner_id, environment_id, creator_id and so on."
    return 1
  fi
  echo "COMPLIANT: V3 OIDC tokens with ${count} extra sub field(s) — cloud trust policies can pin"
  echo "           a specific project, runner or environment rather than the whole organization."
  return 0
}
# HTH Guide Excerpt: end oidc-config-audit

audit
