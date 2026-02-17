#!/usr/bin/env bash
# HTH GitLab Code Pack -- Common Utilities
# Source this file: source "$(dirname "$0")/common.sh"
#
# Required environment variables:
#   GITLAB_URL         -- Your GitLab instance URL (e.g., https://gitlab.company.com)
#   GITLAB_TOKEN       -- Personal or group access token with admin privileges
#   HTH_PROFILE_LEVEL  -- 1 (Baseline), 2 (Hardened), 3 (Maximum Security) [default: 1]
#
# https://howtoharden.com/guides/gitlab/

set -euo pipefail

# Required environment variables
: "${GITLAB_URL:?Set GITLAB_URL (e.g., https://gitlab.company.com)}"
: "${GITLAB_TOKEN:?Set GITLAB_TOKEN}"
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

GL_BASE="${GITLAB_URL}/api/v4"
AUTH_HEADER="PRIVATE-TOKEN: ${GITLAB_TOKEN}"

# ---------------------------------------------------------------------------
# HTTP helpers -- thin wrappers around curl for GitLab API v4 calls
# All return raw JSON; pipe to jq for formatting
# ---------------------------------------------------------------------------
gl_get() {
  curl -sf -X GET "${GL_BASE}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json"
}

gl_post() {
  curl -sf -X POST "${GL_BASE}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

gl_put() {
  curl -sf -X PUT "${GL_BASE}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

gl_patch() {
  curl -sf -X PATCH "${GL_BASE}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

gl_delete() {
  curl -sf -X DELETE "${GL_BASE}$1" \
    -H "${AUTH_HEADER}"
}

# ---------------------------------------------------------------------------
# Profile level gate -- skip controls above current level
# Usage: should_apply 2 || return 0
# ---------------------------------------------------------------------------
should_apply() {
  local required_level=$1
  if [ "${HTH_PROFILE_LEVEL}" -lt "${required_level}" ]; then
    echo -e "${YELLOW}[SKIP]${NC} Requires L${required_level} (current: L${HTH_PROFILE_LEVEL})"
    return 1
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Logging helpers
# ---------------------------------------------------------------------------
info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
pass()  { echo -e "${GREEN}[PASS]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

# ---------------------------------------------------------------------------
# Banner
# ---------------------------------------------------------------------------
banner() {
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}  How to Harden -- GitLab API Hardening${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}  Profile Level: L${HTH_PROFILE_LEVEL}${NC}"
  echo -e "${BLUE}================================================================${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# Counters for summary reporting
# ---------------------------------------------------------------------------
CONTROLS_APPLIED=0
CONTROLS_SKIPPED=0
CONTROLS_FAILED=0

increment_applied()  { CONTROLS_APPLIED=$((CONTROLS_APPLIED + 1)); }
increment_skipped()  { CONTROLS_SKIPPED=$((CONTROLS_SKIPPED + 1)); }
increment_failed()   { CONTROLS_FAILED=$((CONTROLS_FAILED + 1)); }

summary() {
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}  Summary${NC}"
  echo -e "${GREEN}  Applied: ${CONTROLS_APPLIED}${NC}"
  echo -e "${YELLOW}  Skipped: ${CONTROLS_SKIPPED}${NC}"
  echo -e "${RED}  Failed:  ${CONTROLS_FAILED}${NC}"
  echo -e "${BLUE}================================================================${NC}"
}
