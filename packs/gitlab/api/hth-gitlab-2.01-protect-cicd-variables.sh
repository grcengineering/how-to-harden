#!/usr/bin/env bash
# HTH GitLab Control 2.1: Protect CI/CD Variables
# Profile: L1 | NIST: SC-12, SC-28 | SOC 2: CC6.1, CC6.7
# https://howtoharden.com/guides/gitlab/#21-protect-cicd-variables
#
# Required: PROJECT_ID environment variable (or pass as $1)
# Exit codes: 0 compliant | 1 finding | 2 precondition (an API call failed, so nothing was audited)
source "$(dirname "$0")/common.sh"

PROJECT_ID="${PROJECT_ID:-${1:-}}"
: "${PROJECT_ID:?Set PROJECT_ID or pass as first argument}"

banner "2.1: Protect CI/CD Variables (Project: ${PROJECT_ID})"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Auditing CI/CD variables for project ${PROJECT_ID}..."

# HTH Guide Excerpt: begin api-audit-cicd-variables
# Retrieve all project-level CI/CD variables and check protection settings.
# The endpoint is paginated (20 per page by default), so walk every page --
# auditing only the first page would report a partial scan as a clean one.
VARIABLES="[]"
PAGE=1
while true; do
  RESPONSE=$(gl_get "/projects/${PROJECT_ID}/variables?per_page=100&page=${PAGE}") || {
    fail "2.1 Failed to retrieve CI/CD variables (page ${PAGE}) -- check PROJECT_ID and token permissions (Maintainer role)"
    increment_failed; summary; exit 2
  }
  COUNT=$(printf '%s' "${RESPONSE}" | jq 'length') || {
    fail "2.1 Unparseable response on page ${PAGE}"
    increment_failed; summary; exit 2
  }
  [ "${COUNT}" -eq 0 ] && break
  VARIABLES=$(printf '%s %s' "${VARIABLES}" "${RESPONSE}" | jq -s 'add')
  [ "${COUNT}" -lt 100 ] && break
  PAGE=$((PAGE + 1))
done

VAR_COUNT=$(printf '%s' "${VARIABLES}" | jq 'length')
info "2.1 Found ${VAR_COUNT} CI/CD variable(s)"

printf '%s' "${VARIABLES}" | jq -c '.[]' | while IFS= read -r var; do
  KEY=$(printf '%s' "${var}" | jq -r '.key')
  PROTECTED=$(printf '%s' "${var}" | jq -r '.protected')
  MASKED=$(printf '%s' "${var}" | jq -r '.masked')
  # raw=true means "Expand variable reference" is off, the recommended state
  RAW=$(printf '%s' "${var}" | jq -r '.raw')

  ISSUES=""
  if [ "${PROTECTED}" != "true" ]; then
    ISSUES="${ISSUES} unprotected"
  fi
  if [ "${MASKED}" != "true" ]; then
    ISSUES="${ISSUES} unmasked"
  fi
  if [ "${RAW}" == "false" ]; then
    ISSUES="${ISSUES} expands-references"
  fi

  if [ -n "${ISSUES}" ]; then
    warn "2.1 Variable '${KEY}':${ISSUES}"
  else
    pass "2.1 Variable '${KEY}': protected + masked"
  fi
done

# Summary counts (re-parse for totals since while-loop runs in subshell)
UNPROTECTED=$(printf '%s' "${VARIABLES}" | jq '[.[] | select(.protected != true)] | length')
UNMASKED=$(printf '%s' "${VARIABLES}" | jq '[.[] | select(.masked != true)] | length')
EXPANDED=$(printf '%s' "${VARIABLES}" | jq '[.[] | select(.raw == false)] | length')

info "2.1 Unprotected: ${UNPROTECTED}, Unmasked: ${UNMASKED}, Expands references: ${EXPANDED}"
# HTH Guide Excerpt: end api-audit-cicd-variables

if [ "${UNPROTECTED}" -gt 0 ] || [ "${UNMASKED}" -gt 0 ]; then
  fail "2.1 Found CI/CD variables without protection or masking -- update via Settings > CI/CD > Variables"
  increment_failed
else
  pass "2.1 All ${VAR_COUNT} CI/CD variable(s) are protected and masked"
  increment_applied
fi

summary
[ "${CONTROLS_FAILED}" -eq 0 ] || exit 1
