#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: gitlab-1.2
#   guide:   https://howtoharden.com/guides/gitlab/#12-implement-granular-project-permissions
#   profile: L1
#   mode:    read-only
#   requires: GITLAB_TOKEN(personal access token, read_api scope; Maintainer role on the project), PROJECT_ID
# =============================================================================
# HTH GitLab Control 1.2: Implement Granular Project Permissions
# Profile: L1 | NIST: AC-3, AC-6 | SOC 2: CC6.2, CC8.1
# https://howtoharden.com/guides/gitlab/#12-implement-granular-project-permissions
#
# Read-only audit. Every call is a GET:
#   GET /projects/:id                         default branch
#   GET /projects/:id/protected_branches      push/merge access, force push, code owners
#   GET /projects/:id/approvals               approval settings (Premium/Ultimate)
#   GET /projects/:id/approval_rules          required approvals (Premium/Ultimate)
# Docs: docs.gitlab.com/api/protected_branches, docs.gitlab.com/api/merge_request_approvals
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (a call failed, so part of
# the project was not audited -- on the Free tier the two approvals endpoints
# are unavailable, and the pack says so rather than reporting them clean).
# =============================================================================
source "$(dirname "$0")/common.sh"

PROJECT_ID="${PROJECT_ID:-${1:-}}"
: "${PROJECT_ID:?Set PROJECT_ID or pass as first argument}"

banner "1.2: Implement Granular Project Permissions (Project: ${PROJECT_ID})"
should_apply 1 || { increment_skipped; summary; exit 0; }

STATE_UNKNOWN=0
FINDINGS=0
finding() { fail "$1"; FINDINGS=$((FINDINGS + 1)); }

# Walk every page of a list endpoint; a failed page is fatal (exit 2), never "empty".
gl_get_all() {
  local path="$1" sep="?" page=1 all="[]" resp count
  case "${path}" in *\?*) sep="&" ;; esac
  while true; do
    resp=$(gl_get "${path}${sep}per_page=100&page=${page}") || return 1
    count=$(printf '%s' "${resp}" | jq 'length') || return 1
    [ "${count}" -eq 0 ] && break
    all=$(printf '%s %s' "${all}" "${resp}" | jq -s 'add')
    [ "${count}" -lt 100 ] && break
    page=$((page + 1))
  done
  printf '%s' "${all}"
}

# HTH Guide Excerpt: begin api-audit-project-permissions
# 1. The default branch must be covered by a protected-branch rule.
PROJECT=$(gl_get "/projects/${PROJECT_ID}") || {
  fail "1.2 GET /projects/${PROJECT_ID} failed -- check PROJECT_ID and token"; summary; exit 2; }
DEFAULT_BRANCH=$(printf '%s' "${PROJECT}" | jq -r '.default_branch // empty')

RULES=$(gl_get_all "/projects/${PROJECT_ID}/protected_branches") || {
  fail "1.2 Could not list protected branches (HTTP status above; a 403 means the Maintainer role is required)"; summary; exit 2; }

COVERED=0
while IFS= read -r pattern; do
  # GitLab protected-branch names may use * as a wildcard.
  # shellcheck disable=SC2053
  [ -n "${DEFAULT_BRANCH}" ] && [[ "${DEFAULT_BRANCH}" == ${pattern} ]] && COVERED=1
done < <(printf '%s' "${RULES}" | jq -r '.[].name')
if [ -z "${DEFAULT_BRANCH}" ]; then
  warn "1.2 Project has no default branch (empty repository?) -- nothing to protect yet"
elif [ "${COVERED}" -eq 1 ]; then
  pass "1.2 Default branch '${DEFAULT_BRANCH}' is protected"
else
  finding "1.2 Default branch '${DEFAULT_BRANCH}' is NOT protected"
fi

# 2. Each rule: nobody pushes directly, Developers do not merge, no force push.
while IFS= read -r rule; do
  NAME=$(printf '%s' "${rule}" | jq -r '.name')
  PUSHERS=$(printf '%s' "${rule}" | jq '[.push_access_levels[]? | select(.access_level != 0)] | length')
  DEV_MERGE=$(printf '%s' "${rule}" | jq '[.merge_access_levels[]? | select(.access_level == 30)] | length')
  FORCE=$(printf '%s' "${rule}" | jq -r '.allow_force_push')
  CODEOWNER=$(printf '%s' "${rule}" | jq -r '.code_owner_approval_required')
  [ "${PUSHERS}" -gt 0 ] && finding "1.2 '${NAME}': direct push allowed for ${PUSHERS} role/user/group/key entry(ies) -- set Allowed to push to No one"
  [ "${DEV_MERGE}" -gt 0 ] && finding "1.2 '${NAME}': Developers are allowed to merge -- restrict to Maintainers"
  [ "${FORCE}" = "true" ] && finding "1.2 '${NAME}': force push is allowed"
  [ "${CODEOWNER}" = "true" ] || warn "1.2 '${NAME}': code owner approval not required (Premium/Ultimate)"
done < <(printf '%s' "${RULES}" | jq -c '.[]')

# 3. Approval settings (Premium/Ultimate): authors cannot approve their own MRs,
#    and approval rules cannot be edited per merge request. Console labels
#    (Settings > Merge requests): "Prevent approval by merge request creator",
#    "Prevent editing approval rules in merge requests".
if APPROVALS=$(gl_get "/projects/${PROJECT_ID}/approvals"); then
  [ "$(printf '%s' "${APPROVALS}" | jq -r '.merge_requests_author_approval')" = "false" ] \
    && pass "1.2 Prevent approval by merge request creator: enabled" \
    || finding "1.2 Merge request authors can approve their own merge requests"
  [ "$(printf '%s' "${APPROVALS}" | jq -r '.disable_overriding_approvers_per_merge_request')" = "true" ] \
    && pass "1.2 Prevent editing approval rules in merge requests: enabled" \
    || finding "1.2 Approval rules can be edited in individual merge requests"
else
  fail "1.2 Could not read approval settings (HTTP status above; a 403 or 404 here usually means Premium/Ultimate and the Maintainer role are required)"
  STATE_UNKNOWN=1
fi

# 4. At least one approval rule requires two or more approvals.
if APPROVAL_RULES=$(gl_get_all "/projects/${PROJECT_ID}/approval_rules"); then
  MAX_REQUIRED=$(printf '%s' "${APPROVAL_RULES}" | jq '[.[].approvals_required] | max // 0')
  if [ "${MAX_REQUIRED}" -ge 2 ]; then
    pass "1.2 Highest approval rule requires ${MAX_REQUIRED} approvals"
  else
    finding "1.2 No approval rule requires 2 or more approvals (highest: ${MAX_REQUIRED})"
  fi
else
  fail "1.2 Could not list approval rules (HTTP status above; a 403 or 404 here usually means Premium/Ultimate is required)"
  STATE_UNKNOWN=1
fi
# HTH Guide Excerpt: end api-audit-project-permissions

if [ "${FINDINGS}" -gt 0 ]; then
  fail "1.2 ${FINDINGS} project permission finding(s) -- fix in Settings > Repository and Settings > Merge requests"
  increment_failed
else
  [ "${STATE_UNKNOWN}" -eq 0 ] && pass "1.2 Protected branches and approval settings match the guide"
  increment_applied
fi

summary
[ "${STATE_UNKNOWN}" -eq 0 ] || exit 2
[ "${FINDINGS}" -eq 0 ] || exit 1
