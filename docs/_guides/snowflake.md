---
layout: guide
title: "Snowflake Hardening Guide"
vendor: "Snowflake"
slug: "snowflake"
tier: "1"
category: "Data"
description: "Data warehouse security including network policies, MFA enforcement, and access controls"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-02-19"
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
|--------|--------------|---------|
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


{% include pack-code.html vendor="snowflake" section="1.1" %}

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

**Step 1: Generate RSA Key Pair** using OpenSSL to create a 2048-bit private key and extract the public key in Snowflake format.

**Step 2: Configure User with Key-Pair** by assigning the public key to the service account and removing its password.

**Step 3: Update Application Connection** to use the private key file instead of a password.

{% include pack-code.html vendor="snowflake" section="1.2" %}

---

### 1.3 Implement RBAC with Custom Roles

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Create granular role hierarchy instead of granting broad SYSADMIN or ACCOUNTADMIN access. Implement least privilege for data access.

#### ClickOps Implementation

**Step 1: Design Role Hierarchy**
1. Navigate to: **Admin --> Account --> Roles**
2. Create functional roles (data_analyst, data_engineer, security_admin)
3. Create object access roles (sales_data_reader, sales_data_writer, pii_data_reader)
4. Grant object access roles to functional roles
5. Grant functional roles to users

**Step 2: Restrict ACCOUNTADMIN**
1. Navigate to: **Admin --> Account --> Roles --> ACCOUNTADMIN**
2. Review all members with ACCOUNTADMIN access
3. Remove unnecessary ACCOUNTADMIN grants
4. Document break-glass procedure for emergency admin access

---


{% include pack-code.html vendor="snowflake" section="1.3" %}

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

#### Validation & Testing
```sql
-- Test from allowed IP - should succeed
SELECT CURRENT_USER();

-- View network policy assignments
SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN ACCOUNT;
SHOW PARAMETERS LIKE 'NETWORK_POLICY' IN USER svc_tableau;
```

---


{% include pack-code.html vendor="snowflake" section="2.1" %}

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
1. Create a new OAuth security integration for your BI tool
2. Set token refresh validity to 86400 seconds (1 day) instead of the 90-day default
3. Add ACCOUNTADMIN, SECURITYADMIN, and SYSADMIN to the blocked roles list

**Step 3: Block High-Privilege Roles from OAuth**
1. Edit the security integration to ensure ACCOUNTADMIN, SECURITYADMIN, SYSADMIN, and ORGADMIN are all in the blocked roles list
2. Verify no admin roles can authenticate via OAuth tokens

---


{% include pack-code.html vendor="snowflake" section="3.1" %}

### 3.2 Implement External OAuth (IdP Integration)

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-2(1)

#### Description
Configure External OAuth using your identity provider (Okta, Azure AD) for centralized authentication and MFA enforcement.

#### Code Implementation

{% include pack-code.html vendor="snowflake" section="3.2" %}

---

## 4. Data Security

### 4.1 Implement Column-Level Security with Masking Policies

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3, SC-28

#### Description
Apply dynamic data masking to sensitive columns (PII, financial data) to restrict visibility based on user role.

#### ClickOps Implementation

**Step 1: Create Masking Policies**
1. Navigate to: **Data --> Databases --> [Database] --> Policies**
2. Create masking policy for SSN that returns full value for PII_ADMIN role, masked value (XXX-XX-####) for all others
3. Create masking policy for email that returns full value for PII_ADMIN and CUSTOMER_SERVICE roles, masked value for all others

**Step 2: Apply Masking Policies to Columns**
1. Navigate to the target table and column
2. Set the SSN masking policy on the ssn column
3. Set the email masking policy on the email column

---


{% include pack-code.html vendor="snowflake" section="4.1" %}

### 4.2 Enable Row Access Policies

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3

#### Description
Implement row-level security to restrict data visibility based on user attributes (department, region, customer assignment).

{% include pack-code.html vendor="snowflake" section="4.2" %}

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

Key anomaly detection queries are provided in the code pack below. These cover:

- **Anomaly 1: Failed Login Spike** -- Detect credential stuffing by identifying users/IPs with 10+ failed logins per hour
- **Anomaly 2: Bulk Data Export** -- Flag SELECT queries returning 1M+ rows (potential exfiltration)
- **Anomaly 3: New IP Address Access** -- Identify successful logins from IPs not seen in the prior 7 days
- **Anomaly 4: Privilege Escalation** -- Monitor for GRANT or ALTER statements targeting ACCOUNTADMIN

---


{% include pack-code.html vendor="snowflake" section="5.1" %}

### 5.2 Forward Logs to SIEM

**Profile Level:** L1 (Baseline)

#### Description
Export Snowflake audit logs to SIEM (Splunk, Datadog, Sumo Logic) for real-time alerting and correlation.

{% include pack-code.html vendor="snowflake" section="5.2" %}

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

{% include pack-code.html vendor="snowflake" section="6.2" %}

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
| 2026-02-19 | 0.2.0 | draft | Migrate inline code to Code Packs (sections 1.2, 3.2, 4.2, 5.2, 6.2) | Claude Code (Opus 4.6) |
| 2025-12-14 | 0.1.0 | draft | Initial Snowflake hardening guide | Claude Code (Opus 4.5) |
