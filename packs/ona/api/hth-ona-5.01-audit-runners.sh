#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-5.1
#   guide:   https://howtoharden.com/guides/ona/#51-run-self-hosted-runners-for-sensitive-source-code
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 2; sibling common.sh
# =============================================================================
# HTH Ona Control 5.1: Run Self-Hosted Runners for Sensitive Source Code
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 12.2
# Source: https://howtoharden.com/guides/ona/#51-run-self-hosted-runners-for-sensitive-source-code
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 2
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `gitpod-io/ona` ships `ona_runner`, `ona_runner_token` and `runner`/`runners`
# data sources, so Terraform is the right way to CREATE a self-hosted runner. It
# is the wrong way to audit one: the provider's own guide warns that the runner
# registration token is single-use, expires in 24 hours, and — though marked
# sensitive — IS STORED IN TERRAFORM STATE. Reading the fleet over the API needs
# no state file and mints no token.
#
# ── TRAP 1: RUNNER_KIND_LOCAL is deprecated, and there are TWO levers ───────
# `RUNNER_KIND_LOCAL` verbatim: "Deprecated: Local runners are no longer
# supported. Use RUNNER_PROVIDER_AWS_EC2 or RUNNER_PROVIDER_GCP instead."
# `RUNNER_KIND_LOCAL_CONFIGURATION` is different: "a system-managed runner that
# holds shared configuration for local runners. Every organization automatically
# has one… DesiredPhase. Can be set to STOPPED to disable all local runners." So
# local runners are governed by the org policy `allowLocalRunners` AND by that
# singleton's desiredPhase. This pack reads both, because either one left open is
# enough to keep local runners alive.
#
# ── TRAP 2: MANAGED and DEV_AGENT are internal-only providers ──────────────
# `RUNNER_PROVIDER_MANAGED` and `RUNNER_PROVIDER_DEV_AGENT` are both marked
# "Internal use only… Do not use when creating your own runners."  MANAGED is the
# Ona-operated fleet — i.e. exactly the NOT-self-hosted case this control exists
# to move away from, so it is counted separately rather than lumped in.
# `RUNNER_PROVIDER_LINUX_HOST` and `_DESKTOP_MAC` are deprecated too.
#
# ── TRAP 3: desiredPhase and status.phase are different facts ──────────────
# `spec.desiredPhase` is what you asked for; `status.phase` is what the runner
# reports. A runner can be desired ACTIVE and report DEGRADED. Both are printed;
# conflating them turns an outage into a compliance pass.
#
# ── TRAP 4: CreateRunner returns bootstrap credentials — never called here ──
# `CreateRunner` returns `accessToken` and `exchangeToken` once. This is a
# read-only pack; the only runner methods it touches are ListRunners and the
# organization policy read.
#
# Tunable: ONA_REQUIRE_SELF_HOSTED=1 — also fail when no AWS_EC2/GCP runner exists.
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
# HTH Guide Excerpt: begin runner-fleet-audit
audit() {
  get_policies
  echo "Ona 5.1 — runner fleet and local-runner policy"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  paginate "RunnerService/ListRunners" '{}' "runners"
  local runners="${PAGE_ITEMS}" total self_hosted managed
  total=$(jq 'length' <<<"${runners}")
  # TRAP 2: self-hosted means AWS_EC2 or GCP; MANAGED is the Ona-operated fleet.
  self_hosted=$(jq '[.[] | select((.provider // "") == "RUNNER_PROVIDER_AWS_EC2" or (.provider // "") == "RUNNER_PROVIDER_GCP")] | length' <<<"${runners}")
  managed=$(jq '[.[] | select((.provider // "") == "RUNNER_PROVIDER_MANAGED")] | length' <<<"${runners}")
  echo "  runners: total=${total} self-hosted(AWS_EC2|GCP)=${self_hosted} Ona-managed=${managed}"

  # TRAP 3: desired vs reported, side by side.
  jq -r '.[] |
    "    - id=…\(((.runnerId // "unknown")[-6:]))" +
    " kind=\(.kind // "RUNNER_KIND_UNSPECIFIED")" +
    " provider=\(.provider // "RUNNER_PROVIDER_UNSPECIFIED")" +
    " desiredPhase=\(.spec.desiredPhase // "RUNNER_PHASE_UNSPECIFIED")" +
    " reportedPhase=\(.status.phase // "RUNNER_PHASE_UNSPECIFIED")"' <<<"${runners}"

  # TRAP 1: the second lever — the system-managed LOCAL_CONFIGURATION singleton.
  local lc_phase
  lc_phase=$(jq -r '[.[] | select((.kind // "") == "RUNNER_KIND_LOCAL_CONFIGURATION")
                         | (.spec.desiredPhase // "RUNNER_PHASE_UNSPECIFIED")]
                    | if length == 0 then "(no LOCAL_CONFIGURATION runner visible)" else .[0] end' <<<"${runners}")
  echo "  RUNNER_KIND_LOCAL_CONFIGURATION desiredPhase: ${lc_phase}"
  echo "    (set that singleton to RUNNER_PHASE_STOPPED to disable all local runners — the second"
  echo "     lever alongside allowLocalRunners)"

  local allow_local
  allow_local=$(jq -r '.allowLocalRunners // false' <<<"${POLICIES}")
  echo "  allowLocalRunners: ${allow_local} (absent in the JSON means false)"

  local rc=0
  if [ "${allow_local}" = "true" ]; then
    echo "FINDING: allowLocalRunners is true."
    echo "  Members can run environments on a machine the organization does not control, which puts"
    echo "  cloned source and mounted secrets on unmanaged hardware. Local runners are deprecated at"
    echo "  the enum level anyway — RUNNER_KIND_LOCAL says 'no longer supported'."
    rc=1
  fi
  if [ "${self_hosted}" -eq 0 ] && [ "${ONA_REQUIRE_SELF_HOSTED:-0}" = "1" ]; then
    echo "FINDING: no self-hosted runner exists (ONA_REQUIRE_SELF_HOSTED=1)."
    echo "  Every environment runs on Ona-operated infrastructure, so sensitive source is cloned"
    echo "  outside your own network boundary. Deploy an AWS_EC2 (CloudFormation) or GCP"
    echo "  (Terraform) runner and bind the sensitive projects to it."
    rc=1
  fi
  if [ "${self_hosted}" -eq 0 ] && [ "${ONA_REQUIRE_SELF_HOSTED:-0}" != "1" ]; then
    echo "NOTE: no self-hosted runner exists. Set ONA_REQUIRE_SELF_HOSTED=1 to score that as a"
    echo "  finding once your organization has decided sensitive source must stay on its own"
    echo "  infrastructure."
  fi
  if [ "${rc}" -eq 0 ]; then
    echo "COMPLIANT: local runners are not allowed and the fleet posture matches the expected profile."
  fi
  ona_complete
  return "${rc}"
}
# HTH Guide Excerpt: end runner-fleet-audit

audit
