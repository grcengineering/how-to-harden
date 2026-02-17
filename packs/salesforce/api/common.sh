#!/usr/bin/env bash
# HTH Salesforce Code Pack -- Common Utilities
# Source this file: source "$(dirname "$0")/common.sh"
#
# Required environment variables:
#   SF_INSTANCE_URL    -- Your Salesforce instance (e.g., https://your-instance.salesforce.com)
#   SF_ACCESS_TOKEN    -- OAuth Bearer token with admin privileges
#   HTH_PROFILE_LEVEL  -- 1 (Baseline), 2 (Hardened), 3 (Maximum Security) [default: 1]
#
# https://howtoharden.com/guides/salesforce/

set -euo pipefail

# Required environment variables
: "${SF_INSTANCE_URL:?Set SF_INSTANCE_URL (e.g., https://your-instance.salesforce.com)}"
: "${SF_ACCESS_TOKEN:?Set SF_ACCESS_TOKEN (OAuth Bearer token)}"
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

SF_API="v59.0"
SF_BASE="${SF_INSTANCE_URL}/services/data/${SF_API}"
AUTH_HEADER="Authorization: Bearer ${SF_ACCESS_TOKEN}"

# ---------------------------------------------------------------------------
# HTTP helpers -- thin wrappers around curl for Salesforce REST API calls
# All return raw JSON; pipe to jq for formatting
# ---------------------------------------------------------------------------
sf_get() {
  curl -sf -X GET "${SF_BASE}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json"
}

sf_post() {
  curl -sf -X POST "${SF_BASE}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

sf_patch() {
  curl -sf -X PATCH "${SF_BASE}$1" \
    -H "${AUTH_HEADER}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

sf_delete() {
  curl -sf -X DELETE "${SF_BASE}$1" \
    -H "${AUTH_HEADER}"
}

# ---------------------------------------------------------------------------
# SOQL query helper -- URL-encodes the query string
# Usage: sf_query "SELECT Id, Name FROM Account LIMIT 10"
# ---------------------------------------------------------------------------
sf_query() {
  local encoded
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))")
  sf_get "/query?q=${encoded}"
}

# ---------------------------------------------------------------------------
# Tooling API query helper -- for metadata queries
# Usage: sf_tooling_query "SELECT Id, Name FROM ConnectedApplication"
# ---------------------------------------------------------------------------
sf_tooling_query() {
  local encoded
  encoded=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$1'))")
  sf_get "/tooling/query?q=${encoded}"
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
  echo -e "${BLUE}  How to Harden -- Salesforce API Hardening${NC}"
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
