#!/usr/bin/env bash
# HTH ServiceNow Code Pack -- Common Utilities
# Source this file: source "$(dirname "$0")/common.sh"
#
# Required environment variables:
#   SN_INSTANCE       -- Your ServiceNow instance name (e.g., your-company)
#   SN_USER           -- Admin username for Basic Auth
#   SN_PASSWORD       -- Admin password for Basic Auth
#   HTH_PROFILE_LEVEL -- 1 (Baseline), 2 (Hardened), 3 (Maximum Security) [default: 1]
#
# https://howtoharden.com/guides/servicenow/

set -euo pipefail

# Required environment variables
: "${SN_INSTANCE:?Set SN_INSTANCE (e.g., your-company)}"
: "${SN_USER:?Set SN_USER (admin username)}"
: "${SN_PASSWORD:?Set SN_PASSWORD}"
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

SN_BASE="https://${SN_INSTANCE}.service-now.com/api/now"

# ---------------------------------------------------------------------------
# HTTP helpers -- thin wrappers around curl for ServiceNow REST Table API
# All return raw JSON; pipe to jq for formatting
# ---------------------------------------------------------------------------
sn_get() {
  curl -sf -X GET "${SN_BASE}$1" \
    -u "${SN_USER}:${SN_PASSWORD}" \
    -H "Accept: application/json"
}

sn_post() {
  curl -sf -X POST "${SN_BASE}$1" \
    -u "${SN_USER}:${SN_PASSWORD}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$2"
}

sn_patch() {
  curl -sf -X PATCH "${SN_BASE}$1" \
    -u "${SN_USER}:${SN_PASSWORD}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "$2"
}

sn_delete() {
  curl -sf -X DELETE "${SN_BASE}$1" \
    -u "${SN_USER}:${SN_PASSWORD}" \
    -H "Accept: application/json"
}

# ---------------------------------------------------------------------------
# Table API convenience helpers
# ---------------------------------------------------------------------------
sn_table_get() {
  sn_get "/table/$1?$2"
}

sn_property() {
  sn_table_get "sys_properties" "sysparm_query=name=$1&sysparm_fields=name,value" \
    | jq -r '.result[0].value // empty'
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
  echo -e "${BLUE}  How to Harden -- ServiceNow API Hardening${NC}"
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
