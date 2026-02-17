#!/usr/bin/env bash
# HTH Terraform Cloud Control 1.02: Team-Based Access Control
# Profile: L1 | NIST: AC-3, AC-6
# https://howtoharden.com/guides/terraform-cloud/#12-team-based-access-control
source "$(dirname "$0")/common.sh"

banner "1.02: Team-Based Access Control"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.02 Auditing team membership and permissions..."

# HTH Guide Excerpt: begin api-audit-teams
# Fetch all teams in the organization
TEAMS_RESPONSE=$(tfc_get "/organizations/${TFC_ORG}/teams") || {
  fail "1.02 Unable to retrieve teams for org ${TFC_ORG}"
  increment_failed
  summary
  exit 0
}

TEAM_COUNT=$(echo "${TEAMS_RESPONSE}" | jq '.data | length')
info "1.02 Found ${TEAM_COUNT} team(s) in organization ${TFC_ORG}"

# Audit each team's permissions
echo "${TEAMS_RESPONSE}" | jq -r '.data[] | @base64' | while read -r TEAM_B64; do
  TEAM_JSON=$(echo "${TEAM_B64}" | base64 -d)
  TEAM_NAME=$(echo "${TEAM_JSON}" | jq -r '.attributes.name')
  TEAM_ID=$(echo "${TEAM_JSON}" | jq -r '.id')
  MANAGE_WORKSPACES=$(echo "${TEAM_JSON}" | jq -r '.attributes."organization-access"."manage-workspaces" // false')
  MANAGE_POLICIES=$(echo "${TEAM_JSON}" | jq -r '.attributes."organization-access"."manage-policies" // false')
  MANAGE_VCS=$(echo "${TEAM_JSON}" | jq -r '.attributes."organization-access"."manage-vcs-settings" // false')

  info "1.02 Team: ${TEAM_NAME} (ID: ${TEAM_ID})"

  # Flag overly permissive teams
  if [ "${MANAGE_WORKSPACES}" = "true" ] && [ "${MANAGE_POLICIES}" = "true" ] && [ "${MANAGE_VCS}" = "true" ]; then
    warn "1.02   ${TEAM_NAME} has full org-level access -- review for least privilege"
  fi

  # Check team membership count
  MEMBERS_RESPONSE=$(tfc_get "/teams/${TEAM_ID}/memberships") || {
    warn "1.02   Unable to retrieve members for team ${TEAM_NAME}"
    continue
  }
  MEMBER_COUNT=$(echo "${MEMBERS_RESPONSE}" | jq '.data | length')
  info "1.02   Members: ${MEMBER_COUNT}"

  # Flag empty teams
  if [ "${MEMBER_COUNT}" = "0" ]; then
    warn "1.02   ${TEAM_NAME} has no members -- consider removing"
  fi

  # Check workspace-level access grants
  ACCESS_RESPONSE=$(tfc_get "/teams/${TEAM_ID}/team-workspaces") || {
    warn "1.02   Unable to retrieve workspace access for team ${TEAM_NAME}"
    continue
  }
  WORKSPACE_COUNT=$(echo "${ACCESS_RESPONSE}" | jq '.data | length')
  info "1.02   Workspace grants: ${WORKSPACE_COUNT}"

  # Flag admin access on many workspaces
  ADMIN_COUNT=$(echo "${ACCESS_RESPONSE}" | jq '[.data[] | select(.attributes.access == "admin")] | length')
  if [ "${ADMIN_COUNT}" -gt 5 ]; then
    warn "1.02   ${TEAM_NAME} has admin access on ${ADMIN_COUNT} workspaces -- review for least privilege"
  fi
done

pass "1.02 Team access audit complete"
increment_applied
# HTH Guide Excerpt: end api-audit-teams

summary
