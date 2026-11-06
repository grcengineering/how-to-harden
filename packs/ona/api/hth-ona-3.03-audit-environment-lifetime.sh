#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-3.3
#   guide:   https://howtoharden.com/guides/ona/#33-enforce-environment-lifetime-timeout-and-retention
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 2; sibling common.sh
# =============================================================================
# HTH Ona Control 3.3: Enforce Environment Lifetime, Timeout, and Retention
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 4.1
# Source: https://howtoharden.com/guides/ona/#33-enforce-environment-lifetime-timeout-and-retention
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 2
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# All four durations live on `ona_organization_policies`, which Terraform can
# write. It cannot verify: the write method returns an EMPTY message
# (`UpdateOrganizationPoliciesResponse` has no fields), so the only proof any of
# these values landed is GetOrganizationPolicies. And on the read path all four
# vanish at their defaults (TRAP 1), which is precisely the case a `terraform
# plan` diff cannot distinguish from "not managed here".
#
# ── TRAP 1: ZERO MEANS NO LIMIT ON ALL FOUR FIELDS ─────────────────────────
# This is the inversion that makes a well-meaning hardening script WEAKEN an
# organization. Verbatim:
#   maximumEnvironmentTimeout      "0 means no limit (never)"
#   maximumEnvironmentLifetime     "0 means no maximum lifetime"
#   deleteArchivedEnvironmentsAfter "0 means no automatic deletion"
# Proto3 omits zero durations, so every one of these reads back as an ABSENT KEY
# on an unconfigured organization. Absent == 0 == unlimited, never "default" and
# never "fine". `// "0s"` is the only correct read.
#
# ── TRAP 2: the timeout has a floor, and 0s sits BELOW it and still validates ─
# `cel.expression=this == duration('0s') || this >= duration('1800s')`,
# `cel.message=value must be 0s (no limit) or at least 1800s (30 minutes)`.
# So 900s is REJECTED but 0s — the weakest possible value — is ACCEPTED. Anyone
# tightening the number downward hits the floor, gives up, and writes 0s.
#
# ── TRAP 3: archiveEnvironmentsAfter is whole-days-only AND Enterprise-only ──
# `int(this) % int(duration('86400s')) == 0` with min 86400s (1 day) and max
# 2592000s (30 days) — so 604800s works, 100000s is rejected. The field is also
# documented Enterprise only, so on a lower tier its absence is a plan boundary
# rather than a misconfiguration. This pack reports it, and never fails on it.
#
# ── TRAP 4: lifetime without STRICT is advisory ────────────────────────────
# `maximumEnvironmentLifetimeStrict` — "controls whether environments past their
# lockdown_at timestamp are BLOCKED FROM STARTING". Without it the lifetime is a
# label on an environment that still runs. Both are asserted.
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
# HTH Guide Excerpt: begin environment-lifetime-audit
# Duration strings arrive like "172800s". Absent == "0s" == no limit (TRAP 1).
dur_seconds() { # dur_seconds <duration-string-or-empty> -> integer seconds
  local d="${1:-}"
  d="${d%s}"
  case "${d}" in
    ''|*[!0-9.]*) echo 0 ;;
    *) echo "${d%%.*}" ;;
  esac
}

audit() {
  get_policies
  echo "Ona 3.3 — environment lifetime, timeout and retention"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  local lifetime strict timeout archive delete_after
  lifetime=$(jq -r '.maximumEnvironmentLifetime // "0s"' <<<"${POLICIES}")
  strict=$(jq -r '.maximumEnvironmentLifetimeStrict // false' <<<"${POLICIES}")
  timeout=$(jq -r '.maximumEnvironmentTimeout // "0s"' <<<"${POLICIES}")
  archive=$(jq -r '.archiveEnvironmentsAfter // "0s"' <<<"${POLICIES}")
  delete_after=$(jq -r '.deleteArchivedEnvironmentsAfter // "0s"' <<<"${POLICIES}")

  local l_s t_s a_s d_s
  l_s=$(dur_seconds "${lifetime}"); t_s=$(dur_seconds "${timeout}")
  a_s=$(dur_seconds "${archive}");  d_s=$(dur_seconds "${delete_after}")

  echo "  maximumEnvironmentLifetime:       ${lifetime}  ($( [ "${l_s}" -eq 0 ] && echo "0 == NO MAXIMUM LIFETIME" || echo "$((l_s / 86400)) day(s); ceiling is 15552000s / 180d" ))"
  echo "  maximumEnvironmentLifetimeStrict: ${strict}  (false means the lifetime does not block a start)"
  echo "  maximumEnvironmentTimeout:        ${timeout}  ($( [ "${t_s}" -eq 0 ] && echo "0 == NO LIMIT, not 'immediate'" || echo "$((t_s / 60)) minute(s); floor is 1800s / 30m" ))"
  echo "  archiveEnvironmentsAfter:         ${archive}  ($( [ "${a_s}" -eq 0 ] && echo "unset — Enterprise-only field" || echo "$((a_s / 86400)) day(s), whole days only" ))"
  echo "  deleteArchivedEnvironmentsAfter:  ${delete_after}  ($( [ "${d_s}" -eq 0 ] && echo "0 == NO AUTOMATIC DELETION" || echo "$((d_s / 86400)) day(s); ceiling is 2419200s / 4w" ))"
  echo "  (every value above that reads 0s was ABSENT from the JSON — absent means unlimited, TRAP 1)"

  local rc=0
  if [ "${l_s}" -eq 0 ]; then
    echo "FINDING: maximumEnvironmentLifetime is unset — environments can be reused indefinitely."
    echo "  A long-lived environment accumulates cloned repositories, minted tokens and agent"
    echo "  state that no rebuild ever clears."
    rc=1
  fi
  if [ "${strict}" != "true" ]; then
    echo "FINDING: maximumEnvironmentLifetimeStrict is false."
    echo "  Environments past their lockdown_at timestamp are NOT blocked from starting, so the"
    echo "  lifetime above is advisory (TRAP 4)."
    rc=1
  fi
  if [ "${t_s}" -eq 0 ]; then
    echo "FINDING: maximumEnvironmentTimeout is unset (0s == no limit, TRAP 1/2)."
    echo "  Idle environments stay running with their credentials mounted. The minimum accepted"
    echo "  non-zero value is 1800s — anything smaller is rejected, so do not 'tighten' toward 0."
    rc=1
  fi
  if [ "${d_s}" -eq 0 ]; then
    echo "NOTE: deleteArchivedEnvironmentsAfter is 0 — archived environments are never deleted."
    echo "  Not scored here (retention windows are a policy decision), but it means archived"
    echo "  environment data persists indefinitely. Ceiling is 4 weeks if you set it."
  fi
  if [ "${rc}" -eq 0 ]; then
    echo "COMPLIANT: lifetime, strict enforcement and idle timeout are all set."
  fi
  ona_complete
  return "${rc}"
}
# HTH Guide Excerpt: end environment-lifetime-audit

audit
