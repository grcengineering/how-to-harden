#!/usr/bin/env bash
# HTH GitHub Control 4.04: Audit OAuth App Access
# Profile: L1 | NIST: AC-6, AC-17
# https://howtoharden.com/guides/github/#41-audit-and-restrict-oauth-app-access
source "$(dirname "$0")/common.sh"

banner "4.04: Audit OAuth Apps"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.04 Auditing OAuth app access for ${GITHUB_ORG}..."

# HTH Guide Excerpt: begin api-list-oauth-apps
# List organization authorized OAuth apps
info "4.04 Listing authorized OAuth apps for ${GITHUB_ORG}..."
APPS=$(gh_get "/orgs/${GITHUB_ORG}/installations") || {
  warn "4.04 Unable to retrieve app list (may require admin scope)"
}
echo "${APPS}" | jq '.installations[] | {app: .app_slug, permissions: .permissions, created_at: .created_at}'

# NOTE: The /applications endpoint was deprecated by GitHub in 2019.
# Use the Admin Console (Settings > OAuth Apps) to review personal OAuth authorizations.
# HTH Guide Excerpt: end api-list-oauth-apps

APP_COUNT=$(echo "${APPS}" | jq '.installations | length' 2>/dev/null || echo "0")
if [ "${APP_COUNT}" -gt 20 ]; then
  warn "4.04 ${APP_COUNT} OAuth apps authorized -- review and revoke unused apps"
fi

increment_applied
summary
