#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-2.6
#   guide:   https://howtoharden.com/guides/ona/#26-deploy-runtime-edr-to-agent-environments
#   profile: L3
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 3; sibling common.sh
# =============================================================================
# HTH Ona Control 2.6: Deploy Runtime EDR to Agent Environments
# Profile Level: L3 (Run)
# Frameworks: CIS Controls 10.1, 13.7
# Source: https://howtoharden.com/guides/ona/#26-deploy-runtime-edr-to-agent-environments
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 3
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `ona_organization_policies` can declare the security-agent block, but the read
# side is where this control lives: an EDR policy that exists and is not
# `enabled` deploys nothing, and only GetOrganizationPolicies shows the live
# value. See TRAP 1 for the reason that read has to be written defensively.
#
# ── TRAP 1: the READ-BACK TYPE IS UNDOCUMENTED (census D12) ──────────────────
# `OrganizationPolicies.securityAgentPolicy.crowdstrike` is typed
# `CrowdStrikeConfig`, and NO page in the 259-page API reference expands a
# `CrowdStrikeConfig` accordion — the string appears only as an unlinked type
# reference on the two policies pages. The only fully documented shape is the
# WRITE-side `UpdateCrowdStrikeConfig` { enabled, image, cidSecretId, tags,
# additionalOptions }. Every field access below is therefore defensive: presence
# of the `crowdstrike` object is treated as the primary signal, `enabled` is read
# with `// false` and reported as INFERRED, and no other field is depended on.
# If a future doc revision publishes the type, tighten this — do not guess now.
#
# ── TRAP 2: cidSecretId points at a secret; never resolve it ────────────────
# Verbatim: "cid_secret_id references an organization secret containing the
# Customer ID (CID)". This pack reports only whether the reference is set.
# `SecretService/GetSecretValue` returns plaintext and is never called.
#
# ── TRAP 3: customAgents needs read-then-write, so read it before you write ──
# `UpdateSecurityAgentPolicy.customAgents` carries the verbatim warning "Callers
# must read-then-write the full list." A PATCH-shaped update silently deletes
# every custom agent it omits. That is a remediation hazard, and the count this
# pack prints is the input that remediation needs.
#
# ── TRAP 4: absent securityAgentPolicy is NOT an error ──────────────────────
# The field is optional (Required: No) and proto3 omits it entirely when unset.
# Absent means no security agent is deployed to any environment — the finding,
# not a failure to read.
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
ona_init 3
# HTH Guide Excerpt: begin security-agent-policy-audit
# TRAP 1 governs the whole function: the read-back type is undocumented, so the
# checks lean on presence and on the one field name the write side shares.
audit() {
  get_policies
  echo "Ona 2.6 — runtime EDR (security agent) policy"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  local sap present cs cs_present enabled custom
  sap=$(jq -c '.securityAgentPolicy // null' <<<"${POLICIES}")
  if [ "${sap}" = "null" ]; then
    present="absent"
    sap='{}'
  else
    present="present"
  fi
  echo "  securityAgentPolicy: ${present} (absent means no security agent deploys to any environment)"

  cs=$(jq -c '.crowdstrike // null' <<<"${sap}")
  if [ "${cs}" = "null" ]; then
    cs_present="absent"
    cs='{}'
  else
    cs_present="present"
  fi
  # TRAP 1: `enabled` is read defensively and labelled INFERRED — the response
  # type is not published, so this is the write-side field name, not a contract.
  enabled=$(jq -r '.enabled // false' <<<"${cs}")
  echo "  securityAgentPolicy.crowdstrike: ${cs_present}; enabled=${enabled} [INFERRED — CrowdStrikeConfig is undocumented on the read path]"
  # TRAP 2: report the reference, never resolve it.
  echo "    cidSecretId: $(jq -r 'if (.cidSecretId // "") == "" then "(unset)" else "(set — an organization secret holds the CID; not resolved here)" end' <<<"${cs}")"
  echo "    image:       $(jq -r 'if (.image // "") == "" then "(default)" else "(pinned)" end' <<<"${cs}")"

  # TRAP 3: the count remediation must preserve.
  custom=$(jq '(.customAgents // []) | length' <<<"${sap}")
  echo "  securityAgentPolicy.customAgents: ${custom}"
  if [ "${custom}" -gt 0 ]; then
    jq -r '(.customAgents // [])[] | "    - name=\(.name // "(unnamed)") enabled=\(.enabled // false)"' <<<"${sap}"
    echo "    Any update MUST resend this whole list — omitting an entry deletes it (TRAP 3)."
  fi

  if [ "${cs_present}" = "present" ] && [ "${enabled}" = "true" ]; then
    echo "COMPLIANT: a CrowdStrike Falcon security agent is configured and reads back enabled."
    ona_complete
    return 0
  fi
  if [ "${custom}" -gt 0 ]; then
    local custom_enabled
    custom_enabled=$(jq '[(.customAgents // [])[] | select((.enabled // false) == true)] | length' <<<"${sap}")
    if [ "${custom_enabled}" -gt 0 ]; then
      echo "FINDING: CrowdStrike is not enabled; ${custom_enabled} custom security agent(s) are."
      echo "  A custom agent may well be the right answer — but this control asserts the documented"
      echo "  CrowdStrike path, so record the custom agent as a compensating control explicitly"
      echo "  rather than letting it pass silently."
      ona_complete
      return 1
    fi
  fi
  echo "FINDING: no security agent is enabled for this organization."
  echo "  Agent environments run untrusted, model-selected code with no runtime detection."
  echo "  When enabled, security agents are deployed automatically to ALL environments — so this"
  echo "  is one write that covers the whole estate rather than a per-environment rollout."
  ona_complete
  return 1
}
# HTH Guide Excerpt: end security-agent-policy-audit

audit
