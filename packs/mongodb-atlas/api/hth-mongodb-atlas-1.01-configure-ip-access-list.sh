#!/usr/bin/env bash
# HTH MongoDB Atlas Control 1.1: Configure IP Access List (L1)
# Profile: L1 | SOC 2: CC6.1, CC6.6 | NIST: SC-7, AC-3
# https://howtoharden.com/guides/mongodb-atlas/#11-ip-access-list
source "$(dirname "$0")/common.sh"

banner "1.1: Configure IP Access List"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Auditing IP access list for project ${ATLAS_PROJECT_ID}..."

# HTH Guide Excerpt: begin api-audit-ip-access
# Retrieve all IP access list entries for the project
ACCESS_LIST=$(atlas_get "/groups/${ATLAS_PROJECT_ID}/accessList") || {
  fail "1.1 Failed to retrieve IP access list"
  increment_failed
  summary
  exit 1
}

TOTAL_ENTRIES=$(echo "${ACCESS_LIST}" | jq '.totalCount // 0')
info "1.1 Found ${TOTAL_ENTRIES} IP access list entries"

# Check for open access (0.0.0.0/0) -- critical finding
OPEN_ENTRIES=$(echo "${ACCESS_LIST}" | jq -r '
  .results[]
  | select(.cidrBlock == "0.0.0.0/0" or .cidrBlock == "::/0")
  | .cidrBlock
' 2>/dev/null || true)

if [ -n "${OPEN_ENTRIES}" ]; then
  fail "1.1 CRITICAL: Open access entry detected -- databases exposed to entire internet"
  echo "${OPEN_ENTRIES}" | while read -r cidr; do
    fail "  - ${cidr}"
  done
  increment_failed
else
  pass "1.1 No open access entries (0.0.0.0/0) found"
  increment_applied
fi

# Report overly broad CIDR blocks (larger than /16)
BROAD_ENTRIES=$(echo "${ACCESS_LIST}" | jq -r '
  .results[]
  | select(.cidrBlock != null)
  | select(
      (.cidrBlock | split("/") | .[1] | tonumber) < 16
    )
  | "\(.cidrBlock) (\(.comment // "no comment"))"
' 2>/dev/null || true)

if [ -n "${BROAD_ENTRIES}" ]; then
  warn "1.1 Overly broad CIDR blocks detected (wider than /16):"
  echo "${BROAD_ENTRIES}" | while read -r entry; do
    warn "  - ${entry}"
  done
fi

# Check for entries with no comment (poor documentation)
UNCOMMENTED=$(echo "${ACCESS_LIST}" | jq '[.results[] | select(.comment == null or .comment == "")] | length' 2>/dev/null || echo "0")
if [ "${UNCOMMENTED}" -gt 0 ]; then
  warn "1.1 ${UNCOMMENTED} access list entries have no comment (add descriptions for audit trail)"
fi

# Report temporary entries that may have expired or are about to
TEMP_ENTRIES=$(echo "${ACCESS_LIST}" | jq -r '
  .results[]
  | select(.deleteAfterDate != null)
  | "\(.cidrBlock) expires \(.deleteAfterDate)"
' 2>/dev/null || true)

if [ -n "${TEMP_ENTRIES}" ]; then
  info "1.1 Temporary access list entries:"
  echo "${TEMP_ENTRIES}" | while read -r entry; do
    info "  - ${entry}"
  done
fi
# HTH Guide Excerpt: end api-audit-ip-access

summary
