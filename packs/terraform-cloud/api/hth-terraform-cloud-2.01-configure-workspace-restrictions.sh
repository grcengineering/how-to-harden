#!/usr/bin/env bash
# HTH Terraform Cloud Control 2.01: Configure Workspace Restrictions
# Profile: L1 | NIST: CM-3
# https://howtoharden.com/guides/terraform-cloud/#21-configure-workspace-restrictions
source "$(dirname "$0")/common.sh"

banner "2.01: Configure Workspace Restrictions"
should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.01 Auditing workspace settings..."

# HTH Guide Excerpt: begin api-audit-workspaces
# Fetch all workspaces in the organization
PAGE=1
TOTAL_WORKSPACES=0
AUTO_APPLY_VIOLATIONS=0
EXEC_MODE_VIOLATIONS=0

while true; do
  WS_RESPONSE=$(tfc_get "/organizations/${TFC_ORG}/workspaces?page%5Bnumber%5D=${PAGE}&page%5Bsize%5D=20") || {
    fail "2.01 Unable to retrieve workspaces for org ${TFC_ORG} (page ${PAGE})"
    increment_failed
    summary
    exit 0
  }

  WS_COUNT=$(echo "${WS_RESPONSE}" | jq '.data | length')
  if [ "${WS_COUNT}" = "0" ]; then
    break
  fi

  echo "${WS_RESPONSE}" | jq -r '.data[] | @base64' | while read -r WS_B64; do
    WS_JSON=$(echo "${WS_B64}" | base64 -d)
    WS_NAME=$(echo "${WS_JSON}" | jq -r '.attributes.name')
    AUTO_APPLY=$(echo "${WS_JSON}" | jq -r '.attributes."auto-apply" // false')
    EXEC_MODE=$(echo "${WS_JSON}" | jq -r '.attributes."execution-mode" // "remote"')
    SPECULATIVE=$(echo "${WS_JSON}" | jq -r '.attributes."speculative-enabled" // false')

    # Check auto-apply -- should be disabled for production workspaces
    if [ "${AUTO_APPLY}" = "true" ]; then
      fail "2.01 ${WS_NAME}: auto-apply is ENABLED -- disable for production workspaces"
      AUTO_APPLY_VIOLATIONS=$((AUTO_APPLY_VIOLATIONS + 1))
    else
      pass "2.01 ${WS_NAME}: auto-apply is disabled"
    fi

    # Check execution mode -- should be remote
    if [ "${EXEC_MODE}" != "remote" ]; then
      warn "2.01 ${WS_NAME}: execution mode is '${EXEC_MODE}' (expected 'remote')"
      EXEC_MODE_VIOLATIONS=$((EXEC_MODE_VIOLATIONS + 1))
    else
      pass "2.01 ${WS_NAME}: execution mode is remote"
    fi

    # Check speculative plans
    if [ "${SPECULATIVE}" != "true" ]; then
      warn "2.01 ${WS_NAME}: speculative plans are disabled -- enable for PR previews"
    fi

    TOTAL_WORKSPACES=$((TOTAL_WORKSPACES + 1))
  done

  # Check for next page
  NEXT_PAGE=$(echo "${WS_RESPONSE}" | jq -r '.meta.pagination."next-page" // empty')
  if [ -z "${NEXT_PAGE}" ]; then
    break
  fi
  PAGE=$((PAGE + 1))
done

info "2.01 Audited ${TOTAL_WORKSPACES} workspace(s)"

if [ "${AUTO_APPLY_VIOLATIONS}" -gt 0 ] || [ "${EXEC_MODE_VIOLATIONS}" -gt 0 ]; then
  fail "2.01 Found ${AUTO_APPLY_VIOLATIONS} auto-apply and ${EXEC_MODE_VIOLATIONS} execution mode violation(s)"
  increment_failed
else
  pass "2.01 All workspaces meet hardening requirements"
  increment_applied
fi
# HTH Guide Excerpt: end api-audit-workspaces

summary
