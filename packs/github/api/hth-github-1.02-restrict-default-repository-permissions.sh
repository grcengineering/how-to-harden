#!/usr/bin/env bash
# HTH GitHub Control 1.02: Restrict Default Repository Permissions
# Profile: L1 | NIST: AC-6, AC-6(1)
# https://howtoharden.com/guides/github/#12-restrict-default-repository-permissions
source "$(dirname "$0")/common.sh"

banner "1.02: Restrict Default Repository Permissions"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.02 Checking default repository permissions..."

# Idempotency check -- verify current default permission level
ORG_DATA=$(gh_get "/orgs/${GITHUB_ORG}") || {
  fail "1.02 Unable to retrieve org settings for ${GITHUB_ORG}"
  increment_failed
  summary
  exit 0
}

DEFAULT_PERM=$(echo "${ORG_DATA}" | jq -r '.default_repository_permission // "unknown"')

if [ "${DEFAULT_PERM}" = "read" ] || [ "${DEFAULT_PERM}" = "none" ]; then
  pass "1.02 Default repository permission is already '${DEFAULT_PERM}'"
  increment_applied
  summary
  exit 0
fi

warn "1.02 Default repository permission is '${DEFAULT_PERM}' (expected 'read' or 'none')"

# HTH Guide Excerpt: begin api-set-default-permissions
# Restrict default repository permission to read-only
info "1.02 Setting default repository permission to 'read'..."
RESPONSE=$(gh_patch "/orgs/${GITHUB_ORG}" '{
  "default_repository_permission": "read"
}') || {
  fail "1.02 Failed to set default repository permission"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-set-default-permissions

RESULT=$(echo "${RESPONSE}" | jq -r '.default_repository_permission // "unknown"')
if [ "${RESULT}" = "read" ]; then
  pass "1.02 Default repository permission set to 'read'"
  increment_applied
else
  fail "1.02 Default permission not confirmed as 'read' after update (got '${RESULT}')"
  increment_failed
fi

summary
