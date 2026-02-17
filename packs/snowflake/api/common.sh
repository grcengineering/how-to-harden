#!/usr/bin/env bash
# HTH Snowflake Code Pack -- Common Utilities
# Source this file: source "$(dirname "$0")/common.sh"
#
# Required environment variables:
#   SNOWFLAKE_ACCOUNT  -- Your Snowflake account identifier (e.g., xy12345.us-east-1)
#   SNOWFLAKE_USER     -- Snowflake user with ACCOUNTADMIN or SECURITYADMIN role
#
# Authentication (one of):
#   SNOWFLAKE_PRIVATE_KEY  -- Path to RSA private key file (preferred)
#   SNOWFLAKE_PASSWORD     -- Password (fallback)
#
# Optional:
#   HTH_PROFILE_LEVEL -- 1 (Baseline), 2 (Hardened), 3 (Maximum Security) [default: 1]
#
# https://howtoharden.com/guides/snowflake/

set -euo pipefail

# Required environment variables
: "${SNOWFLAKE_ACCOUNT:?Set SNOWFLAKE_ACCOUNT (e.g., xy12345.us-east-1)}"
: "${SNOWFLAKE_USER:?Set SNOWFLAKE_USER}"
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"

# ---------------------------------------------------------------------------
# Authentication -- key-pair preferred, password fallback
# ---------------------------------------------------------------------------
SNOWSQL_AUTH=""
if [ -n "${SNOWFLAKE_PRIVATE_KEY:-}" ]; then
  SNOWSQL_AUTH="--private-key-path ${SNOWFLAKE_PRIVATE_KEY}"
elif [ -n "${SNOWFLAKE_PASSWORD:-}" ]; then
  SNOWSQL_AUTH=""
  export SNOWSQL_PWD="${SNOWFLAKE_PASSWORD}"
else
  echo "ERROR: Set SNOWFLAKE_PRIVATE_KEY or SNOWFLAKE_PASSWORD" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Query helper -- executes SQL via snowsql and returns JSON
# Usage: snow_query "SELECT CURRENT_ACCOUNT()"
# ---------------------------------------------------------------------------
snow_query() {
  snowsql -a "${SNOWFLAKE_ACCOUNT}" -u "${SNOWFLAKE_USER}" ${SNOWSQL_AUTH} \
    -o output_format=json -o friendly=false -o header=true -o timing=false \
    -q "$1"
}

# ---------------------------------------------------------------------------
# Query helper (plain text) -- for DDL/DML that doesn't need JSON
# ---------------------------------------------------------------------------
snow_exec() {
  snowsql -a "${SNOWFLAKE_ACCOUNT}" -u "${SNOWFLAKE_USER}" ${SNOWSQL_AUTH} \
    -o friendly=false -o header=true -o timing=false \
    -q "$1"
}

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

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
  echo -e "${BLUE}  How to Harden -- Snowflake SQL Hardening${NC}"
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
