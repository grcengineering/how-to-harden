#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: gitlab-7.1
#   guide:   https://howtoharden.com/guides/gitlab/#71-govern-gitlab-duo-availability
#   profile: L1
#   mode:    read-only
#   requires: GITLAB_TOKEN(personal access token, read_api scope; Owner role on the group), GROUP_ID
# =============================================================================
# HTH GitLab Control 7.1: Govern GitLab Duo Availability
# Profile: L1 | NIST: CM-7, SA-9
# https://howtoharden.com/guides/gitlab/#71-govern-gitlab-duo-availability
#
# Read-only audit of a top-level group's GitLab Duo posture:
#   GET /groups/:id   duo_availability, experiment_features_enabled
# Docs: docs.gitlab.com/api/groups -- these attributes are returned to users of
# GitLab Premium or Ultimate. duo_availability is one of default_on,
# default_off, never_on (never_on is "Always off" in the UI).
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (the call failed or the
# Duo attributes were not returned, so the posture is unknown).
# =============================================================================
source "$(dirname "$0")/common.sh"

GROUP_ID="${GROUP_ID:-${1:-}}"
: "${GROUP_ID:?Set GROUP_ID or pass as first argument}"

banner "7.1: Govern GitLab Duo Availability (Group: ${GROUP_ID})"
should_apply 1 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin api-audit-duo-availability
GROUP=$(gl_get "/groups/${GROUP_ID}") || {
  fail "7.1 GET /groups/${GROUP_ID} failed -- check GROUP_ID and token"; summary; exit 2; }
AVAILABILITY=$(printf '%s' "${GROUP}" | jq -r '.duo_availability // empty')
# (Not `// empty`: jq's // also discards a literal false.)
EXPERIMENTS=$(printf '%s' "${GROUP}" | jq -r '.experiment_features_enabled | if . == null then empty else tostring end')

if [ -z "${AVAILABILITY}" ]; then
  fail "7.1 duo_availability was not returned -- requires Premium/Ultimate and the Owner role"
  summary; exit 2
fi

FINDINGS=0
case "${AVAILABILITY}" in
  never_on)    pass "7.1 GitLab Duo availability: Always off" ;;
  default_off) pass "7.1 GitLab Duo availability: Off by default (enablement is an explicit act)" ;;
  default_on)  warn "7.1 GitLab Duo availability: On by default -- every new project gets Duo; confirm this was a decision, or set Off by default" ;;
  *)           fail "7.1 Unrecognized duo_availability value '${AVAILABILITY}'"; FINDINGS=$((FINDINGS + 1)) ;;
esac

STATE_UNKNOWN=0
if [ "${EXPERIMENTS}" = "true" ]; then
  fail "7.1 Experiment and beta features are ON -- leave them off until their data handling terms are reviewed"
  FINDINGS=$((FINDINGS + 1))
elif [ "${EXPERIMENTS}" = "false" ]; then
  pass "7.1 Experiment and beta features are off"
else
  # Absent is unknown, never "off": a missing field could be hiding a finding.
  fail "7.1 experiment_features_enabled was not returned -- experiment and beta feature posture unknown"
  STATE_UNKNOWN=1
fi
# HTH Guide Excerpt: end api-audit-duo-availability

if [ "${FINDINGS}" -gt 0 ]; then increment_failed; else increment_applied; fi
summary
[ "${STATE_UNKNOWN}" -eq 0 ] || exit 2
[ "${FINDINGS}" -eq 0 ] || exit 1
