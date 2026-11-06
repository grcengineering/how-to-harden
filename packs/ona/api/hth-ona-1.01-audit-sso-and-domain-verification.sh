#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-1.1
#   guide:   https://howtoharden.com/guides/ona/#11-enforce-sso-with-domain-verification
#   profile: L1
#   mode:    mutating
#   requires: ONA_TOKEN(personal access token; Read-only is enough for the default audit), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 1; sibling common.sh
# =============================================================================
# HTH Ona Control 1.1: Enforce SSO with Domain Verification
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 6.7, 12.5
# Source: https://howtoharden.com/guides/ona/#11-enforce-sso-with-domain-verification
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 1
#
# WHY THIS PACK DECLARES `mode: mutating` DESPITE A READ-ONLY DEFAULT.
# The default invocation (no arguments) is a pure audit: ListSSOConfigurations +
# ListDomainVerifications, both `List*` reads. But while the `gitpod-io/ona`
# provider does ship `ona_sso_configuration`, its v0.5.1 34-resource inventory contains
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
# Current docs name `https://app.ona.com/api`; an August 2026 check observed a
# redirect to app.gitpod.io. That historical observation does not establish
# current routing. Retain the legacy default, choose the reviewed token's origin
# explicitly and never follow a redirect. Custom bases also require the exact
# ONA_REVIEWED_API_BASE; tokens must be minted on that same domain.
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

set +x
set -euo pipefail
# Download the complete api directory; common.sh is required.
# Use same-domain tokens. Custom HTTPS bases also require matching
# ONA_REVIEWED_API_BASE. Stdout is staged until completion; keep it private.
# shellcheck source=packs/ona/api/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
ona_init 1

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
  ona_complete
  return "${rc}"
}
# HTH Guide Excerpt: end sso-domain-audit

# HTH Guide Excerpt: begin sso-domain-verification-write
# The two write branches. CreateDomainVerification returns `verificationToken`,
# which is the value you publish as a public DNS TXT record — printing it is
# intended, it is not a secret (TRAP 4). Neither branch touches SSO client
# credentials. The dedicated write helper uses explicit POST for these branches.
apply_domain() {
  local domain="$1"
  resolve_org
  local body
  ona_write_rpc 'OrganizationService/CreateDomainVerification' \
    "$(jq -nc --arg o "$ORG_ID" --arg d "$domain" '{organizationId:$o,domain:$d}')"
  body="$RPC_BODY"
  jq -e '.domainVerification | type == "object" and (.id | type == "string" and length > 0) and (.state | type == "string" and startswith("DOMAIN_VERIFICATION_STATE_"))' >/dev/null <<< "$body" || ona_fail 'domain creation response incomplete; reconcile before retrying'
  echo "created domain verification for ${domain}"
  echo "  id:    $(jq -r '.domainVerification.id // ""' <<<"${body}" | tail -c 7)"
  echo "  state: $(jq -r '.domainVerification.state // "DOMAIN_VERIFICATION_STATE_UNSPECIFIED"' <<<"${body}")"
  echo "  publish this TXT record on ${domain}, then re-run with --verify-domain <id>:"
  echo "  token: $(jq -r '.domainVerification.verificationToken // "(none returned)"' <<<"${body}")"
  ona_complete
}

verify_domain() {
  local dvid="$1" body
  ona_write_rpc 'OrganizationService/VerifyDomain' "$(jq -nc --arg i "$dvid" '{domainVerificationId:$i}')"
  body="$RPC_BODY"
  jq -e '.domainVerification | type == "object" and (.state | type == "string" and startswith("DOMAIN_VERIFICATION_STATE_"))' >/dev/null <<< "$body" || ona_fail 'domain verification response incomplete; reconcile before retrying'
  echo "domain …${dvid: -6} now reads state=$(jq -r '.domainVerification.state // "DOMAIN_VERIFICATION_STATE_UNSPECIFIED"' <<<"${body}")"
  ona_complete
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
