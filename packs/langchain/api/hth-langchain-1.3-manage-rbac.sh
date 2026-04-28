#!/usr/bin/env bash
# HTH LangChain Control 1.3: Enforce RBAC + ABAC on LangSmith
# Profile: L2 | NIST: AC-3, AC-6
# https://howtoharden.com/guides/langchain/#13-enforce-rbac-abac
#
# RBAC requires LangSmith Enterprise plan.
# LangSmith REST API: api.smith.langchain.com

set -euo pipefail

: "${LANGSMITH_API_KEY:?Set LANGSMITH_API_KEY (org admin)}"
: "${LANGSMITH_API_URL:=https://api.smith.langchain.com}"
: "${LANGSMITH_WORKSPACE_ID:?Set LANGSMITH_WORKSPACE_ID}"

# HTH Guide Excerpt: begin api-list-roles
# List all custom roles in the workspace
curl -sf "${LANGSMITH_API_URL}/api/v1/orgs/current/workspaces/${LANGSMITH_WORKSPACE_ID}/roles" \
  -H "X-API-Key: ${LANGSMITH_API_KEY}" | \
  jq '.[] | {id, name, description, permissions: [.permissions[] | .resource + ":" + .action]}'
# HTH Guide Excerpt: end api-list-roles

# HTH Guide Excerpt: begin api-create-readonly-role
# Create a read-only "Auditor" role (least-privilege)
curl -sf -X POST "${LANGSMITH_API_URL}/api/v1/orgs/current/workspaces/${LANGSMITH_WORKSPACE_ID}/roles" \
  -H "X-API-Key: ${LANGSMITH_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Auditor",
    "description": "Read-only access to traces, runs, and audit logs",
    "permissions": [
      {"resource": "trace", "action": "read"},
      {"resource": "run", "action": "read"},
      {"resource": "audit_log", "action": "read"}
    ]
  }'
# HTH Guide Excerpt: end api-create-readonly-role

# HTH Guide Excerpt: begin api-list-user-role-assignments
# List role assignments for all users in the workspace
curl -sf "${LANGSMITH_API_URL}/api/v1/orgs/current/workspaces/${LANGSMITH_WORKSPACE_ID}/members" \
  -H "X-API-Key: ${LANGSMITH_API_KEY}" | \
  jq '.[] | {user_email: .email, role: .role.name, assigned_at: .created_at}'
# HTH Guide Excerpt: end api-list-user-role-assignments
