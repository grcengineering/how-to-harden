#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-4.1
#   guide:   https://howtoharden.com/guides/ona/#41-scope-secrets-and-restrict-organization-secrets
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 4.1: Scope Secrets and Restrict Organization Secrets
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 16.4
# Source: https://howtoharden.com/guides/ona/#41-scope-secrets-and-restrict-organization-secrets
# Dependencies: curl, jq
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `gitpod-io/ona` ships an `ona_secret` resource, so Terraform can create a
# correctly-scoped secret. It cannot inventory the ones created in the console,
# by another team, or before the module existed — and those are exactly the
# organization-scoped secrets this control is about. The provider's own guide
# ("state, secrets and safe deletion") is a reminder that putting secret material
# through Terraform state is its own hazard; reading metadata over the API is not.
#
# ── TRAP 1: GetSecretValue RETURNS PLAINTEXT AND IS NEVER CALLED ────────────
# `SecretService/GetSecretValue` classifies as read-only by RPC verb but is a
# credential-disclosure path. `ListSecrets` returns everything this control needs
# — name, scope, mount, credentialProxy — and never returns `value`. The same
# applies to the other Get* methods that mint or disclose credentials:
# IdentityService/GetIDToken, AccountService/GetSSOLoginURL,
# WebhookService/GetWebhookSecret, WorkflowService/GetWorkflowWebhookSecret and
# RunnerConfigurationService/GetHostAuthenticationToken. "Get" is not a safety
# guarantee.
#
# ── TRAP 2: filter.projectIds is DEPRECATED AND SILENTLY IGNORED ────────────
# `ListSecretsRequest.Filter.projectIds` is deprecated and its values are
# explicitly "ignored". A pack that filters by projectIds gets UNFILTERED results
# and reports another scope's secrets as though they were the ones it asked for —
# a silent correctness bug, not an error. Filter on `scope` (and `Secret.projectId`
# is deprecated on the response side too — read `scope` there as well).
#
# ── TRAP 3: the mount is a ONEOF, so exactly one of four keys is present ────
# `filePath` | `environmentVariable` | `containerRegistryBasicAuthHost` |
# `apiOnly`. Proto3 JSON emits only the set member, so mount detection has to
# test for presence rather than read a "mount type" field, which does not exist.
#
# ── TRAP 4: credentialProxy is the strong posture, and it is orthogonal ─────
# Verbatim: "the credential proxy intercepts HTTPS traffic to the target hosts
# and replaces the dummy mounted value with the real value in the specified HTTP
# header. THE REAL SECRET VALUE IS NEVER EXPOSED IN THE ENVIRONMENT. This field
# is orthogonal to mount." An environment-variable-mounted secret is readable by
# any process — including an agent — in that environment; the same secret behind
# the credential proxy is not. That difference is what ONA_STRICT_SECRETS scores.
#
# Tunable: ONA_STRICT_SECRETS=1 — fail when an org-scoped secret has no
#   credentialProxy. Default (unset) reports the inventory and exits 0, because
#   organization secrets are a review item, not automatically a misconfiguration.
# Exit codes: 0 compliant/inventory | 1 finding | 2 precondition
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
# HTH Guide Excerpt: begin org-secret-inventory
# Metadata only. TRAP 1: GetSecretValue is never called from this pack.
audit() {
  resolve_org
  echo "Ona 4.1 — organization-scoped secrets"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  # TRAP 2: filter on scope, never on the deprecated projectIds.
  paginate "SecretService/ListSecrets" \
           "$(jq -nc --arg o "${ORG_ID}" '{filter: {scope: {organizationId: $o}}}')" "secrets"
  local secrets="${PAGE_ITEMS}" total proxied unproxied envvar
  total=$(jq 'length' <<<"${secrets}")
  proxied=$(jq '[.[] | select(.credentialProxy != null)] | length' <<<"${secrets}")
  unproxied=$((total - proxied))
  envvar=$(jq '[.[] | select((.environmentVariable // false) == true)] | length' <<<"${secrets}")

  echo "  organization-scoped secrets: ${total} (credentialProxy set on ${proxied}, absent on ${unproxied})"
  echo "  mounted as an environment variable: ${envvar}"
  # TRAP 3: the mount is a oneof — detect the member that is present.
  jq -r '.[] |
    "    - name=\(.name // "(unnamed)")" +
    " mount=\(if (.filePath // "") != "" then "filePath"
              elif (.environmentVariable // false) == true then "environmentVariable"
              elif (.containerRegistryBasicAuthHost // "") != "" then "containerRegistryBasicAuthHost"
              elif (.apiOnly // false) == true then "apiOnly"
              else "(none set)" end)" +
    " credentialProxy=\(if .credentialProxy == null then "absent" else "present" end)" +
    " source=\(.source // "(unset)")"' <<<"${secrets}"
  echo "  (values are never returned by ListSecrets, and GetSecretValue is not called — TRAP 1)"

  if [ "${total}" -eq 0 ]; then
    echo "COMPLIANT: no organization-scoped secrets exist — nothing is shared across every environment."
    return 0
  fi
  echo "REVIEW: an organization-scoped secret is mounted into EVERY environment in the organization,"
  echo "  including from-scratch environments and agent sessions. Each one above should be justified"
  echo "  against a narrower scope (project, user or service account) before it stays."
  if [ "${unproxied}" -gt 0 ] && [ "${ONA_STRICT_SECRETS:-0}" = "1" ]; then
    echo "FINDING: ${unproxied} organization-scoped secret(s) have no credentialProxy (ONA_STRICT_SECRETS=1)."
    echo "  Without the proxy the real value is materialised inside the environment and any process"
    echo "  there — an agent included — can read it. With it, only a dummy value is mounted (TRAP 4)."
    return 1
  fi
  if [ "${unproxied}" -gt 0 ]; then
    echo "NOTE: ${unproxied} of them have no credentialProxy. Set ONA_STRICT_SECRETS=1 to score that"
    echo "  as a finding once your organization has adopted the credential proxy."
  fi
  return 0
}
# HTH Guide Excerpt: end org-secret-inventory

audit
