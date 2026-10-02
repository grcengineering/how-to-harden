#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: langchain-1.3
#   guide:   https://howtoharden.com/guides/langchain/#13-enforce-rbac-and-abac-for-project--dataset-access
#   profile: L2
#   mode:    mutating
#   requires: LANGSMITH_API_KEY(Organization Admin service key or PAT; Enterprise plan; the default audit only reads), LANGSMITH_ORGANIZATION_ID, LANGSMITH_WORKSPACE_ID, LANGSMITH_API_URL(optional)
# =============================================================================
# HTH LangChain Control 1.3: Enforce RBAC and ABAC for Project / Dataset Access
# Profile Level: L2 (Walk)
# Frameworks: CIS Controls 6.8 | NIST 800-53 AC-3, AC-6
# Dependencies: curl, jq
#
# Usage:
#   bash hth-langchain-1.3-manage-rbac.sh                  # read-only audit (default)
#   bash hth-langchain-1.3-manage-rbac.sh create-auditor   # mutating: create a read-only custom role
#
# WHY `mode: mutating` WHEN THE DEFAULT ONLY READS. One api/ file per control, so the
# role-creation branch lives beside the audit. It never fires unless named.
#
# Source of every path and field: https://api.smith.langchain.com/openapi.json,
# https://docs.langchain.com/langsmith/manage-organization-by-api and .../langsmith/abac
#   GET  /api/v1/orgs/current/roles                    -> Role[] (display_name, access_scope, permissions: string[])
#   POST /api/v1/orgs/current/roles                    <- CreateRoleRequest {display_name, description, permissions: string[]}
#   GET  /api/v1/workspaces/current/members + X-Tenant-Id -> TenantMembers {tenant_id, members[], pending[]}
#   GET  /api/v1/platform/orgs/current/access-policies -> {access_policies: [...]} (ABAC; policies are API/Terraform only)
#
# TRAPS
#  1. There are no /orgs/current/workspaces/{id}/roles or /members routes (both 404).
#     Roles are organization-level; the workspace is chosen with the X-Tenant-Id header.
#  2. Permissions are `<resource>:<action>` strings (projects:read, runs:read, ...),
#     not {resource, action} objects. Custom roles take workspace-level permissions only.
#  3. The members response is an object, not an array: iterate `.members[]`.

set -euo pipefail

: "${LANGSMITH_API_KEY:?Set LANGSMITH_API_KEY (Organization Admin service key)}"
: "${LANGSMITH_ORGANIZATION_ID:?Set LANGSMITH_ORGANIZATION_ID}"
: "${LANGSMITH_WORKSPACE_ID:?Set LANGSMITH_WORKSPACE_ID}"
: "${LANGSMITH_API_URL:=https://api.smith.langchain.com}"

# HTH Guide Excerpt: begin api-audit-roles-and-members
# Read-only: roles and their permissions, who holds which role, and the ABAC policies.
audit() {
  local roles members policies
  roles=$(curl -sf "${LANGSMITH_API_URL}/api/v1/orgs/current/roles" \
    -H "X-API-Key: ${LANGSMITH_API_KEY}" \
    -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}")
  members=$(curl -sf "${LANGSMITH_API_URL}/api/v1/workspaces/current/members" \
    -H "X-API-Key: ${LANGSMITH_API_KEY}" \
    -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}" \
    -H "X-Tenant-Id: ${LANGSMITH_WORKSPACE_ID}")
  policies=$(curl -sf "${LANGSMITH_API_URL}/api/v1/platform/orgs/current/access-policies" \
    -H "X-API-Key: ${LANGSMITH_API_KEY}" \
    -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}")

  echo "== roles"
  printf '%s' "${roles}" | jq -c 'if type != "array" then error("roles: expected an array") else .[] end
    | {display_name, access_scope, permissions}'
  echo "== workspace members by role"
  printf '%s' "${members}" | jq -c '.members | if type != "array" then error("members: expected .members[]") else . end
    | group_by(.role_name) | map({role: .[0].role_name, count: length})'
  echo "== ABAC access policies"
  printf '%s' "${policies}" | jq -c '.access_policies // error("access-policies: expected .access_policies")
    | .[] | {name, effect, role_ids, condition_groups}'
}
# HTH Guide Excerpt: end api-audit-roles-and-members

# HTH Guide Excerpt: begin api-create-readonly-role
# Mutating: create a read-only "Auditor" custom role (Enterprise; Organization Admin only).
create_auditor() {
  curl -sf -X POST "${LANGSMITH_API_URL}/api/v1/orgs/current/roles" \
    -H "X-API-Key: ${LANGSMITH_API_KEY}" \
    -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}" \
    -H "Content-Type: application/json" \
    -d '{
      "display_name": "Auditor",
      "description": "Read-only reviewer: traces, runs, datasets and prompts",
      "permissions": ["projects:read", "runs:read", "datasets:read", "prompts:read"]
    }' | jq -c '{id, display_name, permissions}'
}
# HTH Guide Excerpt: end api-create-readonly-role

case "${1:-audit}" in
  audit)          audit ;;
  create-auditor) create_auditor ;;
  *)              echo "usage: $0 [audit | create-auditor]" >&2; exit 2 ;;
esac
