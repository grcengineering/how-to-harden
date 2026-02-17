#!/usr/bin/env bash
# HTH MongoDB Atlas Control 2.1: Configure Database Users (L1)
# Profile: L1 | SOC 2: CC6.1, CC6.3 | NIST: AC-2, AC-6
# https://howtoharden.com/guides/mongodb-atlas/#21-database-users
source "$(dirname "$0")/common.sh"

banner "2.1: Configure Database Users"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "2.1 Auditing database users for project ${ATLAS_PROJECT_ID}..."

# HTH Guide Excerpt: begin api-audit-database-users
# Retrieve all database users for the project
DB_USERS=$(atlas_get "/groups/${ATLAS_PROJECT_ID}/databaseUsers") || {
  fail "2.1 Failed to retrieve database users"
  increment_failed
  summary
  exit 1
}

TOTAL_USERS=$(echo "${DB_USERS}" | jq '.totalCount // 0')
info "2.1 Found ${TOTAL_USERS} database users"

# Check for users with atlasAdmin role on all databases (overly permissive)
ADMIN_USERS=$(echo "${DB_USERS}" | jq -r '
  .results[]
  | select(
      .roles[]
      | select(.roleName == "atlasAdmin" and (.databaseName == "admin" or .databaseName == ""))
    )
  | .username
' 2>/dev/null | sort -u || true)

if [ -n "${ADMIN_USERS}" ]; then
  fail "2.1 Users with atlasAdmin role detected (overly permissive):"
  echo "${ADMIN_USERS}" | while read -r user; do
    fail "  - ${user}"
  done
  increment_failed
else
  pass "2.1 No users with unrestricted atlasAdmin role"
  increment_applied
fi

# Check for users with readWriteAnyDatabase (broad access)
BROAD_USERS=$(echo "${DB_USERS}" | jq -r '
  .results[]
  | select(
      .roles[]
      | select(.roleName == "readWriteAnyDatabase")
    )
  | .username
' 2>/dev/null | sort -u || true)

if [ -n "${BROAD_USERS}" ]; then
  warn "2.1 Users with readWriteAnyDatabase role (consider scoping to specific databases):"
  echo "${BROAD_USERS}" | while read -r user; do
    warn "  - ${user}"
  done
fi

# Check for users authenticating with SCRAM (password) vs X.509 or LDAP
SCRAM_USERS=$(echo "${DB_USERS}" | jq '[.results[] | select(.databaseName == "admin")] | length' 2>/dev/null || echo "0")
X509_USERS=$(echo "${DB_USERS}" | jq '[.results[] | select(.databaseName == "$external" and .x509Type != "NONE")] | length' 2>/dev/null || echo "0")
LDAP_USERS=$(echo "${DB_USERS}" | jq '[.results[] | select(.ldapAuthType != null and .ldapAuthType != "NONE")] | length' 2>/dev/null || echo "0")

info "2.1 Authentication breakdown:"
info "  - SCRAM (password): ${SCRAM_USERS}"
info "  - X.509 certificate: ${X509_USERS}"
info "  - LDAP: ${LDAP_USERS}"

if [ "${SCRAM_USERS}" -gt 0 ] && should_apply 2 2>/dev/null; then
  warn "2.1 L2 recommends migrating SCRAM users to X.509 or LDAP authentication"
fi

# Check for users with no role scoping (roles on all clusters)
UNSCOPED_USERS=$(echo "${DB_USERS}" | jq -r '
  .results[]
  | select(.scopes == null or (.scopes | length) == 0)
  | .username
' 2>/dev/null || true)

if [ -n "${UNSCOPED_USERS}" ]; then
  warn "2.1 Users with no cluster scope (access to all clusters in project):"
  echo "${UNSCOPED_USERS}" | while read -r user; do
    warn "  - ${user}"
  done
fi
# HTH Guide Excerpt: end api-audit-database-users

summary
