#!/usr/bin/env bash
# HTH GitHub Control 1.06: Restrict Org Member Repository Deletion
# Profile: L3 | NIST: AC-6, MP-6
# https://howtoharden.com/guides/github/#16-restrict-org-member-repository-deletion
source "$(dirname "$0")/common.sh"

banner "1.06: Restrict Org Member Repository Deletion"
should_apply 3 || { increment_skipped; summary; exit 0; }
info "1.06 Checking repository creation and deletion restrictions..."

# Idempotency check -- verify members cannot create repos and default perm is restricted
ORG_DATA=$(gh_get "/orgs/${GITHUB_ORG}") || {
  fail "1.06 Unable to retrieve org settings for ${GITHUB_ORG}"
  increment_failed
  summary
  exit 0
}

CAN_CREATE=$(echo "${ORG_DATA}" | jq -r '.members_can_create_repositories // "unknown"')
DEFAULT_PERM=$(echo "${ORG_DATA}" | jq -r '.default_repository_permission // "unknown"')

COMPLIANT=true
if [ "${CAN_CREATE}" != "false" ]; then
  warn "1.06 Members can create repositories (current: ${CAN_CREATE})"
  COMPLIANT=false
fi
if [ "${DEFAULT_PERM}" != "read" ] && [ "${DEFAULT_PERM}" != "none" ]; then
  warn "1.06 Default permission is '${DEFAULT_PERM}' (expected 'read' or 'none')"
  COMPLIANT=false
fi

if [ "${COMPLIANT}" = "true" ]; then
  pass "1.06 Repository deletion restricted (create: ${CAN_CREATE}, default perm: ${DEFAULT_PERM})"
  increment_applied
  summary
  exit 0
fi

# HTH Guide Excerpt: begin api-restrict-repo-deletion
# Restrict repository creation and set default permission to read-only
info "1.06 Restricting repository creation and default permissions..."
RESPONSE=$(gh_patch "/orgs/${GITHUB_ORG}" '{
  "default_repository_permission": "read",
  "members_can_create_repositories": false
}') || {
  fail "1.06 Failed to restrict repository creation and permissions"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end api-restrict-repo-deletion

R_CREATE=$(echo "${RESPONSE}" | jq -r '.members_can_create_repositories // "unknown"')
R_PERM=$(echo "${RESPONSE}" | jq -r '.default_repository_permission // "unknown"')

if [ "${R_CREATE}" = "false" ] && { [ "${R_PERM}" = "read" ] || [ "${R_PERM}" = "none" ]; }; then
  pass "1.06 Repository deletion restricted (create: ${R_CREATE}, default perm: ${R_PERM})"
  increment_applied
else
  fail "1.06 Repository restrictions not confirmed after update"
  increment_failed
fi

summary
