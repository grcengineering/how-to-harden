#!/usr/bin/env bash
# HTH GitHub Control 2.04: Enable Secret Scanning Validity Checks
# Profile: L3 | NIST: IA-5, SI-4
# https://howtoharden.com/guides/github/#24-enable-secret-scanning-validity-checks
source "$(dirname "$0")/common.sh"

banner "2.04: Enable Secret Scanning Validity Checks"
should_apply 3 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "2.04 Checking secret scanning validity checks on ${GITHUB_ORG}/${REPO}..."

# Idempotency check -- verify validity checks are enabled
REPO_DATA=$(gh_get "/repos/${GITHUB_ORG}/${REPO}") || {
  fail "2.04 Unable to retrieve repo settings for ${GITHUB_ORG}/${REPO}"
  increment_failed
  summary
  exit 0
}

VC_STATUS=$(echo "${REPO_DATA}" | jq -r '.security_and_analysis.secret_scanning_validity_checks.status // "disabled"')

if [ "${VC_STATUS}" = "enabled" ]; then
  pass "2.04 Secret scanning validity checks are already enabled"
  increment_applied
  summary
  exit 0
fi

warn "2.04 Secret scanning validity checks are ${VC_STATUS}"

# HTH Guide Excerpt: begin api-enable-validity-checks
# Enable secret scanning validity checks to verify if detected secrets are still active
info "2.04 Enabling secret scanning validity checks..."
RESPONSE=$(gh_patch "/repos/${GITHUB_ORG}/${REPO}" '{
  "security_and_analysis": {
    "secret_scanning_validity_checks": { "status": "enabled" }
  }
}') || {
  fail "2.04 Failed to enable validity checks -- may require GHAS license"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-enable-validity-checks

RESULT=$(echo "${RESPONSE}" | jq -r '.security_and_analysis.secret_scanning_validity_checks.status // "disabled"')
if [ "${RESULT}" = "enabled" ]; then
  pass "2.04 Secret scanning validity checks enabled"
  increment_applied
else
  fail "2.04 Validity checks not confirmed after update (got: ${RESULT})"
  increment_failed
fi

summary
