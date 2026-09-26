#!/usr/bin/env bash
# HTH GitHub Control 8.01: Security Overview Dashboard Queries
# Profile: L1 | NIST: RA-5, SI-4
# https://howtoharden.com/guides/github/#82-use-security-overview-dashboard
source "$(dirname "$0")/common.sh"

banner "8.01: Security Overview Dashboard"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "8.01 Querying security overview for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-security-overview-alerts
# Count every page of an alert query (a single page caps at 100)
count_alerts() {
  gh api --paginate "$1" --jq 'length' | awk '{s += $1} END {print s + 0}'
}

# Query organization-wide security alert summary
info "8.01 Querying Dependabot alerts summary..."
DEPENDABOT_COUNT=$(count_alerts "/orgs/${GITHUB_ORG}/dependabot/alerts?state=open&severity=critical,high&per_page=100") || {
  fail "8.01 Unable to query Dependabot alerts"; increment_failed; DEPENDABOT_COUNT="?"
}

info "8.01 Querying secret scanning alerts summary..."
SECRET_COUNT=$(count_alerts "/orgs/${GITHUB_ORG}/secret-scanning/alerts?state=open&per_page=100") || {
  fail "8.01 Unable to query secret scanning alerts"; increment_failed; SECRET_COUNT="?"
}

# Code scanning takes ONE severity per request, so query critical and high separately
info "8.01 Querying code scanning alerts summary..."
CODE_CRITICAL=$(count_alerts "/orgs/${GITHUB_ORG}/code-scanning/alerts?state=open&severity=critical&per_page=100") \
  && CODE_HIGH=$(count_alerts "/orgs/${GITHUB_ORG}/code-scanning/alerts?state=open&severity=high&per_page=100") \
  && CODE_COUNT=$((CODE_CRITICAL + CODE_HIGH)) || {
  fail "8.01 Unable to query code scanning alerts"; increment_failed; CODE_COUNT="?"
}

echo ""
echo "Security Overview Summary for ${GITHUB_ORG}:"
echo "  Dependabot (critical/high):    ${DEPENDABOT_COUNT}"
echo "  Secret scanning (open):        ${SECRET_COUNT}"
echo "  Code scanning (critical/high): ${CODE_COUNT}"
# HTH Guide Excerpt: end api-security-overview-alerts

# HTH Guide Excerpt: begin api-audit-log-query
# Query audit log for security-relevant events (GitHub Enterprise Cloud)
info "8.01 Querying recent security audit events..."
gh_get "/orgs/${GITHUB_ORG}/audit-log?phrase=action:protected_branch+action:org.update_member&per_page=25" \
  | jq '.[] | {action: .action, actor: .actor, created_at: .created_at, repo: .repo}' || {
  warn "8.01 Unable to query audit log (requires GitHub Enterprise Cloud)"
}
# HTH Guide Excerpt: end api-audit-log-query

if [ "${CONTROLS_FAILED}" -eq 0 ]; then
  increment_applied
fi
summary
