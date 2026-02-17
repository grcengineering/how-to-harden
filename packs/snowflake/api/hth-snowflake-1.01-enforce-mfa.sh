#!/usr/bin/env bash
# HTH Snowflake Control 1.1: Enforce MFA for All Users
# Profile: L1 | NIST: IA-2(1) | CRITICAL
# https://howtoharden.com/guides/snowflake/#11-enforce-mfa-for-all-users
source "$(dirname "$0")/common.sh"

banner "1.1: Enforce MFA for All Users"

should_apply 1 || { increment_skipped; summary; exit 0; }
info "1.1 Auditing MFA enrollment across all users..."

# HTH Guide Excerpt: begin audit-mfa-enrollment
# Identify users without MFA enrolled
MFA_AUDIT=$(snow_query "
SELECT
    name,
    login_name,
    ext_authn_duo,
    has_rsa_public_key,
    disabled,
    last_success_login
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE deleted_on IS NULL
  AND disabled = 'false'
ORDER BY name;
") || {
  fail "1.1 Failed to query user MFA status"
  increment_failed
  summary
  exit 0
}

# Count users without MFA
NO_MFA_COUNT=$(echo "${MFA_AUDIT}" | jq '[.[] | select(.EXT_AUTHN_DUO == "false" and .HAS_RSA_PUBLIC_KEY == "false")] | length' 2>/dev/null || echo "unknown")
TOTAL_COUNT=$(echo "${MFA_AUDIT}" | jq 'length' 2>/dev/null || echo "unknown")
# HTH Guide Excerpt: end audit-mfa-enrollment

if [ "${NO_MFA_COUNT}" = "0" ]; then
  pass "1.1 All ${TOTAL_COUNT} active users have MFA enrolled"
  increment_applied
else
  warn "1.1 ${NO_MFA_COUNT} of ${TOTAL_COUNT} active users lack MFA enrollment"

  # List users without MFA
  info "1.1 Users without MFA:"
  echo "${MFA_AUDIT}" | jq -r '.[] | select(.EXT_AUTHN_DUO == "false" and .HAS_RSA_PUBLIC_KEY == "false") | "  - \(.NAME) (\(.LOGIN_NAME))"' 2>/dev/null || true

  # HTH Guide Excerpt: begin create-authentication-policy
  # Create authentication policy requiring MFA for all users
  info "1.1 Creating authentication policy to enforce MFA..."
  snow_exec "
CREATE AUTHENTICATION POLICY IF NOT EXISTS hth_require_mfa
  MFA_AUTHENTICATION_METHODS = ('TOTP')
  CLIENT_TYPES = ('SNOWFLAKE_UI', 'SNOWSQL', 'DRIVERS')
  SECURITY_INTEGRATIONS = ()
  COMMENT = 'HTH: Enforce MFA for all human users (Control 1.1)';
" > /dev/null 2>&1 || {
    fail "1.1 Failed to create authentication policy"
    increment_failed
    summary
    exit 0
  }

  # Attach policy at account level
  info "1.1 Attaching authentication policy to account..."
  snow_exec "
ALTER ACCOUNT SET AUTHENTICATION POLICY hth_require_mfa;
" > /dev/null 2>&1 || {
    warn "1.1 Could not attach policy at account level (may require ACCOUNTADMIN)"
    increment_failed
    summary
    exit 0
  }
  # HTH Guide Excerpt: end create-authentication-policy

  pass "1.1 Authentication policy hth_require_mfa created and attached to account"
  increment_applied
fi

summary
