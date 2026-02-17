#!/usr/bin/env bash
# HTH MongoDB Atlas Code Pack -- Common Utilities
# Source this file: source "$(dirname "$0")/common.sh"
#
# Required environment variables:
#   ATLAS_PUBLIC_KEY   -- MongoDB Atlas API public key (digest username)
#   ATLAS_PRIVATE_KEY  -- MongoDB Atlas API private key (digest password)
#   ATLAS_PROJECT_ID   -- MongoDB Atlas project (group) ID
#   HTH_PROFILE_LEVEL  -- 1 (Baseline), 2 (Hardened), 3 (Maximum Security) [default: 1]
#
# https://howtoharden.com/guides/mongodb-atlas/

set -euo pipefail

# Required environment variables
: "${ATLAS_PUBLIC_KEY:?Set ATLAS_PUBLIC_KEY (API public key)}"
: "${ATLAS_PRIVATE_KEY:?Set ATLAS_PRIVATE_KEY (API private key)}"
: "${ATLAS_PROJECT_ID:?Set ATLAS_PROJECT_ID (project/group ID)}"
HTH_PROFILE_LEVEL="${HTH_PROFILE_LEVEL:-1}"

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

ATLAS_BASE="https://cloud.mongodb.com/api/atlas/v2"

# ---------------------------------------------------------------------------
# HTTP helpers -- thin wrappers around curl for MongoDB Atlas Admin API v2
# Uses HTTP Digest authentication (--digest -u)
# All return raw JSON; pipe to jq for formatting
# ---------------------------------------------------------------------------
atlas_get() {
  curl -sf --digest -u "${ATLAS_PUBLIC_KEY}:${ATLAS_PRIVATE_KEY}" \
    -X GET "${ATLAS_BASE}$1" \
    -H "Content-Type: application/json" \
    -H "Accept: application/vnd.atlas.2023-11-15+json"
}

atlas_post() {
  curl -sf --digest -u "${ATLAS_PUBLIC_KEY}:${ATLAS_PRIVATE_KEY}" \
    -X POST "${ATLAS_BASE}$1" \
    -H "Content-Type: application/json" \
    -H "Accept: application/vnd.atlas.2023-11-15+json" \
    -d "$2"
}

atlas_patch() {
  curl -sf --digest -u "${ATLAS_PUBLIC_KEY}:${ATLAS_PRIVATE_KEY}" \
    -X PATCH "${ATLAS_BASE}$1" \
    -H "Content-Type: application/json" \
    -H "Accept: application/vnd.atlas.2023-11-15+json" \
    -d "$2"
}

atlas_delete() {
  curl -sf --digest -u "${ATLAS_PUBLIC_KEY}:${ATLAS_PRIVATE_KEY}" \
    -X DELETE "${ATLAS_BASE}$1" \
    -H "Content-Type: application/json" \
    -H "Accept: application/vnd.atlas.2023-11-15+json"
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
  echo -e "${BLUE}  How to Harden -- MongoDB Atlas API Hardening${NC}"
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
