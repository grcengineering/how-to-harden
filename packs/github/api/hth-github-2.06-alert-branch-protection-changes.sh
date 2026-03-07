#!/usr/bin/env bash
# HTH GitHub Control 2.06: Alert on Branch Protection Changes
# Profile: L1 | NIST: AU-12, CM-3
# https://howtoharden.com/guides/github/#21-enable-branch-protection-for-all-critical-branches
source "$(dirname "$0")/common.sh"

banner "2.06: Alert on Branch Protection Changes"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.06 Checking audit log for branch protection changes in ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-alert-branch-protection
# Query audit log for branch protection rule changes
EVENTS=$(gh_get "/orgs/${GITHUB_ORG}/audit-log?phrase=action:protected_branch&per_page=30") || {
  fail "2.06 Unable to query audit log (requires admin:org scope)"
  increment_failed
  summary
  exit 0
}

echo "${EVENTS}" | jq '[.[] | {
  actor: .actor,
  action: .action,
  repo: .repo,
  created_at: .created_at
}]'
# HTH Guide Excerpt: end api-alert-branch-protection

EVENT_COUNT=$(echo "${EVENTS}" | jq 'length' 2>/dev/null || echo "0")
if [ "${EVENT_COUNT}" -gt 0 ]; then
  warn "2.06 Found ${EVENT_COUNT} branch protection change events -- review for unauthorized modifications"
else
  pass "2.06 No recent branch protection changes detected"
fi

increment_applied
summary
