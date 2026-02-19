-- =============================================================================
-- HTH Snowflake Control 1.1: Enforce MFA for All Users
-- Profile: L1 (CRITICAL) | NIST: IA-2(1), IA-2(2)
-- https://howtoharden.com/guides/snowflake/#11-enforce-mfa-for-all-users
-- =============================================================================

-- HTH Guide Excerpt: begin db-verify-mfa-enrollment
-- Check MFA enrollment status for all active users
SELECT
    name,
    login_name,
    ext_authn_duo,
    ext_authn_uid,
    disabled,
    last_success_login
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE deleted_on IS NULL
ORDER BY ext_authn_duo DESC;
-- HTH Guide Excerpt: end db-verify-mfa-enrollment

-- HTH Guide Excerpt: begin db-alert-mfa-bypass
-- Alert on MFA bypass attempts (last 24 hours)
SELECT *
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE IS_SUCCESS = 'NO'
  AND ERROR_MESSAGE LIKE '%MFA%'
  AND EVENT_TIMESTAMP > DATEADD(hour, -24, CURRENT_TIMESTAMP());

-- Weekly MFA compliance check
SELECT
    COUNT(CASE WHEN ext_authn_duo = 'TRUE' THEN 1 END) as mfa_enabled,
    COUNT(CASE WHEN ext_authn_duo = 'FALSE' OR ext_authn_duo IS NULL THEN 1 END) as mfa_disabled,
    COUNT(*) as total_users
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE deleted_on IS NULL
  AND disabled = 'FALSE';
-- HTH Guide Excerpt: end db-alert-mfa-bypass

-- HTH Guide Excerpt: begin db-emergency-mfa-disable
-- Emergency MFA disable (NOT RECOMMENDED)
ALTER ACCOUNT UNSET AUTHENTICATION POLICY;
-- HTH Guide Excerpt: end db-emergency-mfa-disable
