#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: gitlab-7.2
#   guide:   https://howtoharden.com/guides/gitlab/#72-treat-repository-content-as-untrusted-gitlab-duo-input
#   profile: L2
#   mode:    read-only
#   requires: GITLAB_TOKEN(personal access token, read_api scope; Owner role on the group), GROUP_ID
# =============================================================================
# HTH GitLab Control 7.2: Treat Repository Content as Untrusted GitLab Duo Input
# Profile: L2 | NIST: SI-10, SA-9
# https://howtoharden.com/guides/gitlab/#72-treat-repository-content-as-untrusted-gitlab-duo-input
#
# Read-only audit. Every call is a GET:
#   GET /groups/:id   duo_availability; ai_settings.prompt_injection_protection_level
#                     (no_checks, log_only or interrupt; GitLab 18.8+, returned
#                     only when GitLab Duo Agent Platform is available to the group)
#   GET /groups/:id/projects?include_subgroups=true&visibility=public&archived=false
# Docs: docs.gitlab.com/api/groups
#
# Public projects accept outside contributions, so their merge requests,
# comments and files are attacker-controllable Duo input. The project-level
# GitLab Duo toggle is not exposed by the REST API: when Duo is not "Always
# off" for the group, the pack lists the public projects to check by hand.
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (a call failed or the
# group's Duo availability was not returned).
# =============================================================================
source "$(dirname "$0")/common.sh"

GROUP_ID="${GROUP_ID:-${1:-}}"
: "${GROUP_ID:?Set GROUP_ID or pass as first argument}"

banner "7.2: Repository Content as Untrusted Duo Input (Group: ${GROUP_ID})"
should_apply 2 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin api-audit-duo-untrusted-input
GROUP=$(gl_get "/groups/${GROUP_ID}") || {
  fail "7.2 GET /groups/${GROUP_ID} failed -- check GROUP_ID and token"; summary; exit 2; }
AVAILABILITY=$(printf '%s' "${GROUP}" | jq -r '.duo_availability // empty')
[ -n "${AVAILABILITY}" ] || {
  fail "7.2 duo_availability was not returned -- requires Premium/Ultimate and the Owner role"; summary; exit 2; }

# Public projects in the group and its subgroups (all pages).
PUBLIC="[]"
PAGE=1
while true; do
  RESP=$(gl_get "/groups/${GROUP_ID}/projects?include_subgroups=true&visibility=public&archived=false&per_page=100&page=${PAGE}") || {
    fail "7.2 Could not list public projects (page ${PAGE})"; summary; exit 2; }
  COUNT=$(printf '%s' "${RESP}" | jq 'length') || { fail "7.2 Unparseable project list"; summary; exit 2; }
  PUBLIC=$(printf '%s %s' "${PUBLIC}" "${RESP}" | jq -s 'add')
  [ "${COUNT}" -lt 100 ] && break
  PAGE=$((PAGE + 1))
done
PUBLIC_COUNT=$(printf '%s' "${PUBLIC}" | jq 'length')

FINDINGS=0
if [ "${AVAILABILITY}" = "never_on" ]; then
  pass "7.2 Duo is Always off for this group -- no project content reaches it"
elif [ "${PUBLIC_COUNT}" -eq 0 ]; then
  pass "7.2 No public projects in this group"
else
  if [ "${AVAILABILITY}" = "default_on" ]; then
    fail "7.2 Duo is On by default and ${PUBLIC_COUNT} public project(s) inherit it"
    FINDINGS=$((FINDINGS + 1))
  fi
  warn "7.2 Confirm GitLab Duo is off in Settings > General > GitLab Duo for each public project:"
  printf '%s' "${PUBLIC}" | jq -r '.[] | "  - \(.path_with_namespace)"'
fi

LEVEL=$(printf '%s' "${GROUP}" | jq -r '.ai_settings.prompt_injection_protection_level // empty')
case "${LEVEL}" in
  interrupt) pass "7.2 Prompt injection protection: interrupt" ;;
  log_only)  warn "7.2 Prompt injection protection: log_only (detections are logged, not stopped)" ;;
  no_checks) warn "7.2 Prompt injection protection: no_checks" ;;
  *)         info "7.2 Prompt injection protection level not returned (Duo Agent Platform not available to this group)" ;;
esac
# HTH Guide Excerpt: end api-audit-duo-untrusted-input

if [ "${FINDINGS}" -gt 0 ]; then increment_failed; else increment_applied; fi
summary
[ "${FINDINGS}" -eq 0 ] || exit 1
