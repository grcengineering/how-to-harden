#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-api-1.2
#   guide: https://howtoharden.com/guides/openai-api/#12-govern-workload-identities-and-key-lifetimes
#   profile: L2
#   mode: read-only
#   requires: OPENAI_ADMIN_KEY, OPENAI_PROJECT_ID, curl, jq
# Source: https://developers.openai.com/api/reference/resources/admin/subresources/organization/subresources/projects/subresources/api_keys/methods/list
# NIST 800-53 IA-5. Values, redacted keys, names and emails are intentionally omitted.
source "$(dirname "$0")/common.sh"
openai_require_admin
: "${OPENAI_PROJECT_ID:?Set the project to assess}"
[[ "${OPENAI_PROJECT_ID}" =~ ^proj_[A-Za-z0-9_-]+$ ]] || exit 2
# HTH Guide Excerpt: begin key-expiration-audit
openai_list "/organization/projects/${OPENAI_PROJECT_ID}/api_keys" \
  --data-urlencode 'owner_project_access=any' |
  jq -c --argjson now "$(date +%s)" \
    '{id, owner_type: .owner.type, owner_project_access, created_at, expires_at,
      review_required: (.owner_project_access == "inactive" or .expires_at == null or .expires_at <= $now)}'
# Flags missing/expired lifetimes; it does not prove organization creation-policy
# enforcement or make a still-valid over-scoped key safe.
# owner_project_access=any includes enabled keys whose owners no longer have
# project access; the endpoint default can hide some of these enabled keys.
# HTH Guide Excerpt: end key-expiration-audit
