#!/usr/bin/env bash
# HTH GitHub Control 2.01: Enable Secret Scanning
# Profile: L1 | NIST: IA-5(7), SC-28
# https://howtoharden.com/guides/github/#21-enable-secret-scanning
source "$(dirname "$0")/common.sh"

banner "2.01: Enable Secret Scanning"
should_apply 1 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "2.01 Checking secret scanning on ${GITHUB_ORG}/${REPO}..."

# Idempotency check -- verify secret scanning and push protection status
REPO_DATA=$(gh_get "/repos/${GITHUB_ORG}/${REPO}") || {
  fail "2.01 Unable to retrieve repo settings for ${GITHUB_ORG}/${REPO}"
  increment_failed
  summary
  exit 0
}

SS_STATUS=$(echo "${REPO_DATA}" | jq -r '.security_and_analysis.secret_scanning.status // "disabled"')
PP_STATUS=$(echo "${REPO_DATA}" | jq -r '.security_and_analysis.secret_scanning_push_protection.status // "disabled"')

if [ "${SS_STATUS}" = "enabled" ] && [ "${PP_STATUS}" = "enabled" ]; then
  pass "2.01 Secret scanning and push protection are already enabled"
  # Check for open secret scanning alerts
  OPEN_ALERTS=$(gh_get "/orgs/${GITHUB_ORG}/secret-scanning/alerts?state=open&per_page=1" \
    | jq '. | length' 2>/dev/null || echo "-1")
  if [ "${OPEN_ALERTS}" = "0" ]; then
    pass "2.01 No open secret scanning alerts"
  elif [ "${OPEN_ALERTS}" != "-1" ]; then
    warn "2.01 Open secret scanning alerts detected -- review required"
  fi
  increment_applied
  summary
  exit 0
fi

warn "2.01 Secret scanning: ${SS_STATUS}, Push protection: ${PP_STATUS}"

# HTH Guide Excerpt: begin api-enable-secret-scanning
# Enable secret scanning and push protection on the repository
info "2.01 Enabling secret scanning and push protection..."
RESPONSE=$(gh_patch "/repos/${GITHUB_ORG}/${REPO}" '{
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}') || {
  fail "2.01 Failed to enable secret scanning -- may require GHAS license"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-enable-secret-scanning

R_SS=$(echo "${RESPONSE}" | jq -r '.security_and_analysis.secret_scanning.status // "disabled"')
R_PP=$(echo "${RESPONSE}" | jq -r '.security_and_analysis.secret_scanning_push_protection.status // "disabled"')

if [ "${R_SS}" = "enabled" ] && [ "${R_PP}" = "enabled" ]; then
  pass "2.01 Secret scanning and push protection enabled"
  increment_applied
else
  fail "2.01 Secret scanning not confirmed after update (scanning: ${R_SS}, push protection: ${R_PP})"
  increment_failed
fi

summary
