#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-4.2
#   guide:   https://howtoharden.com/guides/ona/#42-use-oidc-workload-identity-for-keyless-cloud-access
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 2; sibling common.sh
# =============================================================================
# HTH Ona Control 4.2: Use OIDC Workload Identity for Keyless Cloud Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 16.9
# Source: https://howtoharden.com/guides/ona/#42-use-oidc-workload-identity-for-keyless-cloud-access
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 2
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

set +x
set -euo pipefail
# Download the complete api directory; common.sh is required.
# Use same-domain tokens. Custom HTTPS bases also require matching
# ONA_REVIEWED_API_BASE. Stdout is staged until completion; keep it private.
# shellcheck source=packs/ona/api/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
ona_init 2
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
    ona_complete
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
    ona_complete
    return 1
  fi
  if [ "${version}" != "v3" ]; then
    echo "FINDING: GetOIDCConfig returned neither a v2 nor a v3 member."
    echo "  Treat the configuration as unproven rather than assuming a safe default."
    ona_complete
    return 1
  fi
  if [ "${count}" -eq 0 ]; then
    echo "FINDING: V3 is selected but extraSubFields is empty (TRAP 3)."
    echo "  The sub claim carries nothing to pin an AWS/GCP condition against, so any environment,"
    echo "  project or runner in the organization satisfies the trust policy equally. Add the keys"
    echo "  your condition needs — project_id, runner_id, environment_id, creator_id and so on."
    ona_complete
    return 1
  fi
  echo "COMPLIANT: V3 OIDC tokens with ${count} extra sub field(s) — cloud trust policies can pin"
  echo "           a specific project, runner or environment rather than the whole organization."
  ona_complete
  return 0
}
# HTH Guide Excerpt: end oidc-config-audit

audit
