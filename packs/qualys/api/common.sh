#!/usr/bin/env bash
# HTH Qualys Code Pack -- Common Utilities
# Source this file: source "$(dirname "$0")/common.sh"
#
# Required environment variables:
#   QUALYS_USER       -- Qualys API username
#   QUALYS_PASSWORD   -- Qualys API password
#   QUALYS_PLATFORM   -- Qualys API platform (e.g., qualysapi.qualys.com)
#   HTH_PROFILE_LEVEL -- 1 (Baseline), 2 (Hardened), 3 (Maximum Security) [default: 1]
#
# https://howtoharden.com/guides/qualys/

set -euo pipefail

# Required environment variables
: "${QUALYS_USER:?Set QUALYS_USER (Qualys API username)}"
: "${QUALYS_PASSWORD:?Set QUALYS_PASSWORD (Qualys API password)}"
: "${QUALYS_PLATFORM:?Set QUALYS_PLATFORM (e.g., qualysapi.qualys.com)}"
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

QUALYS_BASE="https://${QUALYS_PLATFORM}/api/2.0/fo"
QUALYS_V3="https://${QUALYS_PLATFORM}/qps/rest/3.0"
QUALYS_AUTH="${QUALYS_USER}:${QUALYS_PASSWORD}"

# ---------------------------------------------------------------------------
# HTTP helpers -- thin wrappers around curl for Qualys API v2
# Qualys v2 uses XML by default; responses are XML unless noted
# All require X-Requested-With header
# ---------------------------------------------------------------------------
ql_get() {
  curl -sf -u "${QUALYS_AUTH}" \
    -H "X-Requested-With: curl" \
    "${QUALYS_BASE}$1"
}

ql_post() {
  curl -sf -X POST -u "${QUALYS_AUTH}" \
    -H "X-Requested-With: curl" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "$2" \
    "${QUALYS_BASE}$1"
}

# ---------------------------------------------------------------------------
# HTTP helpers -- Qualys API v3 (JSON-based)
# ---------------------------------------------------------------------------
ql_v3_get() {
  curl -sf -u "${QUALYS_AUTH}" \
    -H "X-Requested-With: curl" \
    -H "Accept: application/json" \
    "${QUALYS_V3}$1"
}

ql_v3_post() {
  curl -sf -X POST -u "${QUALYS_AUTH}" \
    -H "X-Requested-With: curl" \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    -d "$2" \
    "${QUALYS_V3}$1"
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
  echo -e "${BLUE}  How to Harden -- Qualys API Hardening${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}  Profile Level: L${HTH_PROFILE_LEVEL}${NC}"
  echo -e "${BLUE}================================================================${NC}"
  echo ""
}

# ---------------------------------------------------------------------------
# XML parsing helpers -- extract values from Qualys v2 XML responses
# Uses grep/sed since Qualys v2 returns XML, not JSON
# ---------------------------------------------------------------------------
xml_value() {
  # Extract single-line XML tag value: xml_value "TAG" <<< "$xml"
  local tag="$1"
  grep -oP "<${tag}>\K[^<]+" || true
}

xml_count() {
  # Count occurrences of a tag in XML response
  local tag="$1"
  grep -c "<${tag}>" || echo "0"
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
