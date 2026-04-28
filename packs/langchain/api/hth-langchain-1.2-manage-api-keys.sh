#!/usr/bin/env bash
# HTH LangChain Control 1.2: Use Workspace-Scoped Service Keys, Not Personal Access Tokens
# Profile: L1 | NIST: IA-5, AC-2(7)
# https://howtoharden.com/guides/langchain/#12-use-workspace-scoped-service-keys
#
# LangSmith REST API: api.smith.langchain.com
# Auth header: X-API-Key: <ls__... key>

set -euo pipefail

: "${LANGSMITH_API_KEY:?Set LANGSMITH_API_KEY (workspace admin key)}"
: "${LANGSMITH_API_URL:=https://api.smith.langchain.com}"
: "${LANGSMITH_WORKSPACE_ID:?Set LANGSMITH_WORKSPACE_ID}"

# HTH Guide Excerpt: begin api-list-api-keys
# List all API keys in the workspace (Personal Access Tokens + Service Keys)
curl -sf "${LANGSMITH_API_URL}/api/v1/api-keys?workspace_id=${LANGSMITH_WORKSPACE_ID}" \
  -H "X-API-Key: ${LANGSMITH_API_KEY}" \
  -H "Accept: application/json" | \
  jq '.[] | {id, description, type, created_at, last_used_at, user_id}'
# HTH Guide Excerpt: end api-list-api-keys

# HTH Guide Excerpt: begin api-create-service-key
# Create a workspace-scoped Service Key (preferred for CI/CD and services)
curl -sf -X POST "${LANGSMITH_API_URL}/api/v1/api-keys" \
  -H "X-API-Key: ${LANGSMITH_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"description\": \"ci-pipeline-prod\",
    \"workspace_id\": \"${LANGSMITH_WORKSPACE_ID}\",
    \"is_service_key\": true
  }"
# HTH Guide Excerpt: end api-create-service-key

# HTH Guide Excerpt: begin api-revoke-stale-keys
# Revoke API keys not used in the last 90 days
NINETY_DAYS_AGO=$(date -u -v-90d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '90 days ago' '+%Y-%m-%dT%H:%M:%SZ')

curl -sf "${LANGSMITH_API_URL}/api/v1/api-keys?workspace_id=${LANGSMITH_WORKSPACE_ID}" \
  -H "X-API-Key: ${LANGSMITH_API_KEY}" | \
  jq -r --arg cutoff "${NINETY_DAYS_AGO}" \
    '.[] | select(.last_used_at < $cutoff) | .id' | \
  while read -r KEY_ID; do
    echo "Revoking stale key: ${KEY_ID}"
    curl -sf -X DELETE "${LANGSMITH_API_URL}/api/v1/api-keys/${KEY_ID}" \
      -H "X-API-Key: ${LANGSMITH_API_KEY}"
  done
# HTH Guide Excerpt: end api-revoke-stale-keys
