#!/usr/bin/env bash
# HTH GitLab Control 2.1: Protect CI/CD Variables
# Profile: L1 | NIST: SC-12, SC-28 | SOC 2: CC6.1, CC6.7
# https://howtoharden.com/guides/gitlab/#21-protect-cicd-variables
#
# Required: PROJECT_ID environment variable (or pass as $1)
source "$(dirname "$0")/common.sh"

PROJECT_ID="${PROJECT_ID:-${1:-}}"
: "${PROJECT_ID:?Set PROJECT_ID or pass as first argument}"

banner "2.1: Protect CI/CD Variables (Project: ${PROJECT_ID})"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Auditing CI/CD variables for project ${PROJECT_ID}..."

# HTH Guide Excerpt: begin api-audit-cicd-variables
# Retrieve all project-level CI/CD variables and check protection settings
VARIABLES=$(gl_get "/projects/${PROJECT_ID}/variables" 2>/dev/null) || {
  fail "2.1 Failed to retrieve CI/CD variables -- check PROJECT_ID and token permissions"
  increment_failed
  summary
  exit 0
}

VAR_COUNT=$(echo "${VARIABLES}" | jq 'length' 2>/dev/null || echo "0")
info "2.1 Found ${VAR_COUNT} CI/CD variable(s)"

UNPROTECTED=0
UNMASKED=0
RAW_EXPOSED=0

echo "${VARIABLES}" | jq -c '.[]' 2>/dev/null | while IFS= read -r var; do
  KEY=$(echo "${var}" | jq -r '.key')
  PROTECTED=$(echo "${var}" | jq -r '.protected')
  MASKED=$(echo "${var}" | jq -r '.masked')
  RAW=$(echo "${var}" | jq -r '.raw // false')

  ISSUES=""
  if [ "${PROTECTED}" != "true" ]; then
    ISSUES="${ISSUES} unprotected"
  fi
  if [ "${MASKED}" != "true" ]; then
    ISSUES="${ISSUES} unmasked"
  fi
  if [ "${RAW}" == "true" ]; then
    ISSUES="${ISSUES} raw-exposed"
  fi

  if [ -n "${ISSUES}" ]; then
    warn "2.1 Variable '${KEY}':${ISSUES}"
  else
    pass "2.1 Variable '${KEY}': protected + masked"
  fi
done

# Summary counts (re-parse for totals since while-loop runs in subshell)
UNPROTECTED=$(echo "${VARIABLES}" | jq '[.[] | select(.protected != true)] | length' 2>/dev/null || echo "0")
UNMASKED=$(echo "${VARIABLES}" | jq '[.[] | select(.masked != true)] | length' 2>/dev/null || echo "0")
RAW_EXPOSED=$(echo "${VARIABLES}" | jq '[.[] | select(.raw == true)] | length' 2>/dev/null || echo "0")

info "2.1 Unprotected: ${UNPROTECTED}, Unmasked: ${UNMASKED}, Raw-exposed: ${RAW_EXPOSED}"
# HTH Guide Excerpt: end api-audit-cicd-variables

if [ "${UNPROTECTED}" -gt 0 ] || [ "${UNMASKED}" -gt 0 ]; then
  fail "2.1 Found CI/CD variables without protection or masking -- update via Settings > CI/CD > Variables"
  increment_failed
else
  pass "2.1 All CI/CD variables are protected and masked"
  increment_applied
fi

summary
