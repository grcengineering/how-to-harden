#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: gitlab-4.3
#   guide:   https://howtoharden.com/guides/gitlab/#43-enable-secret-push-protection
#   profile: L1
#   mode:    read-only
#   requires: GITLAB_TOKEN(personal access token, read_api scope; Developer role or higher on each project), GROUP_ID or PROJECT_ID
# =============================================================================
# HTH GitLab Control 4.3: Enable Secret Push Protection
# Profile: L1 | NIST: IA-5, SC-28 | Tier: Ultimate
# https://howtoharden.com/guides/gitlab/#43-enable-secret-push-protection
#
# Read-only audit. Every call is a GET:
#   GET /groups/:id/projects?include_subgroups=true&archived=false   (GROUP_ID mode)
#   GET /projects/:id/security_settings   secret_push_protection_enabled
# Docs: docs.gitlab.com/api/project_security_settings (Tier: Ultimate)
#
# Exit codes: 0 compliant | 1 finding | 2 precondition (a call failed, so at
# least one project's setting is unknown -- it is never counted as enabled).
# =============================================================================
source "$(dirname "$0")/common.sh"

GROUP_ID="${GROUP_ID:-}"
PROJECT_ID="${PROJECT_ID:-${1:-}}"
[ -n "${GROUP_ID}" ] || [ -n "${PROJECT_ID}" ] || { fail "Set GROUP_ID (every project in the group) or PROJECT_ID"; exit 2; }

banner "4.3: Enable Secret Push Protection"
should_apply 1 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin api-audit-secret-push-protection
# Collect the projects to check: one project, or every active project in the
# group and its subgroups (all pages).
if [ -n "${GROUP_ID}" ]; then
  PROJECT_IDS=""
  PAGE=1
  while true; do
    RESP=$(gl_get "/groups/${GROUP_ID}/projects?include_subgroups=true&archived=false&per_page=100&page=${PAGE}") || {
      fail "4.3 Could not list projects in group ${GROUP_ID} (page ${PAGE})"; summary; exit 2; }
    COUNT=$(printf '%s' "${RESP}" | jq 'length') || { fail "4.3 Unparseable project list"; summary; exit 2; }
    PROJECT_IDS="${PROJECT_IDS} $(printf '%s' "${RESP}" | jq -r '.[].id' | tr '\n' ' ')"
    [ "${COUNT}" -lt 100 ] && break
    PAGE=$((PAGE + 1))
  done
else
  PROJECT_IDS="${PROJECT_ID}"
fi

ENABLED=0; DISABLED=0; UNKNOWN=0
for PID in ${PROJECT_IDS}; do
  if SETTINGS=$(gl_get "/projects/${PID}/security_settings"); then
    if [ "$(printf '%s' "${SETTINGS}" | jq -r '.secret_push_protection_enabled')" = "true" ]; then
      ENABLED=$((ENABLED + 1))
    else
      DISABLED=$((DISABLED + 1))
      fail "4.3 Project ${PID}: secret push protection is OFF"
    fi
  else
    UNKNOWN=$((UNKNOWN + 1))
    warn "4.3 Project ${PID}: could not read security settings (HTTP status above; a 403 means Ultimate and the Developer role are required)"
  fi
done
info "4.3 Secret push protection: ${ENABLED} enabled, ${DISABLED} disabled, ${UNKNOWN} unknown"
# HTH Guide Excerpt: end api-audit-secret-push-protection

if [ $((ENABLED + DISABLED + UNKNOWN)) -eq 0 ]; then
  warn "4.3 No projects found to audit"
  summary; exit 2
fi
if [ "${DISABLED}" -gt 0 ]; then
  increment_failed
else
  [ "${UNKNOWN}" -eq 0 ] && pass "4.3 Secret push protection is enabled on all ${ENABLED} project(s)"
  increment_applied
fi

summary
[ "${UNKNOWN}" -eq 0 ] || exit 2
[ "${DISABLED}" -eq 0 ] || exit 1
