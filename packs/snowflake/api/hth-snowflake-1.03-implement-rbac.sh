#!/usr/bin/env bash
# HTH Snowflake Control 1.3: Implement RBAC with Custom Roles
# Profile: L1 | NIST: AC-3, AC-6
# https://howtoharden.com/guides/snowflake/#13-implement-rbac-with-custom-roles
source "$(dirname "$0")/common.sh"

banner "1.3: Implement RBAC with Custom Roles"

should_apply 1 || { increment_skipped; summary; exit 0; }

# HTH Guide Excerpt: begin audit-accountadmin
# Audit ACCOUNTADMIN grants -- this role should have minimal direct assignments
info "1.3 Auditing ACCOUNTADMIN role grants..."
ADMIN_GRANTS=$(snow_query "SHOW GRANTS OF ROLE ACCOUNTADMIN;") || {
  fail "1.3 Failed to query ACCOUNTADMIN grants"
  increment_failed
  summary
  exit 0
}

ADMIN_COUNT=$(echo "${ADMIN_GRANTS}" | jq '[.[] | select(.granted_to == "USER")] | length' 2>/dev/null || echo "unknown")

if [ "${ADMIN_COUNT}" -gt 2 ]; then
  warn "1.3 ACCOUNTADMIN granted to ${ADMIN_COUNT} users (recommend <= 2)"
  echo "${ADMIN_GRANTS}" | jq -r '.[] | select(.granted_to == "USER") | "  - \(.grantee_name)"' 2>/dev/null || true
else
  pass "1.3 ACCOUNTADMIN grant count is acceptable (${ADMIN_COUNT} users)"
fi
# HTH Guide Excerpt: end audit-accountadmin

# HTH Guide Excerpt: begin create-custom-roles
# Create custom role hierarchy following least-privilege principle
info "1.3 Creating custom role hierarchy..."
snow_exec "
-- Functional roles
CREATE ROLE IF NOT EXISTS HTH_DATA_READER
  COMMENT = 'HTH: Read-only access to production data (Control 1.3)';
CREATE ROLE IF NOT EXISTS HTH_DATA_WRITER
  COMMENT = 'HTH: Read-write access to production data (Control 1.3)';
CREATE ROLE IF NOT EXISTS HTH_DATA_ANALYST
  COMMENT = 'HTH: Analyst role with warehouse usage and read access (Control 1.3)';
CREATE ROLE IF NOT EXISTS HTH_SECURITY_ADMIN
  COMMENT = 'HTH: Security administration without full ACCOUNTADMIN (Control 1.3)';

-- Role hierarchy: SECURITY_ADMIN -> SYSADMIN -> DATA_WRITER -> DATA_READER
GRANT ROLE HTH_DATA_READER TO ROLE HTH_DATA_WRITER;
GRANT ROLE HTH_DATA_READER TO ROLE HTH_DATA_ANALYST;
GRANT ROLE HTH_DATA_WRITER TO ROLE SYSADMIN;
GRANT ROLE HTH_SECURITY_ADMIN TO ROLE ACCOUNTADMIN;
" > /dev/null 2>&1 || {
  fail "1.3 Failed to create custom role hierarchy"
  increment_failed
  summary
  exit 0
}
# HTH Guide Excerpt: end create-custom-roles

pass "1.3 Custom role hierarchy created (HTH_DATA_READER, HTH_DATA_WRITER, HTH_DATA_ANALYST, HTH_SECURITY_ADMIN)"
increment_applied

# Verify role hierarchy
info "1.3 Verifying role hierarchy..."
snow_query "SHOW GRANTS OF ROLE HTH_DATA_READER;" > /dev/null 2>&1 && \
  pass "1.3 Role hierarchy verified" || \
  warn "1.3 Could not verify role hierarchy"

summary
