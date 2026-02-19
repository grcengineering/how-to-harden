#!/usr/bin/env bash
# HTH GitHub Control 1.08: Audit Admin Access
# Profile: L1 | NIST: AC-2(4), AU-12
# https://howtoharden.com/guides/github/#14-configure-admin-access-controls
source "$(dirname "$0")/common.sh"

banner "1.08: Audit Admin Access"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.08 Auditing admin access for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-audit-admins
# List organization admins
info "1.08 Listing organization admins for ${GITHUB_ORG}..."
ADMINS=$(gh_get "/orgs/${GITHUB_ORG}/members?role=admin") || {
  fail "1.08 Unable to retrieve admin list"
  increment_failed
  summary
  exit 0
}

ADMIN_COUNT=$(echo "${ADMINS}" | jq '. | length')
echo "${ADMINS}" | jq -r '.[].login'
info "1.08 Found ${ADMIN_COUNT} admin(s)"

# Audit admin actions in audit log
info "1.08 Checking recent admin role changes..."
gh_get "/orgs/${GITHUB_ORG}/audit-log?phrase=action:org.update_member" \
  | jq '.[] | {actor: .actor, action: .action, created_at: .created_at}'
# HTH Guide Excerpt: end api-audit-admins

if [ "${ADMIN_COUNT}" -gt 5 ]; then
  warn "1.08 ${ADMIN_COUNT} admins found -- review and reduce to minimum necessary"
fi

increment_applied
summary
