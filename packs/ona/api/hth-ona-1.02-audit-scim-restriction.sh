#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-1.2
#   guide:   https://howtoharden.com/guides/ona/#12-enforce-scim-provisioning-and-restrict-account-creation
#   profile: L1
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 1; sibling common.sh
# =============================================================================
# HTH Ona Control 1.2: Enforce SCIM Provisioning and Restrict Account Creation
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.3, 6.2
# Source: https://howtoharden.com/guides/ona/#12-enforce-scim-provisioning-and-restrict-account-creation
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 1
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

set +x
set -euo pipefail
# Download the complete api directory; common.sh is required.
# Use same-domain tokens. Custom HTTPS bases also require matching
# ONA_REVIEWED_API_BASE. Stdout is staged until completion; keep it private.
# shellcheck source=packs/ona/api/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
ona_init 1
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
  ona_complete
  return "${rc}"
}
# HTH Guide Excerpt: end scim-restriction-audit

SCIM_ENABLED_COUNT=0
audit
