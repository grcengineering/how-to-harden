#!/usr/bin/env bash
# HTH Auth0 Code Pack -- Common Utilities
# Source this file: source "$(dirname "$0")/common.sh"
#
# Required environment variables:
#   AUTH0_DOMAIN      -- Your Auth0 tenant domain (e.g., yourcompany.auth0.com)
#   AUTH0_TOKEN       -- Auth0 Management API token
#   HTH_PROFILE_LEVEL -- 1 (Baseline), 2 (Hardened), 3 (Maximum Security) [default: 1]
#
# https://howtoharden.com/guides/auth0/

set -euo pipefail

: "${AUTH0_DOMAIN:?Set AUTH0_DOMAIN (e.g., yourcompany.auth0.com)}"
: "${AUTH0_TOKEN:?Set AUTH0_TOKEN (Management API token)}"
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

AUTH0_API="https://${AUTH0_DOMAIN}/api/v2"

a0_get() {
  curl -sf -X GET "${AUTH0_API}$1" \
    -H "Authorization: Bearer ${AUTH0_TOKEN}" \
    -H "Content-Type: application/json"
}

a0_post() {
  curl -sf -X POST "${AUTH0_API}$1" \
    -H "Authorization: Bearer ${AUTH0_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

a0_put() {
  curl -sf -X PUT "${AUTH0_API}$1" \
    -H "Authorization: Bearer ${AUTH0_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

a0_patch() {
  curl -sf -X PATCH "${AUTH0_API}$1" \
    -H "Authorization: Bearer ${AUTH0_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

a0_delete() {
  curl -sf -X DELETE "${AUTH0_API}$1" \
    -H "Authorization: Bearer ${AUTH0_TOKEN}"
}

should_apply() {
  local required_level=$1
  if [ "${HTH_PROFILE_LEVEL}" -lt "${required_level}" ]; then
    echo -e "${YELLOW}[SKIP]${NC} Requires L${required_level} (current: L${HTH_PROFILE_LEVEL})"
    return 1
  fi
  return 0
}

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
pass()  { echo -e "${GREEN}[PASS]${NC} $1"; }
fail()  { echo -e "${RED}[FAIL]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }

banner() {
  echo ""
  echo -e "${BLUE}================================================================${NC}"
  echo -e "${BLUE}  How to Harden -- Auth0 API Hardening${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}  Profile Level: L${HTH_PROFILE_LEVEL}${NC}"
  echo -e "${BLUE}================================================================${NC}"
  echo ""
}

CONTROLS_APPLIED=0; CONTROLS_SKIPPED=0; CONTROLS_FAILED=0
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
