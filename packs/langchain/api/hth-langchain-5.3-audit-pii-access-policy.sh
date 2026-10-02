#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: langchain-5.3
#   guide:   https://howtoharden.com/guides/langchain/#53-restrict-trace-project-access
#   profile: L2
#   mode:    read-only
#   requires: LANGSMITH_API_KEY(Organization Admin service key or PAT; Enterprise plan), LANGSMITH_ORGANIZATION_ID, HTH_PII_TAG_KEY(optional, default data-class), HTH_PII_TAG_VALUE(optional, default pii), LANGSMITH_API_URL(optional)
# =============================================================================
# HTH LangChain Control 5.3: Restrict Trace Project Access
# Profile Level: L2 (Walk)
# Frameworks: NIST 800-53 AC-3 | SOC 2 CC6.3
# Dependencies: curl, jq
#
# Read-only verification that an ABAC deny policy covers PII-tagged tracing projects.
# The enforcement half is the Terraform pack for this control
# (terraform/hth-langchain-5.3-restrict-pii-projects.tf).
#
# Source: https://docs.langchain.com/langsmith/abac (policy structure; `resource_tag_key`
# is the only supported attribute_name; deny always wins) and
# https://api.smith.langchain.com/openapi.json
#   GET /api/v1/platform/orgs/current/access-policies -> {access_policies: AccessPolicy[]}

set -euo pipefail

: "${LANGSMITH_API_KEY:?Set LANGSMITH_API_KEY (Organization Admin service key)}"
: "${LANGSMITH_ORGANIZATION_ID:?Set LANGSMITH_ORGANIZATION_ID}"
: "${LANGSMITH_API_URL:=https://api.smith.langchain.com}"
: "${HTH_PII_TAG_KEY:=data-class}"
: "${HTH_PII_TAG_VALUE:=pii}"

# HTH Guide Excerpt: begin api-audit-pii-project-policy
# Read-only: at least one attached deny policy must block projects:read on the PII tag.
POLICIES=$(curl -sf "${LANGSMITH_API_URL}/api/v1/platform/orgs/current/access-policies" \
  -H "X-API-Key: ${LANGSMITH_API_KEY}" \
  -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}")

MATCHING=$(printf '%s' "${POLICIES}" | jq -c --arg k "${HTH_PII_TAG_KEY}" --arg v "${HTH_PII_TAG_VALUE}" '
  (.access_policies // error("access-policies: expected .access_policies"))
  | [ .[] | select(.effect == "deny" and ((.role_ids // []) | length) > 0)
      | select(any(.condition_groups[]?;
          .resource_type == "project" and .permission == "projects:read" and
          any(.conditions[]?; .attribute_name == "resource_tag_key" and .attribute_key == $k
                              and (.operator | startswith("equals")) and .attribute_value == $v)))
      | {name, role_ids} ]')

echo "deny policies on projects tagged ${HTH_PII_TAG_KEY}=${HTH_PII_TAG_VALUE}: ${MATCHING}"
if [ "$(printf '%s' "${MATCHING}" | jq 'length')" -lt 1 ]; then
  echo "FAIL: no attached deny policy restricts PII-tagged tracing projects"
  exit 1
fi
echo "PASS: PII-tagged projects are restricted by an attached ABAC deny policy"
# HTH Guide Excerpt: end api-audit-pii-project-policy
