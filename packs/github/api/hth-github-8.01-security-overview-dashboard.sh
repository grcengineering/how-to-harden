#!/usr/bin/env bash
# HTH GitHub Control 8.01: Security Overview Dashboard Queries
# Profile: L1 | NIST: RA-5, SI-4
# https://howtoharden.com/guides/github/#82-use-security-overview-dashboard
source "$(dirname "$0")/common.sh"

banner "8.01: Security Overview Dashboard"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "8.01 Querying security overview for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-security-overview-alerts
# Query organization-wide security alert summary
info "8.01 Querying Dependabot alerts summary..."
DEPENDABOT=$(gh_get "/orgs/${GITHUB_ORG}/dependabot/alerts?state=open&severity=critical,high&per_page=100") || {
  warn "8.01 Unable to query Dependabot alerts"
}
DEPENDABOT_COUNT=$(echo "${DEPENDABOT}" | jq 'length' 2>/dev/null || echo "0")

info "8.01 Querying secret scanning alerts summary..."
SECRETS=$(gh_get "/orgs/${GITHUB_ORG}/secret-scanning/alerts?state=open&per_page=100") || {
  warn "8.01 Unable to query secret scanning alerts"
}
SECRET_COUNT=$(echo "${SECRETS}" | jq 'length' 2>/dev/null || echo "0")

info "8.01 Querying code scanning alerts summary..."
CODE=$(gh_get "/orgs/${GITHUB_ORG}/code-scanning/alerts?state=open&severity=critical,error&per_page=100") || {
  warn "8.01 Unable to query code scanning alerts"
}
CODE_COUNT=$(echo "${CODE}" | jq 'length' 2>/dev/null || echo "0")

echo ""
echo "Security Overview Summary for ${GITHUB_ORG}:"
echo "  Dependabot (critical/high): ${DEPENDABOT_COUNT}"
echo "  Secret scanning (open):     ${SECRET_COUNT}"
echo "  Code scanning (critical):   ${CODE_COUNT}"
# HTH Guide Excerpt: end api-security-overview-alerts

# HTH Guide Excerpt: begin api-audit-log-query
# Query audit log for security-relevant events
info "8.01 Querying recent security audit events..."
gh_get "/orgs/${GITHUB_ORG}/audit-log?phrase=action:protected_branch+action:org.update_member&per_page=25" \
  | jq '.[] | {action: .action, actor: .actor, created_at: .created_at, repo: .repo}' || {
  warn "8.01 Unable to query audit log"
}
# HTH Guide Excerpt: end api-audit-log-query

increment_applied
summary
