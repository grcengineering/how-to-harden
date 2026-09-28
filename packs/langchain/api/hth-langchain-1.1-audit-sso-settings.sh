#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: langchain-1.1
#   guide:   https://howtoharden.com/guides/langchain/#11-enforce-saml-single-sign-on
#   profile: L1
#   mode:    read-only
#   requires: LANGSMITH_API_KEY(organization-scoped service key or PAT held by an Organization Admin; Enterprise plan), LANGSMITH_ORGANIZATION_ID, LANGSMITH_API_URL(optional; regional or self-hosted host)
# =============================================================================
# HTH LangChain Control 1.1: Enforce SAML Single Sign-On
# Profile Level: L1 (Crawl)
# Frameworks: CIS Controls 6.3, 12.5 | NIST 800-53 IA-2, IA-8
# Dependencies: curl, jq
#
# Read-only verification pack. Source of every path and field:
#   https://api.smith.langchain.com/openapi.json
#     GET /api/v1/orgs/current/sso-settings -> SSOProvider[]   ("Get Current Sso Settings")
#     GET /api/v1/orgs/current/info         -> OrganizationInfo ("Get Current Organization Info"),
#                                              field `sso_only` = the "Only SAML SSO" login-method setting
#   https://docs.langchain.com/langsmith/manage-organization-by-api
#     (X-Organization-Id belongs on every organization-management request)
#
# WHY THERE IS NO WRITE HALF. The API also exposes PATCH/DELETE on sso-settings and
# PATCH /api/v1/orgs/current/login-methods, and the community bogware/langsmith
# provider ships an sso_settings resource. A scripted SSO or login-method write is
# the one change in this guide that can lock every member out of the organization,
# and the vendor only lets you set "Only SAML SSO" while signed in through SAML SSO
# for exactly that reason. Configure SSO in the console (guide 1.1 ClickOps) and
# use this pack to prove it stayed configured.

set -euo pipefail

: "${LANGSMITH_API_KEY:?Set LANGSMITH_API_KEY (Organization Admin service key or PAT)}"
: "${LANGSMITH_ORGANIZATION_ID:?Set LANGSMITH_ORGANIZATION_ID}"
: "${LANGSMITH_API_URL:=https://api.smith.langchain.com}"

# HTH Guide Excerpt: begin api-audit-sso-settings
# Read-only: confirm a SAML provider exists AND login is restricted to SAML SSO.
SSO=$(curl -sf "${LANGSMITH_API_URL}/api/v1/orgs/current/sso-settings" \
  -H "X-API-Key: ${LANGSMITH_API_KEY}" \
  -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}")
ORG=$(curl -sf "${LANGSMITH_API_URL}/api/v1/orgs/current/info" \
  -H "X-API-Key: ${LANGSMITH_API_KEY}" \
  -H "X-Organization-Id: ${LANGSMITH_ORGANIZATION_ID}")

# Fail closed on an unexpected response shape instead of counting the wrong thing.
PROVIDERS=$(printf '%s' "${SSO}" | jq 'if type == "array" then length else error("sso-settings: expected an array") end')
SSO_ONLY=$(printf '%s' "${ORG}" | jq -r 'if type == "object" then (.sso_only | tostring) else error("orgs/current/info: expected an object") end')

printf '%s' "${SSO}" | jq -c '.[] | {provider_id,
  metadata: (if .metadata_url then "url" elif .metadata_xml then "xml" else "none" end),
  default_workspace_role_id, sso_groups_enabled, sso_groups_role_sync_enabled}'
echo "SAML providers configured: ${PROVIDERS}"
echo "login restricted to SAML SSO only (sso_only): ${SSO_ONLY}"

if [ "${PROVIDERS}" -lt 1 ] || [ "${SSO_ONLY}" != "true" ]; then
  echo "FAIL: SAML SSO is not both configured and enforced for this organization"
  exit 1
fi
echo "PASS: SAML SSO is configured and is the only allowed login method"
# HTH Guide Excerpt: end api-audit-sso-settings
