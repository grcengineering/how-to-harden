#!/usr/bin/env bash
# HTH Pack Contract: v1
#   control: openai-api-5.4
#   guide: https://howtoharden.com/guides/openai-api/#54-gate-cyber-access-by-project-and-explicit-request
#   profile: L2
#   mode: read-only
#   requires: OPENAI_ADMIN_KEY, OPENAI_ORG_ID, OPENAI_EXTERNAL_STORAGE_ID, curl, jq
# Source: https://developers.openai.com/api/docs/guides/private-safety-processing
# NIST 800-53 CA-7, SI-12. Saved status only; does not run storage validation.
source "$(dirname "$0")/common.sh"
openai_require_admin
: "${OPENAI_ORG_ID:?Set the intended organization ID}"
: "${OPENAI_EXTERNAL_STORAGE_ID:?Set the saved PSP storage registration ID}"
[[ "$OPENAI_ORG_ID" =~ ^[A-Za-z0-9_-]+$ && "$OPENAI_EXTERNAL_STORAGE_ID" =~ ^extstorage_[A-Za-z0-9_-]+$ ]] || exit 2
# HTH Guide Excerpt: begin read-psp-status
registration=$(openai_get "/organization/external_storage/${OPENAI_EXTERNAL_STORAGE_ID}" \
  -H "OpenAI-Organization: ${OPENAI_ORG_ID}")
jq -ce --arg expected "$OPENAI_EXTERNAL_STORAGE_ID" '
  if .id == $expected and (.status == "pending" or .status == "validated" or .status == "unhealthy")
  then {id, status, saved_state_only:true, review_required:(.status != "validated")}
  else error("Unexpected storage registration") end' <<<"$registration"
# Omit bucket destinations, identities and cloud connection details.
# Validated records a past check; it is not continuous connectivity evidence.
# Refresh/GET does not validate storage or activate PSP.
# HTH Guide Excerpt: end read-psp-status
