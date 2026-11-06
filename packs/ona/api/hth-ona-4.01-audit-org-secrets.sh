#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-4.1
#   guide:   https://howtoharden.com/guides/ona/#41-scope-secrets-and-restrict-organization-secrets
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 2; sibling common.sh
# =============================================================================
# HTH Ona Control 4.1: Scope Secrets and Restrict Organization Secrets
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 16.4
# Source: https://howtoharden.com/guides/ona/#41-scope-secrets-and-restrict-organization-secrets
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 2
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

set +x
set -euo pipefail
# Download the complete api directory; common.sh is required.
# Use same-domain tokens. Custom HTTPS bases also require matching
# ONA_REVIEWED_API_BASE. Stdout is staged until completion; keep it private.
# shellcheck source=packs/ona/api/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
ona_init 2
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
    ona_complete
    return 0
  fi
  echo "REVIEW: an organization-scoped secret is mounted into EVERY environment in the organization,"
  echo "  including from-scratch environments and agent sessions. Each one above should be justified"
  echo "  against a narrower scope (project, user or service account) before it stays."
  if [ "${unproxied}" -gt 0 ] && [ "${ONA_STRICT_SECRETS:-0}" = "1" ]; then
    echo "FINDING: ${unproxied} organization-scoped secret(s) have no credentialProxy (ONA_STRICT_SECRETS=1)."
    echo "  Without the proxy the real value is materialised inside the environment and any process"
    echo "  there — an agent included — can read it. With it, only a dummy value is mounted (TRAP 4)."
    ona_complete
    return 1
  fi
  if [ "${unproxied}" -gt 0 ]; then
    echo "NOTE: ${unproxied} of them have no credentialProxy. Set ONA_STRICT_SECRETS=1 to score that"
    echo "  as a finding once your organization has adopted the credential proxy."
  fi
  ona_complete
  return 0
}
# HTH Guide Excerpt: end org-secret-inventory

audit
