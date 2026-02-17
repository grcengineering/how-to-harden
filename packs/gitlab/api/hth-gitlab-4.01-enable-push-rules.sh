#!/usr/bin/env bash
# HTH GitLab Control 4.1: Enable Push Rules
# Profile: L1 (prevent_secrets, deny_delete_tag), L2 (reject_unsigned_commits)
# NIST: CM-3, SI-7 | SOC 2: CC8.1
# https://howtoharden.com/guides/gitlab/#41-enable-push-rules
#
# Required: PROJECT_ID environment variable (or pass as $1)
source "$(dirname "$0")/common.sh"

PROJECT_ID="${PROJECT_ID:-${1:-}}"
: "${PROJECT_ID:?Set PROJECT_ID or pass as first argument}"

banner "4.1: Enable Push Rules (Project: ${PROJECT_ID})"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "4.1 Checking push rules for project ${PROJECT_ID}..."

# Check if push rules already exist (idempotent)
EXISTING=$(gl_get "/projects/${PROJECT_ID}/push_rule" 2>/dev/null || echo "")

if [ -n "${EXISTING}" ] && [ "${EXISTING}" != "null" ]; then
  PREVENT_SECRETS=$(echo "${EXISTING}" | jq -r '.prevent_secrets // false' 2>/dev/null)
  DENY_DELETE_TAG=$(echo "${EXISTING}" | jq -r '.deny_delete_tag // false' 2>/dev/null)
  REJECT_UNSIGNED=$(echo "${EXISTING}" | jq -r '.reject_unsigned_commits // false' 2>/dev/null)

  info "4.1 Current push rules: prevent_secrets=${PREVENT_SECRETS}, deny_delete_tag=${DENY_DELETE_TAG}, reject_unsigned_commits=${REJECT_UNSIGNED}"

  # Check if L1 rules are already met
  if [ "${PREVENT_SECRETS}" == "true" ] && [ "${DENY_DELETE_TAG}" == "true" ]; then
    if should_apply 2 2>/dev/null; then
      if [ "${REJECT_UNSIGNED}" == "true" ]; then
        pass "4.1 All push rules already configured (L1 + L2)"
        increment_applied
        summary
        exit 0
      fi
    else
      pass "4.1 L1 push rules already configured"
      increment_applied
      summary
      exit 0
    fi
  fi
fi

# HTH Guide Excerpt: begin api-configure-push-rules
# Configure push rules: L1 enables prevent_secrets and deny_delete_tag;
# L2 additionally enables reject_unsigned_commits for commit signing enforcement.
info "4.1 Configuring push rules..."

PAYLOAD='{
  "prevent_secrets": true,
  "deny_delete_tag": true'

# L2: Add reject_unsigned_commits
if should_apply 2 2>/dev/null; then
  info "4.1 L2: Enabling reject_unsigned_commits (commit signing required)"
  PAYLOAD="${PAYLOAD}"',"reject_unsigned_commits": true'
fi

PAYLOAD="${PAYLOAD}"'}'

if [ -n "${EXISTING}" ] && [ "${EXISTING}" != "null" ]; then
  # Update existing push rules
  RESULT=$(gl_put "/projects/${PROJECT_ID}/push_rule" "${PAYLOAD}" 2>/dev/null) || {
    fail "4.1 Failed to update push rules"
    increment_failed
    summary
    exit 0
  }
else
  # Create new push rules
  RESULT=$(gl_post "/projects/${PROJECT_ID}/push_rule" "${PAYLOAD}" 2>/dev/null) || {
    fail "4.1 Failed to create push rules"
    increment_failed
    summary
    exit 0
  }
fi
# HTH Guide Excerpt: end api-configure-push-rules

# Verify the change
VERIFY=$(gl_get "/projects/${PROJECT_ID}/push_rule" 2>/dev/null || echo "{}")
V_SECRETS=$(echo "${VERIFY}" | jq -r '.prevent_secrets // false' 2>/dev/null)
V_DELETE=$(echo "${VERIFY}" | jq -r '.deny_delete_tag // false' 2>/dev/null)
V_UNSIGNED=$(echo "${VERIFY}" | jq -r '.reject_unsigned_commits // false' 2>/dev/null)

if [ "${V_SECRETS}" == "true" ] && [ "${V_DELETE}" == "true" ]; then
  pass "4.1 Push rules configured: prevent_secrets=${V_SECRETS}, deny_delete_tag=${V_DELETE}, reject_unsigned_commits=${V_UNSIGNED}"
  increment_applied
else
  fail "4.1 Push rules verification failed"
  increment_failed
fi

summary
