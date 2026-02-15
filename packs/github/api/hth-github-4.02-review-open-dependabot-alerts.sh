#!/usr/bin/env bash
# HTH GitHub Control 4.02: Review Open Dependabot Alerts
# Profile: L1 | NIST: RA-5, SI-2
# https://howtoharden.com/guides/github/#42-review-open-dependabot-alerts
source "$(dirname "$0")/common.sh"

banner "4.02: Review Open Dependabot Alerts (Audit Only)"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.02 Auditing open Dependabot alerts for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-audit-dependabot-alerts
# Audit: Check for critical and high severity open Dependabot alerts
info "4.02 Checking critical Dependabot alerts..."
CRITICAL_ALERTS=$(gh_get "/orgs/${GITHUB_ORG}/dependabot/alerts?state=open&severity=critical&per_page=100" 2>/dev/null) || {
  warn "4.02 Unable to query Dependabot alerts (may require security_events scope)"
  CRITICAL_ALERTS="[]"
}
CRITICAL_COUNT=$(echo "${CRITICAL_ALERTS}" | jq '. | length' 2>/dev/null || echo "0")

info "4.02 Checking high severity Dependabot alerts..."
HIGH_ALERTS=$(gh_get "/orgs/${GITHUB_ORG}/dependabot/alerts?state=open&severity=high&per_page=100" 2>/dev/null) || {
  warn "4.02 Unable to query high severity Dependabot alerts"
  HIGH_ALERTS="[]"
}
HIGH_COUNT=$(echo "${HIGH_ALERTS}" | jq '. | length' 2>/dev/null || echo "0")

info "4.02 Open alerts -- Critical: ${CRITICAL_COUNT}, High: ${HIGH_COUNT}"

# List affected repositories for critical alerts
if [ "${CRITICAL_COUNT}" -gt 0 ]; then
  warn "4.02 Repositories with critical alerts:"
  echo "${CRITICAL_ALERTS}" | jq -r '.[].repository.full_name' 2>/dev/null | sort -u | while read -r REPO_NAME; do
    COUNT=$(echo "${CRITICAL_ALERTS}" | jq -r "[.[] | select(.repository.full_name == \"${REPO_NAME}\")] | length" 2>/dev/null)
    warn "4.02   ${REPO_NAME}: ${COUNT} critical alert(s)"
  done
fi
# HTH Guide Excerpt: end api-audit-dependabot-alerts

if [ "${CRITICAL_COUNT}" = "0" ] && [ "${HIGH_COUNT}" = "0" ]; then
  pass "4.02 No critical or high severity Dependabot alerts"
  increment_applied
elif [ "${CRITICAL_COUNT}" = "0" ]; then
  warn "4.02 ${HIGH_COUNT} high severity alert(s) require review"
  increment_applied
else
  fail "4.02 ${CRITICAL_COUNT} critical and ${HIGH_COUNT} high severity alert(s) require immediate attention"
  increment_failed
fi

summary
