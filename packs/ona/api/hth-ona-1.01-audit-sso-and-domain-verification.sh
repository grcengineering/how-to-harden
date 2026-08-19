#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-1.1
#   guide:   https://howtoharden.com/guides/ona/#11-enforce-sso-with-domain-verification
#   profile: L1
#   mode:    mutating
#   requires: ONA_TOKEN(personal access token; Read-only is enough for the default audit), ONA_ORGANIZATION_ID(optional)
# =============================================================================
# HTH Ona Control 1.1: Enforce SSO with Domain Verification
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 6.7, 12.5
# Source: https://howtoharden.com/guides/ona/#11-enforce-sso-with-domain-verification
# Dependencies: curl, jq
#
# WHY THIS PACK DECLARES `mode: mutating` DESPITE A READ-ONLY DEFAULT.
# The default invocation (no arguments) is a pure audit: ListSSOConfigurations +
# ListDomainVerifications, both `List*` reads. But while the `gitpod-io/ona`
# provider does ship `ona_sso_configuration`, its 32-resource inventory contains
# NO domain-verification resource (`ona_custom_domain` is the management-plane
# hostname, a different object), and there is no `ona sso` CLI verb — domain
# verification is API or console only. So the two write branches
# (`--apply-domain`, `--verify-domain`) have to live somewhere, and the honest
# place is beside the audit that motivates them. Those
# branches use an explicit `-X POST`, so `scripts/validate-packs.sh` check 14
# sees a mutation verb; declaring `read-only` here would be a lie about a file
# that really can change organization state. Run with no arguments for evidence
# collection; the writes never fire unless you name them.
#
# ── TRAP 1: the API base that answers is app.gitpod.io, not app.ona.com ──────
# The docs say `https://app.ona.com/api`. That host returns 308 to
# app.gitpod.io, and `curl -L` DROPS the Authorization header across the
# cross-host hop — the redirect-following request comes back 401 with a valid
# token. Default to app.gitpod.io and override ONA_API_BASE only for a custom
# management-plane domain (tokens must be minted on that same domain).
#
# ── TRAP 2: PROVIDER_TYPE_BUILTIN is not your SSO ────────────────────────────
# `SSOConfiguration.providerType` is one of PROVIDER_TYPE_UNSPECIFIED,
# PROVIDER_TYPE_BUILTIN, PROVIDER_TYPE_CUSTOM. The built-in social/OIDC login an
# organization gets for free is a BUILTIN entry and it will happily read as
# ACTIVE. "SSO is on" is only true when a NON-BUILTIN configuration is in
# SSO_CONFIGURATION_STATE_ACTIVE, which is what this pack counts.
#
# ── TRAP 3: SSO without a VERIFIED domain does not close the side door ───────
# Domain verification is what binds an email domain to the organization so that
# accounts in that domain must come through the IdP. An ACTIVE SSO config plus
# zero VERIFIED domains still leaves the non-SSO signup path open, so both halves
# are asserted here and either one missing is a finding.
#
# ── TRAP 4: verificationToken is a DNS value, not a credential ───────────────
# `--apply-domain` prints `verificationToken` on purpose: it must be published
# as a public TXT record for the domain, so it is not secret. `clientId` and
# `clientSecret` ARE sensitive and are never printed — `clientSecret` is not even
# returned by the read path, and `clientId` is suppressed here deliberately.
# `AccountService/GetSSOLoginURL` is a credential-adjacent Get and is not called.
#
# ── TRAP 5: proto3 JSON omits default values ────────────────────────────────
# Absent boolean == false, absent list == empty, absent enum == *_UNSPECIFIED.
# Every read below treats absence as the insecure/default value, never as an
# error and never as "compliant".
#
# Exit codes: 0 compliant (or write applied) | 1 finding | 2 precondition
# =============================================================================

set -euo pipefail

: "${ONA_TOKEN:?set ONA_TOKEN — an Ona personal access token (Read-only is enough for the default audit) or service account token}"

# TRAP 1. Documented base is https://app.ona.com/api; it 308s to app.gitpod.io
# and curl -L drops the Authorization header on that hop. Override for a custom
# management-plane domain.
ONA_API_BASE="${ONA_API_BASE:-https://app.gitpod.io/api}"

command -v curl >/dev/null 2>&1 || { echo "PRECONDITION: curl not found" >&2; exit 2; }
command -v jq   >/dev/null 2>&1 || { echo "PRECONDITION: jq not found" >&2; exit 2; }

RPC_BODY=""; RPC_CODE=""; ORG_ID=""; ORG_TIER=""; PAGE_ITEMS="[]"
BODY_FILE="$(mktemp "${TMPDIR:-/tmp}/hth-ona-101.XXXXXX")"
trap 'rm -f "${BODY_FILE}"' EXIT

# Connect-RPC unary read. No -X flag: curl already implies POST when a body is
# supplied, so the audit path carries no mutation verb.
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

# Follows pagination.nextToken to exhaustion; pageSize is capped at 100 by the API.
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

resolve_org() {
  if [ -n "${ONA_ORGANIZATION_ID:-}" ]; then ORG_ID="${ONA_ORGANIZATION_ID}"; ORG_TIER="(not read)"; return 0; fi
  api_strict "IdentityService/GetAuthenticatedIdentity" '{}'
  ORG_ID=$(printf '%s' "${RPC_BODY}" | jq -r '.organizationId // ""')
  ORG_TIER=$(printf '%s' "${RPC_BODY}" | jq -r '.organizationTier // "(unset)"')
  [ -n "${ORG_ID}" ] || { echo "PRECONDITION: GetAuthenticatedIdentity returned no organizationId" >&2; exit 2; }
}

# HTH Guide Excerpt: begin sso-domain-audit
# The evidence pass. Both halves of 1.1 are asserted: an ACTIVE non-BUILTIN SSO
# configuration (TRAP 2) AND at least one VERIFIED domain (TRAP 3).
audit() {
  resolve_org
  echo "Ona 1.1 — SSO enforcement and domain verification"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  paginate "OrganizationService/ListSSOConfigurations" \
           "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')" "ssoConfigurations"
  local sso="${PAGE_ITEMS}"

  paginate "OrganizationService/ListDomainVerifications" \
           "$(jq -nc --arg o "${ORG_ID}" '{organizationId: $o}')" "domainVerifications"
  local doms="${PAGE_ITEMS}"

  # TRAP 4. clientId/clientSecret are deliberately absent from this projection.
  echo "  sso configurations: $(jq 'length' <<<"${sso}")"
  jq -r '.[] |
    "    - providerType=\(.providerType // "PROVIDER_TYPE_UNSPECIFIED")" +
    " state=\(.state // "SSO_CONFIGURATION_STATE_UNSPECIFIED")" +
    " emailDomains=\((.emailDomains // []) | length)" +
    " claimsExpression=\(if (.claimsExpression // "") == "" then "unset" else "set" end)"' <<<"${sso}"

  # TRAP 2. Only a non-BUILTIN ACTIVE configuration counts as enforced SSO.
  local active_custom
  active_custom=$(jq '[.[] | select((.state // "") == "SSO_CONFIGURATION_STATE_ACTIVE")
                            | select((.providerType // "PROVIDER_TYPE_UNSPECIFIED") != "PROVIDER_TYPE_BUILTIN")] | length' <<<"${sso}")
  echo "  active non-BUILTIN sso configurations: ${active_custom}"

  local verified pending
  verified=$(jq '[.[] | select((.state // "") == "DOMAIN_VERIFICATION_STATE_VERIFIED")] | length' <<<"${doms}")
  pending=$(jq  '[.[] | select((.state // "") == "DOMAIN_VERIFICATION_STATE_PENDING")]  | length' <<<"${doms}")
  echo "  domain verifications: total=$(jq 'length' <<<"${doms}") verified=${verified} pending=${pending}"

  local rc=0
  if [ "${active_custom}" -eq 0 ]; then
    echo "FINDING: no non-BUILTIN SSO configuration is SSO_CONFIGURATION_STATE_ACTIVE."
    echo "  Members can still authenticate outside the IdP, so no IdP policy (MFA, device, session) applies."
    rc=1
  fi
  if [ "${verified}" -eq 0 ]; then
    echo "FINDING: no domain is DOMAIN_VERIFICATION_STATE_VERIFIED."
    echo "  Without a verified domain the organization cannot bind its email domain to the IdP,"
    echo "  so the non-SSO signup path stays open even when SSO is active. TRAP 3."
    rc=1
  fi
  if [ "${rc}" -eq 0 ]; then
    echo "COMPLIANT: SSO is active on a non-BUILTIN provider and at least one domain is verified."
  fi
  return "${rc}"
}
# HTH Guide Excerpt: end sso-domain-audit

# HTH Guide Excerpt: begin sso-domain-verification-write
# The two write branches. CreateDomainVerification returns `verificationToken`,
# which is the value you publish as a public DNS TXT record — printing it is
# intended, it is not a secret (TRAP 4). Neither branch touches SSO client
# credentials. Explicit -X POST marks the mutation for anyone reading the pack.
apply_domain() {
  local domain="$1"
  resolve_org
  local body code
  code=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' -X POST \
    "${ONA_API_BASE}/gitpod.v1.OrganizationService/CreateDomainVerification" \
    -H "Authorization: Bearer ${ONA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg o "${ORG_ID}" --arg d "${domain}" '{organizationId: $o, domain: $d}')")
  body=$(cat "${BODY_FILE}")
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: CreateDomainVerification returned HTTP ${code} — $(jq -r '.message // "no message"' <<<"${body}")" >&2
    exit 2
  fi
  echo "created domain verification for ${domain}"
  echo "  id:    $(jq -r '.domainVerification.id // ""' <<<"${body}" | tail -c 7)"
  echo "  state: $(jq -r '.domainVerification.state // "DOMAIN_VERIFICATION_STATE_UNSPECIFIED"' <<<"${body}")"
  echo "  publish this TXT record on ${domain}, then re-run with --verify-domain <id>:"
  echo "  token: $(jq -r '.domainVerification.verificationToken // "(none returned)"' <<<"${body}")"
}

verify_domain() {
  local dvid="$1" body code
  code=$(curl -sS -o "${BODY_FILE}" -w '%{http_code}' -X POST \
    "${ONA_API_BASE}/gitpod.v1.OrganizationService/VerifyDomain" \
    -H "Authorization: Bearer ${ONA_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg i "${dvid}" '{domainVerificationId: $i}')")
  body=$(cat "${BODY_FILE}")
  if [ "${code}" != "200" ]; then
    echo "PRECONDITION: VerifyDomain returned HTTP ${code} — $(jq -r '.message // "no message"' <<<"${body}")" >&2
    echo "  A PENDING state usually means the TXT record has not propagated yet." >&2
    exit 2
  fi
  echo "domain …${dvid: -6} now reads state=$(jq -r '.domainVerification.state // "DOMAIN_VERIFICATION_STATE_UNSPECIFIED"' <<<"${body}")"
}
# HTH Guide Excerpt: end sso-domain-verification-write

case "${1:-}" in
  ""|audit)        audit ;;
  --apply-domain)  apply_domain "${2:?domain required, e.g. --apply-domain example.com}" ;;
  --verify-domain) verify_domain "${2:?domainVerificationId required — take it from --apply-domain output}" ;;
  *)
    cat >&2 <<'USAGE'
usage:
  hth-ona-1.01-audit-sso-and-domain-verification.sh                       # read-only audit (default)
  hth-ona-1.01-audit-sso-and-domain-verification.sh --apply-domain DOMAIN # create a domain verification, print the TXT token
  hth-ona-1.01-audit-sso-and-domain-verification.sh --verify-domain ID    # verify once the TXT record is live
USAGE
    exit 2 ;;
esac
