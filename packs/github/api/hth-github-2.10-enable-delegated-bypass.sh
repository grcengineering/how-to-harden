#!/usr/bin/env bash
# HTH GitHub Control 2.10: Enable Secret Scanning Delegated Bypass
# Profile: L2 | NIST: SA-11, IA-5(7)
# https://howtoharden.com/guides/github/#26-enable-secret-scanning-delegated-bypass
source "$(dirname "$0")/common.sh"

banner "2.10: Enable Secret Scanning Delegated Bypass"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "2.10 Checking push protection bypass settings for ${GITHUB_ORG}/${REPO}..."

# HTH Guide Excerpt: begin api-check-push-protection-bypasses
# Audit push protection bypass events via secret scanning alerts
info "2.10 Listing push protection bypass alerts..."
ALERTS=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/secret-scanning/alerts?state=open&per_page=100") || {
  warn "2.10 Unable to list secret scanning alerts (may require GHAS license)"
}

if [ -n "${ALERTS}" ]; then
  BYPASS_COUNT=$(echo "${ALERTS}" | jq '[.[] | select(.push_protection_bypassed == true)] | length')
  if [ "${BYPASS_COUNT}" -gt "0" ]; then
    warn "2.10 ${BYPASS_COUNT} alert(s) with push protection bypass detected"
    echo "${ALERTS}" | jq -r '.[] | select(.push_protection_bypassed == true) | "\(.secret_type) | bypassed by: \(.push_protection_bypassed_by.login // "unknown") | \(.created_at)"'
  else
    pass "2.10 No push protection bypasses detected"
  fi
fi

# Check org-level security configuration for push protection
info "2.10 Checking organization code security configuration..."
ORG_SECURITY=$(gh_get "/orgs/${GITHUB_ORG}/code-security/configurations") || {
  warn "2.10 Unable to retrieve org security configurations"
}

if [ -n "${ORG_SECURITY}" ]; then
  echo "${ORG_SECURITY}" | jq '.[] | {name: .name, secret_scanning_push_protection: .secret_scanning_push_protection}'
fi
# HTH Guide Excerpt: end api-check-push-protection-bypasses

pass "2.10 Push protection bypass audit complete"
increment_applied

summary
