#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: langchain-1.2
#   guide:   https://howtoharden.com/guides/langchain/#12-use-workspace-scoped-service-keys-not-personal-access-tokens
#   profile: L1
#   mode:    mutating
#   requires: LANGSMITH_API_KEY(organization-scoped service key with Organization Admin; the default audit only reads), LANGSMITH_ORGANIZATION_ID, LANGSMITH_WORKSPACE_ID(create only), LANGSMITH_CALLER_KEY_ID(revoke-stale: required; audit: exempts the calling org-scoped key from the scope check), LANGSMITH_API_URL(optional)
# =============================================================================
# HTH LangChain Control 1.2: Use Workspace-Scoped Service Keys, Not Personal Access Tokens
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 5.6 | NIST 800-53 IA-5, AC-2(7)
# Dependencies: curl, jq
#
# Usage:
#   LANGSMITH_CALLER_KEY_ID=<id of this key> bash hth-langchain-1.2-manage-api-keys.sh   # read-only audit (default)
#   bash hth-langchain-1.2-manage-api-keys.sh create <description> <RFC3339 expiry>
#   bash hth-langchain-1.2-manage-api-keys.sh revoke-stale [--confirm]
#
# WHY `mode: mutating` WHEN THE DEFAULT ONLY READS. The sync keeps one api/ file per
# control, so the audit and the two write branches share this file. `create` and
# `revoke-stale --confirm` change organization state; they never fire unless named.
#
# Source of every path and field: https://api.smith.langchain.com/openapi.json and
# https://docs.langchain.com/langsmith/manage-organization-by-api
#   GET    /api/v1/orgs/current/service-keys            -> APIKeyGetResponse[] (access_scope, workspace_names, expires_at, last_used_at, revoked_at)
#   GET    /api/v1/orgs/current/info                    -> OrganizationInfo (pat_creation_disabled, max_service_key_expiry_days)
#   POST   /api/v1/api-key  + X-Tenant-Id               -> APIKeyCreateResponse ("key" is shown once); body APIKeyCreateRequest
#   DELETE /api/v1/orgs/current/service-keys/{id}       ("Delete Org Service Key")
#
# TRAPS
#  1. There is no /api/v1/api-keys route (it 404s). Service keys live under
#     /api/v1/orgs/current/service-keys; workspace-context keys under /api/v1/api-key.
#  2. There is no `is_service_key` or `type` field. A service key's reach is its
#     `access_scope` ("organization" | "workspace"). Keys start `lsv2_sk_`; the
#     `ls__` prefix was retired on 2024-10-22.
#  3. `last_used_at` is null for a key that has never been used. In jq, null sorts
#     before every string, so `.last_used_at < $cutoff` would select a key minted a
#     minute ago. Staleness here is measured from last use, or from creation when
#     the key was never used.
#  4. Revoking the key this script authenticates with locks the automation out.
#     revoke-stale refuses to run without LANGSMITH_CALLER_KEY_ID and never
#     selects that id.
#  5. The org routes this script reads need an organization-scoped key, and the
#     service-keys list includes that key. An audit that fails every org-scoped
#     key therefore fails every org it is run against. Name the caller in
#     LANGSMITH_CALLER_KEY_ID; it is exempt from the scope check only.

set -euo pipefail

: "${LANGSMITH_API_KEY:?Set LANGSMITH_API_KEY (Organization Admin service key)}"
: "${LANGSMITH_ORGANIZATION_ID:?Set LANGSMITH_ORGANIZATION_ID}"
: "${LANGSMITH_API_URL:=https://api.smith.langchain.com}"

# HTH Guide Excerpt: begin api-audit-service-keys
# Read-only: every active service key must be workspace-scoped and must expire. The one
# exception is the organization-scoped key running this audit (org routes need one): name
# it in LANGSMITH_CALLER_KEY_ID and it is exempt from the scope check, never the expiry check.
audit() {
  local keys org findings self="${LANGSMITH_CALLER_KEY_ID:-}"
  keys=$(curl -sf "${LANGSMITH_API_URL}/api/v1/orgs/current/service-keys" \
    -H "X-API-Key: ${LANGSMITH_API_KEY}" \
    -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}")
  org=$(curl -sf "${LANGSMITH_API_URL}/api/v1/orgs/current/info" \
    -H "X-API-Key: ${LANGSMITH_API_KEY}" \
    -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}")
  printf '%s' "${keys}" | jq -e 'type == "array"' > /dev/null   # fail closed on an unexpected shape

  printf '%s' "${keys}" | jq -c '.[] | select(.revoked_at == null)
    | {id, description, access_scope, workspace_names, expires_at, last_used_at}'
  printf '%s' "${org}" | jq -c '{pat_creation_disabled, max_service_key_expiry_days}'
  if [ -n "${self}" ]; then
    echo "exempt from the scope check (the key running this audit): ${self}"
  else
    echo "note: LANGSMITH_CALLER_KEY_ID is unset, so an organization-scoped key running this audit counts as a finding"
  fi

  findings=$(printf '%s' "${keys}" | jq --arg self "${self}" '[.[] | select(.revoked_at == null)
    | select((.access_scope != "workspace" and .id != $self) or .expires_at == null)] | length')
  echo "active service keys that are org-scoped or never expire: ${findings}"
  [ "${findings}" -eq 0 ]
}
# HTH Guide Excerpt: end api-audit-service-keys

# HTH Guide Excerpt: begin api-create-service-key
# Mutating: mint a workspace-scoped, expiring service key. The secret is written to a
# 0600 file for your secrets manager and never printed; LangSmith shows it only once.
create() {
  local description="$1" expires_at="$2" resp
  : "${LANGSMITH_WORKSPACE_ID:?Set LANGSMITH_WORKSPACE_ID (the one workspace this key may use)}"
  resp=$(curl -sf -X POST "${LANGSMITH_API_URL}/api/v1/api-key" \
    -H "X-API-Key: ${LANGSMITH_API_KEY}" \
    -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}" \
    -H "X-Tenant-Id: ${LANGSMITH_WORKSPACE_ID}" \
    -H "Content-Type: application/json" \
    -d "$(jq -nc --arg d "${description}" --arg e "${expires_at}" '{description: $d, expires_at: $e}')")
  (umask 077; printf '%s' "${resp}" | jq -er '.key' > "${description}.lsv2_sk.secret")
  printf '%s' "${resp}" | jq -c '{id, short_key, access_scope, workspace_names, expires_at}'
  echo "secret written to ./${description}.lsv2_sk.secret - move it into your secrets manager, then delete the file"
}
# HTH Guide Excerpt: end api-create-service-key

# HTH Guide Excerpt: begin api-revoke-stale-keys
# Mutating with --confirm: revoke service keys idle for 90+ days. Never the caller's key.
revoke_stale() {
  local confirm="${1:-}" cutoff keys candidates key_id
  : "${LANGSMITH_CALLER_KEY_ID:?Set LANGSMITH_CALLER_KEY_ID to the id of the key running this script}"
  cutoff=$(date -u -v-90d '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '90 days ago' '+%Y-%m-%dT%H:%M:%SZ')
  keys=$(curl -sf "${LANGSMITH_API_URL}/api/v1/orgs/current/service-keys" \
    -H "X-API-Key: ${LANGSMITH_API_KEY}" \
    -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}")
  candidates=$(printf '%s' "${keys}" | jq -r --arg cutoff "${cutoff}" --arg self "${LANGSMITH_CALLER_KEY_ID}" '
    if type != "array" then error("service-keys: expected an array") else . end
    | .[] | select(.revoked_at == null and .id != $self)
    | select((.last_used_at // .created_at // $cutoff) < $cutoff) | .id')
  if [ -z "${candidates}" ]; then echo "no service keys idle since ${cutoff}"; return 0; fi
  while IFS= read -r key_id; do
    if [ "${confirm}" = "--confirm" ]; then
      curl -sf -X DELETE "${LANGSMITH_API_URL}/api/v1/orgs/current/service-keys/${key_id}" \
        -H "X-API-Key: ${LANGSMITH_API_KEY}" \
        -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}" > /dev/null
      echo "revoked stale key: ${key_id}"
    else
      echo "would revoke (re-run with --confirm): ${key_id}"
    fi
  done < <(printf '%s\n' "${candidates}")
}
# HTH Guide Excerpt: end api-revoke-stale-keys

case "${1:-audit}" in
  audit)        audit ;;
  create)       create "${2:?description required, e.g. ci-pipeline-prod}" "${3:?RFC3339 expiry required, e.g. 2026-12-31T00:00:00Z}" ;;
  revoke-stale) revoke_stale "${2:-}" ;;
  *)            echo "usage: $0 [audit | create <description> <expires_at> | revoke-stale [--confirm]]" >&2; exit 2 ;;
esac
