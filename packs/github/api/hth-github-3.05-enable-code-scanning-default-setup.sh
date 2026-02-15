#!/usr/bin/env bash
# HTH GitHub Control 3.05: Enable Code Scanning Default Setup
# Profile: L2 | NIST: SA-11, SI-7
# https://howtoharden.com/guides/github/#35-enable-code-scanning-default-setup
source "$(dirname "$0")/common.sh"

banner "3.05: Enable Code Scanning Default Setup"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "3.05 Checking code scanning setup on ${GITHUB_ORG}/${REPO}..."

# Idempotency check -- verify code scanning default setup is configured
SCAN_DATA=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/code-scanning/default-setup" 2>/dev/null) || {
  warn "3.05 Code scanning default-setup endpoint not available (may require GHAS)"
  # Try remediation anyway
  SCAN_DATA=""
}

if [ -n "${SCAN_DATA}" ]; then
  CS_STATE=$(echo "${SCAN_DATA}" | jq -r '.state // "not-configured"')
  if [ "${CS_STATE}" = "configured" ]; then
    pass "3.05 Code scanning default setup is already configured"
    increment_applied
    summary
    exit 0
  fi
  warn "3.05 Code scanning state: ${CS_STATE}"
fi

# HTH Guide Excerpt: begin api-enable-code-scanning
# Enable CodeQL code scanning with the default query suite
info "3.05 Enabling code scanning default setup..."
RESPONSE=$(gh_patch "/repos/${GITHUB_ORG}/${REPO}/code-scanning/default-setup" '{
  "state": "configured",
  "query_suite": "default"
}') || {
  fail "3.05 Failed to enable code scanning -- may require GHAS license"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-enable-code-scanning

R_STATE=$(echo "${RESPONSE}" | jq -r '.state // "unknown"')
# The API may return a run_id indicating async configuration
R_RUN=$(echo "${RESPONSE}" | jq -r '.run_id // empty' 2>/dev/null || true)

if [ "${R_STATE}" = "configured" ] || [ -n "${R_RUN}" ]; then
  pass "3.05 Code scanning default setup enabled"
  increment_applied
else
  fail "3.05 Code scanning not confirmed after update (state: ${R_STATE})"
  increment_failed
fi

summary
