#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-3.1
#   guide:   https://howtoharden.com/guides/ona/#31-restrict-port-admission-levels
#   profile: L1
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 1; sibling common.sh
# =============================================================================
# HTH Ona Control 3.1: Restrict Port Admission Levels
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 4.1, 12.2
# Source: https://howtoharden.com/guides/ona/#31-restrict-port-admission-levels
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 1
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# Two objects carry a port cap — `ona_organization_policies` and
# `ona_security_policy.spec.ports.max_admission_level` — and Terraform can write
# both. What it cannot do is tell you which one WINS on a live organization,
# because that depends on the third field (`portSharingDisabled`) and on which
# policy is currently assigned as the default. That resolution is a read, and it
# is the whole content of this control.
#
# ── TRAP 1: UNSPECIFIED means NO CAP ────────────────────────────────────────
# `maxPortAdmissionLevel` verbatim: "UNSPECIFIED means no cap (any AdmissionLevel
# value is allowed). System ports (VS Code Browser, agents) are exempt. The
# legacy port_sharing_disabled field, when true, takes precedence and blocks all
# user-initiated port sharing." Proto3 omits the zero enum, so an organization
# with no cap returns NO `maxPortAdmissionLevel` key at all — and that absence is
# the most permissive state, not a neutral one.
#
# ── TRAP 2: portSharingDisabled OVERRIDES the cap ───────────────────────────
# When true it blocks all user-initiated sharing regardless of the enum, so a
# check that reads only the enum reports a finding on an organization that is
# actually hardened harder than the enum can express. Precedence is evaluated
# explicitly below.
#
# ── TRAP 3: ADMISSION_LEVEL_OWNER_ONLY is DEPRECATED ────────────────────────
# Enum: UNSPECIFIED(0) | OWNER_ONLY(1, Deprecated → use CREATOR_ONLY) |
# EVERYONE(2) | ORGANIZATION(3) | CREATOR_ONLY(4). OWNER_ONLY is semantically as
# tight as CREATOR_ONLY, so it PASSES here — with a warning, because the vendor's
# own CreateSecurityPolicy cURL example still ships it and copying that example
# writes a deprecated value into your infrastructure.
#
# ── TRAP 4: the enum is not ordered by strictness ───────────────────────────
# The numbers run UNSPECIFIED(0), OWNER_ONLY(1), EVERYONE(2), ORGANIZATION(3),
# CREATOR_ONLY(4) — the LOOSEST value sits between two of the tightest. Any
# comparison written as "level >= N" is wrong. Membership of an explicit
# acceptable set is the only safe test, which is what this pack does.
#
# Hardened outcome: portSharingDisabled=true, OR the effective cap is
# CREATOR_ONLY (or the deprecated OWNER_ONLY) or ORGANIZATION.
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
# HTH Guide Excerpt: begin port-admission-audit
# TRAP 4: an explicit acceptable set, never a numeric comparison.
level_acceptable() { # level_acceptable <ADMISSION_LEVEL_*>
  case "$1" in
    ADMISSION_LEVEL_CREATOR_ONLY|ADMISSION_LEVEL_ORGANIZATION|ADMISSION_LEVEL_OWNER_ONLY) return 0 ;;
    *) return 1 ;;
  esac
}

audit() {
  get_policies
  echo "Ona 3.1 — port admission level"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  # TRAP 1: absent enum == ADMISSION_LEVEL_UNSPECIFIED == no cap at all.
  local level sharing assigned
  level=$(jq -r '.maxPortAdmissionLevel // "ADMISSION_LEVEL_UNSPECIFIED"' <<<"${POLICIES}")
  sharing=$(jq -r '.portSharingDisabled // false' <<<"${POLICIES}")
  assigned=$(jq -r '.securityPolicyId // ""' <<<"${POLICIES}")
  echo "  maxPortAdmissionLevel: ${level}$( [ "${level}" = "ADMISSION_LEVEL_UNSPECIFIED" ] && echo "  ← absent means NO CAP" )"
  echo "  portSharingDisabled:   ${sharing} (takes precedence over the cap when true)"

  # The assigned SecurityPolicy carries its own cap for environments it governs.
  local policy_level="(no policy assigned)"
  if [ -n "${assigned}" ]; then
    paginate "SecurityService/ListSecurityPolicies" \
             "$(jq -nc --arg o "${ORG_ID}" '{filter: {organizationId: $o}}')" "securityPolicies"
    policy_level=$(jq -r --arg id "${assigned}" '
      [ .[] | select(.id == $id)
            | (.spec.ports.maxAdmissionLevel // "ADMISSION_LEVEL_UNSPECIFIED (no additional cap)") ]
      | if length == 0 then "(assigned policy not visible in this organization)" else .[0] end' <<<"${PAGE_ITEMS}")
  fi
  echo "  assigned SecurityPolicy spec.ports.maxAdmissionLevel: ${policy_level}"

  # TRAP 3: deprecated but still tight — warn, do not fail.
  if [ "${level}" = "ADMISSION_LEVEL_OWNER_ONLY" ] || [ "${policy_level}" = "ADMISSION_LEVEL_OWNER_ONLY" ]; then
    echo "  WARNING: ADMISSION_LEVEL_OWNER_ONLY is deprecated in favour of ADMISSION_LEVEL_CREATOR_ONLY."
    echo "           It is still as tight, so this is not a finding — but migrate it, and note that"
    echo "           the vendor's own CreateSecurityPolicy example is the likely source."
  fi

  # TRAP 2: precedence, evaluated in order.
  if [ "${sharing}" = "true" ]; then
    echo "COMPLIANT: portSharingDisabled=true blocks all user-initiated port sharing,"
    echo "           which takes precedence over maxPortAdmissionLevel entirely."
    ona_complete
    return 0
  fi
  if level_acceptable "${level}"; then
    echo "COMPLIANT: the organization caps user-opened ports at ${level}."
    ona_complete
    return 0
  fi
  echo "FINDING: user-opened ports are not capped to the creator or the organization."
  echo "  Effective org-wide cap: ${level}. A port opened at ADMISSION_LEVEL_EVERYONE is reachable"
  echo "  by anyone on the internet who has the URL, and an agent can open one on its own"
  echo "  initiative. Set portSharingDisabled=true, or maxPortAdmissionLevel to"
  echo "  ADMISSION_LEVEL_CREATOR_ONLY (or ADMISSION_LEVEL_ORGANIZATION if teammates need access)."
  ona_complete
  return 1
}
# HTH Guide Excerpt: end port-admission-audit

audit
