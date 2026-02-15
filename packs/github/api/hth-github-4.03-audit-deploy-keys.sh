#!/usr/bin/env bash
# HTH GitHub Control 4.03: Audit Deploy Keys
# Profile: L2 | NIST: AC-6, IA-5
# https://howtoharden.com/guides/github/#43-audit-deploy-keys
source "$(dirname "$0")/common.sh"

banner "4.03: Audit Deploy Keys (Audit Only)"
should_apply 2 || { increment_skipped; summary; exit 0; }

REPO="${GITHUB_REPO:-how-to-harden}"
info "4.03 Auditing deploy keys on ${GITHUB_ORG}/${REPO}..."

# HTH Guide Excerpt: begin api-audit-deploy-keys
# Audit: Check for deploy keys with write access (read_only == false)
KEYS=$(gh_get "/repos/${GITHUB_ORG}/${REPO}/keys") || {
  fail "4.03 Unable to retrieve deploy keys for ${GITHUB_ORG}/${REPO}"
  increment_failed
  summary
  exit 0
}

TOTAL_KEYS=$(echo "${KEYS}" | jq '. | length' 2>/dev/null || echo "0")
WRITE_KEYS=$(echo "${KEYS}" | jq '[.[] | select(.read_only == false)] | length' 2>/dev/null || echo "0")
READ_KEYS=$((TOTAL_KEYS - WRITE_KEYS))

info "4.03 Found ${TOTAL_KEYS} deploy key(s): ${READ_KEYS} read-only, ${WRITE_KEYS} read-write"

# List write-access keys for review
if [ "${WRITE_KEYS}" -gt 0 ]; then
  warn "4.03 Deploy keys with WRITE access (review required):"
  echo "${KEYS}" | jq -r '.[] | select(.read_only == false) | "  ID: \(.id) | Title: \(.title) | Created: \(.created_at)"' 2>/dev/null
fi
# HTH Guide Excerpt: end api-audit-deploy-keys

if [ "${WRITE_KEYS}" = "0" ]; then
  pass "4.03 No deploy keys with write access found"
  increment_applied
else
  warn "4.03 ${WRITE_KEYS} deploy key(s) have write access -- manual review required"
  warn "4.03 Convert write keys to read-only unless write access is explicitly required"
  increment_failed
fi

summary
