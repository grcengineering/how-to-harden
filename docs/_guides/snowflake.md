---
layout: guide
title: "Snowflake Hardening Guide"
vendor: "Snowflake"
slug: "snowflake"
tier: "1"
category: "Data Platform"
description: "Data warehouse security including network policies, MFA enforcement, and access controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

Snowflake is a cloud data platform whose **2024 breach affecting 165+ organizations** (AT&T, Ticketmaster, Santander) demonstrated catastrophic supply chain risk. Over **500+ million individuals** had data exposed via credential stuffing attacks on accounts without MFA. OAuth integrations with Tableau, Looker, and Power BI create broad access chains to sensitive data. AT&T paid $370,000 ransom, and 32 consolidated lawsuits are pending.

### Intended Audience
- Security engineers managing Snowflake security
- Data engineers configuring access controls
- GRC professionals assessing data platform compliance
- Third-party risk managers evaluating BI tool integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries (VPS deployment)

### Scope
This guide covers Snowflake-specific security configurations including authentication, network policies, data sharing governance, and BI tool integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA for All Users

**Profile Level:** L1 (Baseline) - CRITICAL
**CIS Controls:** 6.3, 6.5
**NIST 800-53:** IA-2(1), IA-2(2)

#### Description
Require multi-factor authentication for ALL Snowflake users. The 2024 breach was enabled by credential stuffing against accounts without MFA.

#### Rationale
**Why This Matters:**
- 165+ organizations breached via simple credential stuffing
- No MFA = trivial account takeover
- MFA would have prevented 100% of 2024 breach victims

**Attack Prevented:** Credential stuffing, password spray, account takeover

**Real-World Incidents:**
- **2024 Snowflake Breach:** UNC5537 threat actor used stolen credentials to access 165+ customer accounts. AT&T, Ticketmaster, Santander, LendingTree, and others affected. $370,000 ransom paid by AT&T. 500+ million individuals had data exposed.

#### Prerequisites
- [ ] ACCOUNTADMIN role access
- [ ] User inventory for enrollment tracking
- [ ] Communication plan for MFA rollout

#### ClickOps Implementation

**Step 1: Enable MFA at Account Level**
1. Navigate to: **Admin → Security** (Snowsight)
2. Under **Authentication**, enable:
   - **Multi-Factor Authentication:** Required
   - **MFA Policy:** Enforce for all users

**Step 2: Create MFA Network Policy (Enforce MFA Before Password)**
1. Navigate to: **Admin → Security → Network Policies**
2. Create policy requiring MFA regardless of network

**Step 3: Verify MFA Enrollment**
```sql
-- Check MFA enrollment status
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
```

**Time to Complete:** ~15 minutes (policy) + user enrollment time

#### Code Implementation

**Option 1: SQL**
```sql
-- Enforce MFA at account level
ALTER ACCOUNT SET REQUIRE_STORAGE_INTEGRATION_FOR_STAGE_CREATION = TRUE;

-- Create authentication policy requiring MFA
CREATE OR REPLACE AUTHENTICATION POLICY mfa_required
    MFA_AUTHENTICATION_METHODS = ('TOTP')
    CLIENT_TYPES = ('SNOWFLAKE_UI', 'SNOWSIGHT')
    SECURITY_INTEGRATIONS = ();

-- Apply to account
ALTER ACCOUNT SET AUTHENTICATION POLICY = mfa_required;

-- For specific users
ALTER USER sensitive_user SET MINS_TO_BYPASS_MFA = 0;
```

**Option 2: Terraform**
```hcl
# terraform/snowflake/mfa-enforcement.tf

resource "snowflake_account_parameter" "require_mfa" {
  key   = "REQUIRE_STORAGE_INTEGRATION_FOR_STAGE_CREATION"
  value = "TRUE"
}

resource "snowflake_authentication_policy" "mfa_required" {
  name     = "MFA_REQUIRED"
  database = "SECURITY"
  schema   = "POLICIES"

  mfa_authentication_methods = ["TOTP"]
  client_types               = ["SNOWFLAKE_UI", "SNOWSIGHT"]
}
```

#### Validation & Testing
1. [ ] Attempt login without MFA - should be blocked
2. [ ] Complete login with MFA - should succeed
3. [ ] Run enrollment query - all active users should show MFA enabled
4. [ ] Verify service accounts use key-pair authentication

**Expected result:** No user can authenticate with password-only

#### Monitoring & Maintenance
**Ongoing monitoring:**
```sql
-- Alert on MFA bypass attempts
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
```

**Maintenance schedule:**
- **Weekly:** Review MFA enrollment compliance
- **Monthly:** Audit MFA bypass exceptions
- **Quarterly:** Review authentication policies

#### Operational Impact

| Aspect | Impact Level | Details |
||------|---------|----------|---------|--------|-------------|----------|
| **User Experience** | Low | Users enroll once, authenticate via app |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low | Self-service enrollment |
| **Rollback Difficulty** | Easy | Can disable policy (not recommended) |

**Rollback Procedure:**
```sql
-- Emergency MFA disable (NOT RECOMMENDED)
ALTER ACCOUNT UNSET AUTHENTICATION POLICY;
```

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-2(1), IA-2(2) | MFA for network/local access |
| **PCI DSS** | 8.3.1 | MFA for all access |
| **HIPAA** | 164.312(d) | Person or entity authentication |

---

### 1.2 Implement Service Account Key-Pair Authentication

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Replace password authentication for service accounts with RSA key-pair authentication. Eliminates credential stuffing risk for automated processes.

#### Rationale
**Why This Matters:**
- Service accounts can't use interactive MFA
- Password-based service accounts were compromised in 2024 breach
- Key-pair authentication is immune to credential stuffing

#### ClickOps Implementation

**Step 1: Generate RSA Key Pair**
```bash
# Generate private key (keep secure!)
openssl genrsa -out rsa_key.pem 2048

# Generate public key
openssl rsa -in rsa_key.pem -pubout -out rsa_key.pub

# Extract public key in Snowflake format
grep -v "PUBLIC KEY" rsa_key.pub | tr -d '\n'
```

**Step 2: Configure User with Key-Pair**
```sql
-- Remove password from service account
ALTER USER svc_etl_pipeline
    SET RSA_PUBLIC_KEY = 'MIIBIjANBgkqhki...'
    UNSET PASSWORD;

-- Verify
DESC USER svc_etl_pipeline;
```

**Step 3: Update Application Connection**
```python
# Python example using key-pair
import snowflake.connector

conn = snowflake.connector.connect(
    account='your_account',
    user='svc_etl_pipeline',
    private_key_file='/path/to/rsa_key.pem',
    warehouse='ETL_WH',
    database='PRODUCTION'
)
```

---

### 1.3 Implement RBAC with Custom Roles

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Create granular role hierarchy instead of granting broad SYSADMIN or ACCOUNTADMIN access. Implement least privilege for data access.

#### ClickOps Implementation

**Step 1: Design Role Hierarchy**
```sql
-- Create functional roles
CREATE ROLE IF NOT EXISTS data_analyst;
CREATE ROLE IF NOT EXISTS data_engineer;
CREATE ROLE IF NOT EXISTS security_admin;

-- Create object access roles
CREATE ROLE IF NOT EXISTS sales_data_reader;
CREATE ROLE IF NOT EXISTS sales_data_writer;
CREATE ROLE IF NOT EXISTS pii_data_reader;

-- Grant object access to functional roles
GRANT ROLE sales_data_reader TO ROLE data_analyst;
GRANT ROLE sales_data_writer TO ROLE data_engineer;

-- Grant functional roles to users
GRANT ROLE data_analyst TO USER john_analyst;
```

**Step 2: Restrict ACCOUNTADMIN**
```sql
-- Audit ACCOUNTADMIN members
SHOW GRANTS OF ROLE ACCOUNTADMIN;

-- Remove unnecessary ACCOUNTADMIN grants
REVOKE ROLE ACCOUNTADMIN FROM USER over_privileged_user;

-- Create break-glass procedure for emergency admin access
```

---

## 2. Network Access Controls

### 2.1 Implement Network Policies

**Profile Level:** L1 (Baseline)
**CIS Controls:** 13.3
**NIST 800-53:** AC-3, SC-7

#### Description
Restrict Snowflake access to known IP ranges (corporate network, VPN, approved BI tool IPs). Block access from unauthorized networks.

#### Rationale
**Why This Matters:**
- 2024 attackers accessed accounts from attacker-controlled infrastructure
- IP restrictions would have blocked compromised credential usage
- Network policies are defense-in-depth for credential theft

**Attack Prevented:** Credential stuffing from botnets, unauthorized access from foreign locations

#### ClickOps Implementation

**Step 1: Create Network Policy**
1. Navigate to: **Admin → Security → Network Policies**
2. Click **Add Policy**
3. Configure:
   - **Name:** corporate_access
   - **Allowed IPs:** Corporate ranges, VPN egress
   - **Blocked IPs:** Known bad ranges (optional)

**Step 2: Apply Network Policy**
```sql
-- Apply to account (affects all users)
ALTER ACCOUNT SET NETWORK_POLICY = corporate_access;

-- Or apply to specific users only
ALTER USER external_partner SET NETWORK_POLICY = partner_network_policy;
```

#### Code Implementation

```sql
-- Create network policy
CREATE OR REPLACE NETWORK POLICY corporate_access
    ALLOWED_IP_LIST = (
        '203.0.113.0/24',      -- Corporate HQ
        '198.51.100.0/24',     -- VPN egress
        '192.0.2.10/32'        -- Tableau Server
    )
    BLOCKED_IP_LIST = ()
    COMMENT = 'Restrict access to corporate networks and BI tools';

-- Apply to account
ALTER ACCOUNT SET NETWORK_POLICY = corporate_access;

-- Create separate policy for BI tool integrations
CREATE OR REPLACE NETWORK POLICY bi_tools_access
    ALLOWED_IP_LIST = (
        '192.0.2.10/32',       -- Tableau Server
        '192.0.2.20/32',       -- Power BI Gateway
        '192.0.2.30/32'        -- Looker
    )
    COMMENT = 'Restrict service accounts to BI tool IPs';

-- Apply to service account
ALTER USER svc_tableau SET NETWORK_POLICY = bi_tools_access;
```

**Terraform:**
```hcl
resource "snowflake_network_policy" "corporate" {
  name            = "CORPORATE_ACCESS"
  allowed_ip_list = ["203.0.113.0/24", "198.51.100.0/24"]
  comment         = "Corporate network access only"
}

resource "snowflake_account_parameter" "network_policy" {
  key   = "NETWORK_POLICY"
  value = snowflake_network_policy.corporate.name
}
```

#### Validation & Testing
```sql
-- Test from allowed IP - should succeed
SELECT CURRENT_USER();

-- View network policy assignments
SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN ACCOUNT;
SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN USER svc_tableau;
```

---

### 2.2 Enable Private Connectivity (PrivateLink/Private Service Connect)

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SC-7

#### Description
Configure private network connectivity to Snowflake, eliminating exposure to public internet.

#### ClickOps Implementation

**AWS PrivateLink:**
1. Navigate to: **Admin → Security → Private Connectivity**
2. Enable PrivateLink
3. Configure VPC endpoint in AWS
4. Update DNS for private resolution

**Azure Private Link:**
1. Similar process for Azure environments
2. Configure Private Endpoint in Azure

```sql
-- Verify private connectivity
SELECT SYSTEM$GET_PRIVATELINK_CONFIG();
```

---

## 3. OAuth & Integration Security

### 3.1 Restrict OAuth Token Scope and Lifetime

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(13)

#### Description
Configure OAuth security integrations with minimum required scopes and short token lifetimes for BI tool connections.

#### Rationale
**Why This Matters:**
- OAuth tokens for Tableau, Looker, Power BI access data
- Long-lived tokens create persistent risk
- Stolen OAuth tokens enabled downstream access in 2024 breach

#### ClickOps Implementation

**Step 1: Audit Existing Security Integrations**
```sql
-- List all security integrations
SHOW SECURITY INTEGRATIONS;

-- Describe OAuth integration details
DESC SECURITY INTEGRATION tableau_oauth;
```

**Step 2: Configure OAuth Integration**
```sql
-- Create OAuth integration with restrictions
CREATE OR REPLACE SECURITY INTEGRATION tableau_oauth
    TYPE = OAUTH
    ENABLED = TRUE
    OAUTH_CLIENT = TABLEAU_DESKTOP
    OAUTH_REFRESH_TOKEN_VALIDITY = 86400  -- 1 day (default is 90 days)
    BLOCKED_ROLES_LIST = ('ACCOUNTADMIN', 'SECURITYADMIN', 'SYSADMIN');
```

**Step 3: Block High-Privilege Roles from OAuth**
```sql
-- Ensure admin roles cannot authenticate via OAuth
ALTER SECURITY INTEGRATION tableau_oauth
    SET BLOCKED_ROLES_LIST = ('ACCOUNTADMIN', 'SECURITYADMIN', 'SYSADMIN', 'ORGADMIN');
```

---

### 3.2 Implement External OAuth (IdP Integration)

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-2(1)

#### Description
Configure External OAuth using your identity provider (Okta, Azure AD) for centralized authentication and MFA enforcement.

#### Code Implementation

```sql
-- Create External OAuth integration with Okta
CREATE OR REPLACE SECURITY INTEGRATION okta_oauth
    TYPE = EXTERNAL_OAUTH
    ENABLED = TRUE
    EXTERNAL_OAUTH_TYPE = OKTA
    EXTERNAL_OAUTH_ISSUER = 'https://your-org.okta.com/oauth2/default'
    EXTERNAL_OAUTH_JWS_KEYS_URL = 'https://your-org.okta.com/oauth2/default/v1/keys'
    EXTERNAL_OAUTH_AUDIENCE_LIST = ('your-snowflake-account')
    EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'sub'
    EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'LOGIN_NAME';

-- For Azure AD
CREATE OR REPLACE SECURITY INTEGRATION azure_ad_oauth
    TYPE = EXTERNAL_OAUTH
    ENABLED = TRUE
    EXTERNAL_OAUTH_TYPE = AZURE
    EXTERNAL_OAUTH_ISSUER = 'https://login.microsoftonline.com/{tenant-id}/v2.0'
    EXTERNAL_OAUTH_JWS_KEYS_URL = 'https://login.microsoftonline.com/{tenant-id}/discovery/v2.0/keys'
    EXTERNAL_OAUTH_AUDIENCE_LIST = ('your-snowflake-account');
```

---

## 4. Data Security

### 4.1 Implement Column-Level Security with Masking Policies

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3, SC-28

#### Description
Apply dynamic data masking to sensitive columns (PII, financial data) to restrict visibility based on user role.

#### ClickOps Implementation

```sql
-- Create masking policy for SSN
CREATE OR REPLACE MASKING POLICY ssn_mask AS (val STRING)
RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('PII_ADMIN') THEN val
        ELSE 'XXX-XX-' || RIGHT(val, 4)
    END;

-- Apply to column
ALTER TABLE customers MODIFY COLUMN ssn
    SET MASKING POLICY ssn_mask;

-- Create masking policy for email
CREATE OR REPLACE MASKING POLICY email_mask AS (val STRING)
RETURNS STRING ->
    CASE
        WHEN CURRENT_ROLE() IN ('PII_ADMIN', 'CUSTOMER_SERVICE') THEN val
        ELSE REGEXP_REPLACE(val, '(.)[^@]*(@.*)', '\\1***\\2')
    END;

ALTER TABLE customers MODIFY COLUMN email
    SET MASKING POLICY email_mask;
```

---

### 4.2 Enable Row Access Policies

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3

#### Description
Implement row-level security to restrict data visibility based on user attributes (department, region, customer assignment).

```sql
-- Create row access policy
CREATE OR REPLACE ROW ACCESS POLICY region_access AS (region_col VARCHAR)
RETURNS BOOLEAN ->
    CURRENT_ROLE() IN ('DATA_ADMIN')
    OR region_col = CURRENT_SESSION()::JSON:region;

-- Apply to table
ALTER TABLE sales ADD ROW ACCESS POLICY region_access ON (region);
```

---

### 4.3 Restrict Data Sharing

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-21

#### Description
Audit and control Snowflake data sharing to external accounts. Prevent accidental data exposure via shares.

```sql
-- Audit existing shares
SHOW SHARES;

-- Review who has access
SHOW GRANTS ON SHARE customer_data_share;

-- Remove access
REVOKE USAGE ON DATABASE customers FROM SHARE customer_data_share;
```

---

## 5. Monitoring & Detection

### 5.1 Enable Comprehensive Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3, AU-6

#### Description
Configure access to SNOWFLAKE.ACCOUNT_USAGE schema for security monitoring and anomaly detection.

#### Detection Use Cases

**Anomaly 1: Failed Login Spike (Credential Stuffing Detection)**
```sql
SELECT
    DATE_TRUNC('hour', event_timestamp) as hour,
    user_name,
    client_ip,
    COUNT(*) as failed_attempts
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE is_success = 'NO'
    AND event_timestamp > DATEADD(day, -1, CURRENT_TIMESTAMP())
GROUP BY 1, 2, 3
HAVING COUNT(*) > 10
ORDER BY failed_attempts DESC;
```

**Anomaly 2: Bulk Data Export**
```sql
SELECT
    user_name,
    query_text,
    rows_produced,
    bytes_scanned,
    start_time
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE query_type = 'SELECT'
    AND rows_produced > 1000000
    AND start_time > DATEADD(day, -1, CURRENT_TIMESTAMP())
ORDER BY rows_produced DESC;
```

**Anomaly 3: New IP Address Access**
```sql
WITH historical_ips AS (
    SELECT DISTINCT user_name, client_ip
    FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
    WHERE event_timestamp < DATEADD(day, -7, CURRENT_TIMESTAMP())
)
SELECT DISTINCT l.user_name, l.client_ip, l.event_timestamp
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY l
LEFT JOIN historical_ips h ON l.user_name = h.user_name AND l.client_ip = h.client_ip
WHERE l.event_timestamp > DATEADD(day, -1, CURRENT_TIMESTAMP())
    AND h.client_ip IS NULL
    AND l.is_success = 'YES';
```

**Anomaly 4: Privilege Escalation**
```sql
SELECT
    query_text,
    user_name,
    role_name,
    start_time
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE (query_text ILIKE '%GRANT%ACCOUNTADMIN%'
    OR query_text ILIKE '%ALTER USER%ACCOUNTADMIN%')
    AND start_time > DATEADD(day, -1, CURRENT_TIMESTAMP());
```

---

### 5.2 Forward Logs to SIEM

**Profile Level:** L1 (Baseline)

#### Description
Export Snowflake audit logs to SIEM (Splunk, Datadog, Sumo Logic) for real-time alerting and correlation.

```sql
-- Create task to export logs to S3/Azure Blob for SIEM ingestion
CREATE OR REPLACE TASK export_login_history
    WAREHOUSE = security_wh
    SCHEDULE = '60 MINUTE'
AS
    COPY INTO @security_logs/login_history/
    FROM (
        SELECT *
        FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
        WHERE event_timestamp > DATEADD(minute, -60, CURRENT_TIMESTAMP())
    )
    FILE_FORMAT = (TYPE = JSON);

ALTER TASK export_login_history RESUME;
```

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Integration | Risk Level | OAuth Scopes | Recommended Controls |
|------------|------------|--------------|---------------------|
| **Tableau** | High | Full data access | IP restriction, role blocking, token rotation |
| **Power BI** | High | Full data access | Gateway IP allowlist, limited roles |
| **Looker** | High | Full data access | Service account, IP restriction |
| **dbt Cloud** | High | Write access | Service account, key-pair auth |
| **Fivetran** | Medium | Specific schemas | Limited role, source restrictions |

### 6.2 Tableau Integration Hardening

**Controls:**
- ✅ Create dedicated service account with key-pair auth
- ✅ Restrict to Tableau Server IPs only
- ✅ Block admin roles from OAuth
- ✅ Limit to specific databases/schemas
- ✅ Enable query tagging for monitoring

```sql
-- Create restricted role for Tableau
CREATE ROLE tableau_reader;
GRANT USAGE ON WAREHOUSE bi_warehouse TO ROLE tableau_reader;
GRANT USAGE ON DATABASE analytics TO ROLE tableau_reader;
GRANT USAGE ON ALL SCHEMAS IN DATABASE analytics TO ROLE tableau_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA analytics.dashboards TO ROLE tableau_reader;

-- Create service account
CREATE USER svc_tableau
    DEFAULT_ROLE = tableau_reader
    DEFAULT_WAREHOUSE = bi_warehouse
    RSA_PUBLIC_KEY = 'MIIBIjAN...';

-- Apply network policy
ALTER USER svc_tableau SET NETWORK_POLICY = tableau_only;
```

---

## 7. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Snowflake Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA enforcement | 1.1 |
| CC6.2 | RBAC with custom roles | 1.3 |
| CC6.6 | Network policies | 2.1 |
| CC7.2 | Login/query history monitoring | 5.1 |

### PCI DSS Mapping

| Control | Snowflake Control | Guide Section |
|---------|------------------|---------------|
| 8.3.1 | MFA for all access | 1.1 |
| 7.1 | Role-based access | 1.3 |
| 10.2 | Audit logging | 5.1 |
| 3.4 | Column masking | 4.1 |

---

## Appendix A: Edition Compatibility

| Control | Standard | Enterprise | Business Critical | VPS |
|---------|----------|------------|-------------------|-----|
| MFA | ✅ | ✅ | ✅ | ✅ |
| Network Policies | ✅ | ✅ | ✅ | ✅ |
| Dynamic Masking | ❌ | ✅ | ✅ | ✅ |
| Row Access Policies | ❌ | ✅ | ✅ | ✅ |
| PrivateLink | ❌ | ❌ | ✅ | ✅ |
| Tri-Secret Secure | ❌ | ❌ | ✅ | ✅ |
| Customer-Managed Keys | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Snowflake Documentation:**
- [Trust Center](https://trust.snowflake.com/)
- [Snowflake Documentation](https://docs.snowflake.com/)
- [Securing Snowflake](https://docs.snowflake.com/en/guides-overview-secure)
- [Security Overview and Best Practices](https://community.snowflake.com/s/article/Snowflake-Security-Overview-and-Best-Practices)
- [Network Policies](https://docs.snowflake.com/en/user-guide/network-policies)
- [MFA Migration Best Practices](https://docs.snowflake.com/en/user-guide/security-mfa-migration-best-practices)
- [OAuth Overview](https://docs.snowflake.com/en/user-guide/oauth-snowflake-overview)
- [CIS Benchmark for Snowflake](https://www.cisecurity.org/benchmark/snowflake)

**API & Developer Tools:**
- [REST API Reference](https://docs.snowflake.com/en/developer-guide/snowflake-rest-api/reference)
- [Python Connector](https://docs.snowflake.com/en/developer-guide/python-connector/python-connector)
- [Native SDK for Connectors](https://docs.snowflake.com/en/developer-guide/native-apps/connector-sdk/about-connector-sdk)

**Compliance Frameworks:**
- SOC 1 Type II, SOC 2 Type II, ISO 27001:2022, ISO 27017, ISO 27018, FedRAMP Moderate (SnowGov), FedRAMP High (by request), PCI DSS, HITRUST CSF, IRAP, C5, DoD IL5 -- via [Regulatory Compliance Docs](https://docs.snowflake.com/en/user-guide/intro-compliance)
- [Security & Compliance Reports](https://www.snowflake.com/en/legal/snowflakes-security-and-compliance-reports/)

**Security Incidents:**
- (2024) UNC5537 threat actor campaign used credential stuffing against Snowflake customer accounts lacking MFA. 165+ organizations affected including AT&T, Ticketmaster, Santander, and LendingTree. Over 500 million individuals had data exposed. AT&T paid $370,000 ransom. Root cause: customer accounts without MFA -- not a Snowflake platform breach.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial Snowflake hardening guide | Claude Code (Opus 4.5) |
