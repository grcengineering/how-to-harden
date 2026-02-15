#!/usr/bin/env bash
# HTH GitHub Control 2.02: Enable Dependabot Security Updates
# Profile: L1 | NIST: RA-5, SI-2
# https://howtoharden.com/guides/github/#22-enable-dependabot-security-updates
source "$(dirname "$0")/common.sh"

banner "2.02: Enable Dependabot Security Updates"
should_apply 1 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "2.02 Checking Dependabot security updates on ${GITHUB_ORG}/${REPO}..."

# Idempotency check -- verify Dependabot security updates are enabled
REPO_DATA=$(gh_get "/repos/${GITHUB_ORG}/${REPO}") || {
  fail "2.02 Unable to retrieve repo settings for ${GITHUB_ORG}/${REPO}"
  increment_failed
  summary
  exit 0
}

DEP_STATUS=$(echo "${REPO_DATA}" | jq -r '.security_and_analysis.dependabot_security_updates.status // "disabled"')

if [ "${DEP_STATUS}" = "enabled" ]; then
  pass "2.02 Dependabot security updates are already enabled"
  # Check for critical open Dependabot alerts
  CRITICAL_ALERTS=$(gh_get "/orgs/${GITHUB_ORG}/dependabot/alerts?state=open&severity=critical&per_page=1" \
    | jq '. | length' 2>/dev/null || echo "-1")
  if [ "${CRITICAL_ALERTS}" = "0" ]; then
    pass "2.02 No critical open Dependabot alerts"
  elif [ "${CRITICAL_ALERTS}" != "-1" ]; then
    warn "2.02 Critical open Dependabot alerts detected -- review required"
  fi
  increment_applied
  summary
  exit 0
fi

warn "2.02 Dependabot security updates are ${DEP_STATUS}"

# HTH Guide Excerpt: begin api-enable-dependabot
# Enable Dependabot vulnerability alerts and security updates
info "2.02 Enabling vulnerability alerts and Dependabot security updates..."
curl -sf -X PUT "${GH_API}/repos/${GITHUB_ORG}/${REPO}/vulnerability-alerts" \
  -H "${AUTH_HEADER}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" || {
  fail "2.02 Failed to enable vulnerability alerts"
  increment_failed
  summary
  exit 0
}

curl -sf -X PUT "${GH_API}/repos/${GITHUB_ORG}/${REPO}/automated-security-fixes" \
  -H "${AUTH_HEADER}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" || {
  fail "2.02 Failed to enable Dependabot security updates"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-enable-dependabot

pass "2.02 Dependabot vulnerability alerts and security updates enabled"
increment_applied

summary
