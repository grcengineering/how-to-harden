#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: ona-4.3
#   guide:   https://howtoharden.com/guides/ona/#43-scope-repository-access-to-least-privilege
#   profile: L2
#   mode:    read-only
#   requires: ONA_TOKEN(personal access token, Read-only is enough), ONA_ORGANIZATION_ID(optional); HTH_PROFILE_LEVEL >= 2; sibling common.sh
# =============================================================================
# HTH Ona Control 4.3: Scope Repository Access to Least Privilege
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 3.3, 6.8
# Source: https://howtoharden.com/guides/ona/#43-scope-repository-access-to-least-privilege
# Dependencies: Bash, curl, jq; sibling common.sh; HTH_PROFILE_LEVEL >= 2
#
# WHY THIS IS AN api/ PACK — AND WHY terraform/ CANNOT REPLACE IT.
# `ona_scm_integration` declares an integration; it cannot answer the only
# question that matters for least privilege, which is REACH. `CheckRepositoryAccess`
# and `CheckAuthenticationForHost` are live probes with no declarative equivalent,
# and no configuration field anywhere says what a runner can actually see. This
# control is a measurement, not a definition.
#
# ── TRAP 1: `pat: true` is an ALTERNATIVE credential path, not a fallback ───
# `SCMIntegration.pat` allows personal-access-token authentication against the
# host. When the host also supports OAuth, leaving PAT enabled means a member can
# bind a long-lived token whose scope is chosen by that member — outside the OAuth
# app's grant, outside its revocation, and outside any review. That is the finding
# this pack scores. Set ONA_ALLOW_PAT_SCM=1 for hosts where PAT is genuinely the
# only workable path (and record why).
#
# ── TRAP 2: supportsOauth2 / supportsPat are MESSAGES, not booleans ─────────
# In `CheckAuthenticationForHostResponse`, `supportsOauth2` is typed
# `AuthenticationMethodOAuth2` and `supportsPat` is
# `AuthenticationMethodPersonalAccessToken` — sibling `patSupported` IS a plain
# boolean. Reading the two message fields as booleans is wrong in both
# directions: an empty message is truthy-by-presence and absent-when-unsupported.
# Presence is the test, which is what this pack uses.
#
# ── TRAP 3: the OAuth client secret is never returned ──────────────────────
# `SCMIntegration` exposes `oauth` (SCMIntegrationOAuthConfig) but no plaintext
# secret; the write side takes `oauthPlaintextClientSecret` and the read side does
# not echo it. That is what makes List/Get safe evidence collection here.
# `GetHostAuthenticationToken` is a credential-disclosing Get and is NOT called.
#
# ── TRAP 4: CheckRepositoryAccess is a PROBE, and probes cost a round trip ──
# It answers `hasAccess` for one repository against one runner. It is opt-in via
# `--check-repo <url>` rather than part of the default sweep, because the default
# sweep must stay cheap enough to run against every runner in an organization.
#
# ── TRAP 5: CheckAuthenticationForHost NEEDS A LIVE RUNNER ─────────────────
# Probed against a runner whose status.phase is not RUNNER_PHASE_ACTIVE, it
# answers HTTP 400 "runner is not active" — verified live. An organization
# routinely holds a RUNNER_KIND_LOCAL_CONFIGURATION singleton sitting in
# RUNNER_PHASE_CREATED, so a sweep that treats that refusal as fatal never
# reaches the runners that matter. Inactive runners are SKIPPED here, their host
# capabilities marked unknown, and the PAT verdict falls back to the
# integration's own OAuth block (which, when configured, already proves the host
# speaks OAuth). Where even that is absent, the integration is reported UNPROVEN
# and the pack exits 2 rather than claiming it is clean.
#
# Tunable: ONA_ALLOW_PAT_SCM=1 — accept PAT-enabled integrations on OAuth-capable hosts.
# Exit codes: 0 compliant | 1 finding | 2 precondition/unproven
# =============================================================================

set +x
set -euo pipefail
# Download the complete api directory; common.sh is required.
# Use same-domain tokens. Custom HTTPS bases also require matching
# ONA_REVIEWED_API_BASE. Stdout is staged until completion; keep it private.
# shellcheck source=packs/ona/api/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"
ona_init 2
CHECK_REPO=""
case "${1:-}" in
  ""|audit) ;;
  --check-repo) CHECK_REPO="${2:?repository URL required, e.g. --check-repo https://github.com/org/repo}" ;;
  *) echo "usage: $(basename "$0") [--check-repo <repository-url>]" >&2; exit 2 ;;
esac
FINDINGS=0
UNPROVEN=0

# HTH Guide Excerpt: begin runner-repo-access-audit
# For every runner: which SCM integrations it holds, and for each integration's
# host, which authentication methods the host actually offers (TRAP 2).
audit_runner() {
  local rid="$1" phase="$2"
  api_strict "RunnerConfigurationService/ListSCMIntegrations" \
    "$(jq -nc --arg r "${rid}" '{filter: {runnerIds: [$r]}}')"
  local ints
  ints=$(printf '%s' "${RPC_BODY}" | jq -c '.integrations // []')
  echo "    scm integrations: $(jq 'length' <<<"${ints}")"

  local rows host pat oauth scmid
  rows=$(jq -r '.[] | [(.host // ""), ((.pat // false) | tostring), (if .oauth == null then "false" else "true" end), (.scmId // "")] | @tsv' <<<"${ints}")
  [ -n "${rows}" ] || return 0
  while IFS=$'\t' read -r host pat oauth scmid; do
    [ -n "${host}${scmid}" ] || continue
    local host_oauth="unknown" host_pat="unknown" host_patbool="unknown" why=""
    # TRAP 5: the probe needs a LIVE runner. Skip it on anything that is not
    # reporting RUNNER_PHASE_ACTIVE rather than aborting the whole sweep.
    if [ "${phase}" != "RUNNER_PHASE_ACTIVE" ]; then
      why="runner reports ${phase} — CheckAuthenticationForHost needs an active runner"
    else
      api "RunnerService/CheckAuthenticationForHost" \
        "$(jq -nc --arg r "${rid}" --arg h "${host}" '{runnerId: $r, host: $h}')"
      if [ "${RPC_CODE}" = "200" ]; then
        # TRAP 2: presence of the message, not its truthiness.
        host_oauth=$(printf '%s' "${RPC_BODY}" | jq -r 'if has("supportsOauth2") then "true" else "false" end')
        host_pat=$(printf '%s' "${RPC_BODY}"   | jq -r 'if has("supportsPat")    then "true" else "false" end')
        host_patbool=$(printf '%s' "${RPC_BODY}" | jq -r '.patSupported // false')
      else
        why="probe returned HTTP ${RPC_CODE} $(rpc_err) — $(rpc_msg)"
      fi
    fi
    echo "      - host=${host:-(unset)} scmId=${scmid:-(unset)} oauthConfigured=${oauth} patAllowed=${pat}"
    if [ -n "${why}" ]; then
      echo "        host capabilities UNKNOWN: ${why}"
    else
      echo "        host offers: supportsOauth2=${host_oauth} supportsPat=${host_pat} patSupported=${host_patbool}"
    fi
    # TRAP 1: PAT allowed on a host that speaks OAuth is the finding. When the
    # probe could not run, a CONFIGURED oauth block on the integration itself is
    # sufficient proof that the host speaks OAuth — the fallback never invents
    # capability, it only uses what the integration already records.
    if [ "${pat}" = "true" ] && [ "${ONA_ALLOW_PAT_SCM:-0}" != "1" ] \
       && { [ "${host_oauth}" = "true" ] || { [ "${host_oauth}" = "unknown" ] && [ "${oauth}" = "true" ]; }; }; then
      echo "        FINDING: PAT authentication is allowed on a host that supports OAuth2."
      echo "          A member-chosen personal access token carries whatever scope that member gave"
      echo "          it, is not bounded by the OAuth app's grant, and does not die when the OAuth"
      echo "          app is revoked. Disable pat on this integration, or set ONA_ALLOW_PAT_SCM=1"
      echo "          and record why this host needs it."
      FINDINGS=$((FINDINGS + 1))
      return 0
    fi
    if [ "${pat}" = "true" ] && [ "${host_oauth}" = "unknown" ] && [ "${oauth}" != "true" ]; then
      echo "        UNPROVEN: pat is allowed and this integration has no OAuth block, but the host's"
      echo "          own capabilities could not be read — do not record this integration as clean."
      UNPROVEN=$((UNPROVEN + 1))
    fi
  done <<<"${rows}"
}

audit() {
  resolve_org
  echo "Ona 4.3 — runner repository access and SCM integrations"
  echo "  organization: …${ORG_ID: -6} (tier ${ORG_TIER})"

  paginate "RunnerService/ListRunners" '{}' "runners"
  local runners="${PAGE_ITEMS}" ids rid rphase
  echo "  runners: $(jq 'length' <<<"${runners}")"
  # TRAP 5: carry each runner's REPORTED phase, not its desired one.
  ids=$(jq -r '.[] | [(.runnerId // ""), (.status.phase // "RUNNER_PHASE_UNSPECIFIED")] | @tsv' <<<"${runners}")
  if [ -z "${ids}" ]; then
    echo "  (no runners — no SCM integration surface to read)"
  else
    while IFS=$'\t' read -r rid rphase; do
      [ -n "${rid}" ] || continue
      echo "  runner …${rid: -6} reportedPhase=${rphase}"
      audit_runner "${rid}" "${rphase}"
      # TRAP 4: the reach probe is opt-in.
      if [ -n "${CHECK_REPO}" ]; then
        api "RunnerService/CheckRepositoryAccess" \
          "$(jq -nc --arg r "${rid}" --arg u "${CHECK_REPO}" '{runnerId: $r, repositoryUrl: $u}')"
        if [ "${RPC_CODE}" = "200" ]; then
          echo "    CheckRepositoryAccess: hasAccess=$(printf '%s' "${RPC_BODY}" | jq -r '.hasAccess // false')" \
               "error=$(printf '%s' "${RPC_BODY}" | jq -r 'if (.errorMessage // "") == "" then "(none)" else "(vendor message withheld)" end')"
        else
          echo "    CheckRepositoryAccess: NOT PROBED (HTTP ${RPC_CODE} $(rpc_err) — $(rpc_msg))"
          UNPROVEN=$((UNPROVEN + 1))
        fi
      fi
    done <<<"${ids}"
  fi

  if [ "${FINDINGS}" -gt 0 ]; then
    echo "RESULT: ${FINDINGS} SCM integration(s) allow PAT authentication on an OAuth-capable host."
    ona_complete
    return 1
  fi
  if [ "${UNPROVEN}" -gt 0 ]; then
    echo "RESULT: no finding proven, but ${UNPROVEN} PAT-enabled integration(s) sit on hosts whose"
    echo "        capabilities could not be probed (TRAP 5). Exiting 2: incomplete, not clean."
    ona_complete
    return 2
  fi
  echo "COMPLIANT: no SCM integration allows PAT authentication where the host supports OAuth2."
  ona_complete
  return 0
}
# HTH Guide Excerpt: end runner-repo-access-audit

audit
