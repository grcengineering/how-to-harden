#!/usr/bin/env bash
# HTH Anthropic Claude — Shared helpers for Admin API scripts
# Requires: ANTHROPIC_ADMIN_KEY (sk-ant-admin01-...) environment variable
# API Docs: https://docs.anthropic.com/en/api/admin-api-overview

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────
ANTHROPIC_API_BASE="${ANTHROPIC_API_BASE:-https://api.anthropic.com}"
ANTHROPIC_VERSION="${ANTHROPIC_VERSION:-2023-06-01}"

# ── Colour helpers ─────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
pass()  { printf "${GREEN}[PASS]${NC}  %s\n" "$*"; APPLIED=$((APPLIED+1)); }
fail()  { printf "${RED}[FAIL]${NC}  %s\n" "$*"; FAILED=$((FAILED+1)); }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; SKIPPED=$((SKIPPED+1)); }

APPLIED=0; FAILED=0; SKIPPED=0

banner() {
  echo ""
  printf "${BLUE}━━━ HTH Anthropic Claude: %s ━━━${NC}\n" "$1"
  echo ""
}

summary() {
  echo ""
  printf "${BLUE}──── Summary ────${NC}\n"
  printf "  Applied: ${GREEN}%d${NC}  Failed: ${RED}%d${NC}  Skipped: ${YELLOW}%d${NC}\n" \
    "${APPLIED}" "${FAILED}" "${SKIPPED}"
  echo ""
}

# ── Auth check ─────────────────────────────────────────────────────────
require_admin_key() {
  if [[ -z "${ANTHROPIC_ADMIN_KEY:-}" ]]; then
    echo "ERROR: ANTHROPIC_ADMIN_KEY is not set."
    echo "Provision an Admin API key at: https://console.anthropic.com/settings/admin-keys"
    exit 1
  fi
}

# ── HTTP helpers ───────────────────────────────────────────────────────
anthropic_get() {
  local path="$1"
  curl -sf "${ANTHROPIC_API_BASE}${path}" \
    -H "x-api-key: ${ANTHROPIC_ADMIN_KEY}" \
    -H "anthropic-version: ${ANTHROPIC_VERSION}" \
    -H "Content-Type: application/json"
}

anthropic_post() {
  local path="$1"
  local body="${2:-{}}"
  curl -sf "${ANTHROPIC_API_BASE}${path}" \
    -X POST \
    -H "x-api-key: ${ANTHROPIC_ADMIN_KEY}" \
    -H "anthropic-version: ${ANTHROPIC_VERSION}" \
    -H "Content-Type: application/json" \
    -d "${body}"
}

anthropic_delete() {
  local path="$1"
  curl -sf "${ANTHROPIC_API_BASE}${path}" \
    -X DELETE \
    -H "x-api-key: ${ANTHROPIC_ADMIN_KEY}" \
    -H "anthropic-version: ${ANTHROPIC_VERSION}"
}

# Paginated list helper — follows has_more / next_page pattern
anthropic_list_all() {
  local path="$1"
  local results="[]"
  local url="${path}"
  while true; do
    local response
    response=$(anthropic_get "${url}") || { echo "${results}"; return 1; }
    local page_data
    page_data=$(echo "${response}" | jq -r '.data // []')
    results=$(echo "${results}" "${page_data}" | jq -s 'add')
    local has_more
    has_more=$(echo "${response}" | jq -r '.has_more // false')
    if [[ "${has_more}" != "true" ]]; then
      break
    fi
    local next_page
    next_page=$(echo "${response}" | jq -r '.next_page // empty')
    if [[ -z "${next_page}" ]]; then
      break
    fi
    url="${path}?after_id=${next_page}"
  done
  echo "${results}"
}
