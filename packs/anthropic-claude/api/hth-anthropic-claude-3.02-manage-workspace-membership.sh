#!/usr/bin/env bash
# HTH Anthropic Claude Control 3.2: Manage Workspace Membership
# Profile: L1 | NIST: AC-2, AC-6 | SOC 2: CC6.2, CC6.3
# https://howtoharden.com/guides/anthropic-claude/#32-manage-workspace-membership
source "$(dirname "$0")/common.sh"

banner "3.2: Manage Workspace Membership"
require_admin_key

# HTH Guide Excerpt: begin api-audit-workspace-members
# Audit membership for a specific workspace
# Usage: Set WORKSPACE_ID before running
WORKSPACE_ID="${WORKSPACE_ID:-}"
if [[ -z "${WORKSPACE_ID}" ]]; then
  info "Listing all workspaces to select for audit..."
  WORKSPACES=$(anthropic_list_all "/v1/organizations/workspaces") || {
    fail "3.2 Failed to list workspaces"
    summary; exit 0
  }
  echo "${WORKSPACES}" | jq -r '.[] | "  \(.id)\t\(.display_name)"' | column -t -s $'\t'
  info "Set WORKSPACE_ID=<id> and re-run to audit a specific workspace"
  summary; exit 0
fi

info "Auditing members of workspace ${WORKSPACE_ID}..."
MEMBERS=$(anthropic_list_all "/v1/organizations/workspaces/${WORKSPACE_ID}/members") || {
  fail "3.2 Failed to list workspace members"
  summary; exit 0
}

MEMBER_COUNT=$(echo "${MEMBERS}" | jq 'length')
info "Workspace has ${MEMBER_COUNT} members"

# List members with roles
echo "${MEMBERS}" | jq -r '.[] | "  \(.user_id)\t\(.workspace_role)"' | \
  column -t -s $'\t' -N "USER_ID,ROLE"

# Flag workspace admins
ADMIN_COUNT=$(echo "${MEMBERS}" | jq '[.[] | select(.workspace_role == "workspace_admin")] | length')
if [[ "${ADMIN_COUNT}" -gt 2 ]]; then
  warn "3.2 ${ADMIN_COUNT} workspace admins found — review for least privilege"
else
  pass "3.2 Workspace admin count (${ADMIN_COUNT}) is appropriate"
fi
# HTH Guide Excerpt: end api-audit-workspace-members

# HTH Guide Excerpt: begin api-remove-workspace-member
# Remove a user from a workspace
# Usage: Set WORKSPACE_ID and REMOVE_USER_ID before running
if [[ -n "${REMOVE_USER_ID:-}" ]]; then
  info "Removing user ${REMOVE_USER_ID} from workspace ${WORKSPACE_ID}..."
  anthropic_delete "/v1/organizations/workspaces/${WORKSPACE_ID}/members/${REMOVE_USER_ID}" || {
    fail "3.2 Failed to remove workspace member"
    summary; exit 0
  }
  pass "3.2 User ${REMOVE_USER_ID} removed from workspace"
fi
# HTH Guide Excerpt: end api-remove-workspace-member

summary
