#!/usr/bin/env bash
# HTH GitHub Control 5.03: Audit Org Webhooks
# Profile: L2 | NIST: SC-8, SI-7
# https://howtoharden.com/guides/github/#53-audit-org-webhooks
source "$(dirname "$0")/common.sh"

banner "5.03: Audit Org Webhooks (Audit Only)"
should_apply 2 || { increment_skipped; summary; exit 0; }
info "5.03 Auditing organization webhooks for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-audit-webhooks
# Audit: Check all org webhooks for insecure HTTP URLs and missing secrets
HOOKS=$(gh_get "/orgs/${GITHUB_ORG}/hooks") || {
  fail "5.03 Unable to retrieve org webhooks (may require admin:org_hook scope)"
  increment_failed
  summary
  exit 0
}

TOTAL_HOOKS=$(echo "${HOOKS}" | jq '. | length' 2>/dev/null || echo "0")
info "5.03 Found ${TOTAL_HOOKS} organization webhook(s)"

ISSUES=0

if [ "${TOTAL_HOOKS}" -gt 0 ]; then
  # Check for HTTP (non-HTTPS) webhook URLs
  HTTP_HOOKS=$(echo "${HOOKS}" | jq '[.[] | select(.config.url | test("^http://"))] | length' 2>/dev/null || echo "0")
  if [ "${HTTP_HOOKS}" -gt 0 ]; then
    fail "5.03 ${HTTP_HOOKS} webhook(s) use insecure HTTP (should use HTTPS)"
    echo "${HOOKS}" | jq -r '.[] | select(.config.url | test("^http://")) | "  ID: \(.id) | URL: \(.config.url)"' 2>/dev/null
    ISSUES=$((ISSUES + HTTP_HOOKS))
  fi

  # Check for webhooks without secrets configured
  NO_SECRET=$(echo "${HOOKS}" | jq '[.[] | select(.config.secret == null or .config.secret == "")] | length' 2>/dev/null || echo "0")
  if [ "${NO_SECRET}" -gt 0 ]; then
    warn "5.03 ${NO_SECRET} webhook(s) have no secret configured"
    echo "${HOOKS}" | jq -r '.[] | select(.config.secret == null or .config.secret == "") | "  ID: \(.id) | URL: \(.config.url)"' 2>/dev/null
    ISSUES=$((ISSUES + NO_SECRET))
  fi

  # List all webhooks for review
  info "5.03 All webhooks:"
  echo "${HOOKS}" | jq -r '.[] | "  ID: \(.id) | URL: \(.config.url) | Active: \(.active) | Events: \(.events | join(", "))"' 2>/dev/null
fi
# HTH Guide Excerpt: end api-audit-webhooks

if [ "${ISSUES}" = "0" ]; then
  pass "5.03 All org webhooks use HTTPS and have secrets configured"
  increment_applied
else
  fail "5.03 ${ISSUES} webhook issue(s) found -- manual remediation required"
  increment_failed
fi

summary
