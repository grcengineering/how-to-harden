-- HTH Pack Contract: v1
--   control: snowflake-1.5
--   profile: L2
--   mode: mutating
-- HTH Snowflake 1.5: Constrain workload identity federation
-- Profile: L2 (Walk) | NIST: IA-5, IA-9
-- https://howtoharden.com/guides/snowflake/#15-use-workload-identity-federation-for-cloud-hosted-workloads
-- Source: https://docs.snowflake.com/en/sql-reference/sql/create-authentication-policy
-- REVIEW FIRST: replace example namespace/account ID. Creates a NEW, UNATTACHED
-- policy. Never overwrite a shared policy or attach this WIF-only example to humans.
-- Existing MFA/PAT/client controls must be preserved in the actual target policy.
-- HTH Guide Excerpt: begin db-create-wif-boundary
CREATE AUTHENTICATION POLICY security_db.policies.hth_aws_workloads
  AUTHENTICATION_METHODS = ('WORKLOAD_IDENTITY')
  WORKLOAD_IDENTITY_POLICY = (
    ALLOWED_PROVIDERS = (AWS)
    ALLOWED_AWS_ACCOUNTS = ('123456789012')
  );
-- HTH Guide Excerpt: end db-create-wif-boundary
