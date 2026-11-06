#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-2.2
#   guide:   https://howtoharden.com/guides/ona/#22-configure-the-agent-command-deny-list
#   profile: L1
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 1; sibling common.sh
# =============================================================================
# HTH Ona Control 2.2: Configure the Agent Command Deny List
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 2.7
# Source: https://howtoharden.com/guides/ona/#22-configure-the-agent-command-deny-list
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 1
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `ona_organization_policies` is a SINGLETON resource resolved from the token's
# own organization (import ID `current`), so Terraform can set the deny list —
# but only for an organization already adopted into state, and only on Linux
# amd64/arm64, the only platforms the beta provider publishes. Reading the live
# value needs GetOrganizationPolicies, whose write counterpart returns an EMPTY
# message and can never self-verify. There is no CLI verb for organization
# policies at all.
#
# ── TRAP 1: an absent commandDenyList is an EMPTY deny list ──────────────────
# Proto3 JSON omits default values, and on a real organization the policies read
# came back with no `agentPolicy.commandDenyList` key at all. A check that keys
# off "is the field present" reports a wide-open organization as configured. The
# only correct read is `(.agentPolicy.commandDenyList // [])` and the only
# correct interpretation of absence is zero entries.
#
# ── TRAP 2: the API contract documents NO wildcard syntax ───────────────────
# `command_deny_list` is typed "array of string" with no pattern constraint and
# no documented matching semantics anywhere in the API reference — wildcard
# behaviour is asserted only in the product documentation. This pack therefore
# reports entries verbatim and never tries to interpret, normalise or expand
# them. Do not build glob logic on top of a contract that does not define it.
#
# ── TRAP 3: the deny list is not the executable policy ──────────────────────
# 2.2 governs what the AGENT is allowed to run as a command; control 2.1's Veto
# executable policy governs what the ENVIRONMENT KERNEL admits. An entry here
# that names a binary protected by Veto's server-populated safelist still does
# nothing at the kernel layer. Read this pack together with 2.1.
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
# HTH Guide Excerpt: begin agent-command-deny-list-audit
# One field, one question — but the field is usually missing rather than empty,
# which is exactly the case a naive check gets wrong (TRAP 1).
audit() {
  get_policies
  echo "Ona 2.2 — agent command deny list"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  local deny count
  deny=$(jq -c '.agentPolicy.commandDenyList // []' <<<"${POLICIES}")
  count=$(jq 'length' <<<"${deny}")
  echo "  agentPolicy.commandDenyList: ${count} entr$( [ "${count}" -eq 1 ] && echo y || echo ies )" \
       "(absent in the JSON means empty, not unset)"

  # TRAP 2: verbatim, uninterpreted.
  if [ "${count}" -gt 0 ]; then
    jq -r '.[] | "    - \(.)"' <<<"${deny}"
  fi

  if [ "${count}" -eq 0 ]; then
    echo "FINDING: the agent command deny list is empty."
    echo "  Nothing stops an agent from invoking credential-reading, network-egress or"
    echo "  history-rewriting commands on its own initiative. Seed the list with the commands"
    echo "  your environments never legitimately need, then re-run this pack to confirm the"
    echo "  read-back — UpdateOrganizationPolicies returns an empty message and proves nothing."
    ona_complete
    return 1
  fi
  echo "COMPLIANT: ${count} command(s) are denied to agents organization-wide."
  echo "           Cross-check against control 2.1 — a command denied here can still be reachable"
  echo "           if the corresponding binary sits on Veto's server-populated safelist (TRAP 3)."
  ona_complete
  return 0
}
# HTH Guide Excerpt: end agent-command-deny-list-audit

audit
