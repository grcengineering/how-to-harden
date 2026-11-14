-- HTH Pack Contract: v1
--   control: snowflake-1.6
--   profile: L3
--   mode: mutating
-- HTH Snowflake 1.6: Independent approval for critical changes
-- Profile: L3 (Run) | NIST: AC-5, CM-3
-- https://howtoharden.com/guides/snowflake/#16-require-independent-approval-for-critical-administrative-changes
-- Source: https://docs.snowflake.com/en/sql-reference/sql/create-multi-party-approval-policy
-- Business Critical+. Replace example namespace/users with approved identities.
-- Creates a NEW, UNATTACHED policy; does NOT activate, replace, approve, or replay.
-- Confirm approver MFA, validated email, independent control and availability first.
-- HTH Guide Excerpt: begin db-create-independent-approval
CREATE MULTI PARTY APPROVAL POLICY security_db.policies.hth_admin_changes AS $$
rules:
  - name: independent_security_changes
    operations: [MODIFY_MULTI_PARTY_APPROVAL, MODIFY_PRIVILEGED_ROLE_GRANTS, MODIFY_AUTHENTICATION_POLICY, MODIFY_NETWORK_POLICY]
    approvers:
      users: ['SECURITY_APPROVER_A', 'SECURITY_APPROVER_B', 'SECURITY_APPROVER_C']
    required_approvals: 2
    request_duration_days: 3
    self_approval_allowed: false
$$;
-- HTH Guide Excerpt: end db-create-independent-approval
