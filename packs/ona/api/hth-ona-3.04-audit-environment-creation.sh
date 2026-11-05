#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-3.4
#   guide:   https://howtoharden.com/guides/ona/#34-restrict-environment-creation
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 2; sibling common.sh
# =============================================================================
# HTH Ona Control 3.4: Restrict Environment Creation
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 4.1
# Source: https://howtoharden.com/guides/ona/#34-restrict-environment-creation
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 2
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# All four booleans sit on the `ona_organization_policies` singleton, so
# Terraform can declare them — for an organization already imported as `current`,
# on Linux amd64/arm64, the only platforms the beta provider publishes. The read
# is what proves them, and the write method returns an EMPTY message so it can
# never prove itself. No CLI verb reads organization policies.
#
# ── TRAP 1: all four are omitted when false, and false is permissive ────────
# `disableFromScratch`, `membersRequireProjects`, `membersCreateProjects` and
# `allowLocalRunners` are all documented `required=true` on the proto message and
# all four were ABSENT from a real organization's policies response. "Required"
# constrains the proto, not the JSON encoding. Absent == false, and for the first
# two, false is the permissive value.
#
# ── TRAP 2: the four booleans do not all point the same way ────────────────
# disableFromScratch=true and membersRequireProjects=true are RESTRICTIONS.
# membersCreateProjects=true and allowLocalRunners=true are PERMISSIONS. A
# reviewer who reads the block as "more true is more hardened" gets two of the
# four backwards. Each is printed with its direction spelled out.
#
# ── TRAP 3: this is a non-admin control ────────────────────────────────────
# Verbatim: "disable_from_scratch controls whether NON-ADMIN users can create
# blank environments without a Git or URL initializer." Organization admins are
# unaffected, so the evidence is about the member population — which is why
# control 1.3's admin count is part of this control's real blast radius.
#
# ── TRAP 4: allowLocalRunners belongs to 5.1 as well ───────────────────────
# The same boolean is the org-wide half of the self-hosted-runner control. It is
# reported here for completeness and scored in pack 5.01, so the two packs cannot
# disagree about which one owns the verdict.
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
ona_init 2
# HTH Guide Excerpt: begin environment-creation-audit
audit() {
  get_policies
  echo "Ona 3.4 — environment creation restrictions"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  # TRAP 1: absent == false for every one of these.
  local scratch require_projects create_projects local_runners
  scratch=$(jq -r '.disableFromScratch // false' <<<"${POLICIES}")
  require_projects=$(jq -r '.membersRequireProjects // false' <<<"${POLICIES}")
  create_projects=$(jq -r '.membersCreateProjects // false' <<<"${POLICIES}")
  local_runners=$(jq -r '.allowLocalRunners // false' <<<"${POLICIES}")

  # TRAP 2: direction stated per field so nobody reads the block as a scoreboard.
  echo "  disableFromScratch:     ${scratch}   [restriction — true is hardened]"
  echo "  membersRequireProjects: ${require_projects}   [restriction — true is hardened]"
  echo "  membersCreateProjects:  ${create_projects}   [permission  — false is hardened]"
  echo "  allowLocalRunners:      ${local_runners}   [permission  — false is hardened; scored in pack 5.01]"
  echo "  (every value shown as false was absent from the JSON — absent means false, TRAP 1)"

  if [ "${require_projects}" != "true" ]; then
    echo "NOTE: membersRequireProjects is false — non-admin members can create environments outside"
    echo "  any project, so project-scoped policy and secret scoping do not apply to them."
  fi
  if [ "${create_projects}" = "true" ]; then
    echo "NOTE: membersCreateProjects is true — members can define their own projects, which means"
    echo "  they can also define the repository and configuration those projects carry."
  fi

  if [ "${scratch}" != "true" ]; then
    echo "FINDING: disableFromScratch is false — non-admin members can create blank environments"
    echo "  with no Git or URL initializer."
    echo "  A from-scratch environment has no reviewed repository behind it, so nothing ties the"
    echo "  workload to code anyone approved: it is a general-purpose compute and network foothold"
    echo "  inside the organization's runner. Admins are unaffected by this setting (TRAP 3), so"
    echo "  pair it with the administrator count from control 1.3."
    ona_complete
    return 1
  fi
  echo "COMPLIANT: disableFromScratch is true — non-admin members must start from a Git or URL initializer."
  ona_complete
  return 0
}
# HTH Guide Excerpt: end environment-creation-audit

audit
