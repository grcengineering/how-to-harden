---
layout: guide
title: "Workday Hardening Guide"
vendor: "Workday"
slug: "workday"
tier: "2"
category: "HR/Finance"
description: "HCM platform hardening for security groups, integration security, and domain policies"
last_updated: "2025-12-14"
---


## Overview

**60%+ of Fortune 500** rely on Workday for HR and financial management, processing **365 billion transactions annually**. Integration System Users (ISUs) with OAuth access handle payroll, employee PII (SSN, bank accounts), and compensation data. Non-expiring refresh tokens amplify token theft risk. The 2024 Broadcom employee data breach via ransomware attack on ADP/Workday partner Business Systems House demonstrated third-party ecosystem vulnerabilities.

### Intended Audience
- Security engineers hardening HCM systems
- HR technology administrators
- GRC professionals assessing HR compliance
- Third-party risk managers evaluating payroll integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Workday security configurations including authentication, integration security, data privacy controls, and third-party connector hardening.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Integration System User Security](#2-integration-system-user-security)
3. [Data Security & Privacy](#3-data-security--privacy)
4. [API & Integration Security](#4-api--integration-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SAML SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Workday access, including employee self-service and administrator access.

#### Rationale
**Why This Matters:**
- Workday contains highly sensitive PII (SSN, bank accounts, salary)
- Compromised access enables payroll fraud and data theft
- Compliance requirements mandate strong authentication

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Authentication Policies**
2. Create/Edit Authentication Policy:
   - **Name:** "Corporate SSO"
   - **Authentication Type:** SAML
   - **Identity Provider:** Configure IdP metadata

**Step 2: Configure Security Groups**
1. Assign authentication policy to all security groups
2. Require MFA at IdP level for Workday application

**Step 3: Disable Alternative Authentication**
1. Disable native password authentication
2. Remove local account access (except break-glass)

---

### 1.2 Implement Role-Based Security Groups

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure Workday security groups with least-privilege access to HR and financial data.

#### ClickOps Implementation

**Step 1: Design Security Group Structure**
```
Security Groups:
├── HR Business Partner
│   └── View employee data for assigned organizations
├── Compensation Administrator
│   └── Manage compensation (restricted fields)
├── Benefits Administrator
│   └── Manage benefits enrollment
├── Payroll Administrator
│   └── Process payroll (segregation of duties)
├── Integration System User
│   └── API access for specific integrations
└── Security Administrator
    └── Manage security configuration
```

**Step 2: Configure Domain Security**
1. Navigate to: **Domain Security Policies**
2. For each functional area:
   - Define view/modify permissions
   - Assign to appropriate security groups
   - Enable "View" vs "Modify" separation

**Step 3: Implement Segregation of Duties**
- Separate payroll input from payroll approval
- Separate benefits setup from enrollment processing
- Document conflicts and implement compensating controls

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-12

#### Description
Configure session timeout and management policies.

#### ClickOps Implementation

1. Navigate to: **Edit Tenant Setup - Security**
2. Configure:
   - **Session timeout:** 30 minutes (L1) / 15 minutes (L2)
   - **Concurrent sessions:** Limited
   - **Session extension:** Require re-authentication

---

## 2. Integration System User Security

### 2.1 Secure Integration System Users (ISUs)

**Profile Level:** L1 (Baseline) - CRITICAL
**NIST 800-53:** IA-5, AC-6

#### Description
Harden Integration System Users that provide API access for third-party integrations.

#### Rationale
**Why This Matters:**
- ISUs access sensitive employee data programmatically
- OAuth tokens for ISUs can have long validity
- Compromised ISU = bulk data exfiltration capability

**Real-World Incident:**
- **2024 Broadcom Breach:** Partner Business Systems House (BSH) was compromised, exposing employee data from ADP/Workday integrations

#### ClickOps Implementation

**Step 1: Audit Existing ISUs**
1. Navigate to: **View Integration System Users**
2. Document for each ISU:
   - Purpose/integration
   - Security groups assigned
   - Data access scope
   - Last activity date

**Step 2: Create Purpose-Specific ISUs**
For each integration, create dedicated ISU:
```
ISU Architecture:
├── ISU-ADP-Payroll (payroll data only)
├── ISU-Benefits-Carrier (benefits data only)
├── ISU-HRIS-Reporting (read-only reporting)
├── ISU-Recruiting-ATS (applicant data only)
└── ISU-IT-Provisioning (worker provisioning)
```

**Step 3: Restrict ISU Security Groups**
1. Create integration-specific security groups
2. Grant minimum required domain permissions
3. Document data access justification

**Step 4: Configure ISU Authentication**
1. Navigate to: **Edit Integration System User**
2. Configure:
   - **Authentication:** OAuth 2.0 (not basic auth)
   - **Client credentials:** Store securely
   - **Token lifetime:** Minimum required

---

### 2.2 Implement OAuth Token Policies

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5(13)

#### Description
Configure OAuth token policies for integration authentication.

#### ClickOps Implementation

**Step 1: Configure OAuth Clients**
1. Navigate to: **Register API Client**
2. For each integration:
   - **Grant type:** Client Credentials (M2M)
   - **Scope:** Minimum required APIs
   - **Token expiration:** 1 hour access token, 7 days refresh (L1) / 24h refresh (L2)

**Step 2: Rotate Client Secrets**

| Integration Type | Rotation Frequency |
|-----------------|-------------------|
| Payroll connectors | Quarterly |
| Benefits integrations | Quarterly |
| Reporting tools | Semi-annually |
| Custom integrations | Quarterly |

**Step 3: Monitor Token Usage**
1. Review OAuth token issuance logs
2. Alert on unusual patterns
3. Revoke suspicious tokens immediately

---

## 3. Data Security & Privacy

### 3.1 Configure Field-Level Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3

#### Description
Restrict access to sensitive fields based on business need.

#### ClickOps Implementation

**Step 1: Identify Sensitive Fields**
```
High Sensitivity:
- Social Security Number
- Bank Account Numbers
- Salary/Compensation
- Performance Reviews
- Medical Information

Medium Sensitivity:
- Home Address
- Personal Email
- Emergency Contacts
- Birthdates
```

**Step 2: Configure Field Security**
1. Navigate to: **Domain Security Policies**
2. For sensitive fields:
   - Restrict "View" to specific security groups
   - Enable masking where applicable
   - Log all access

**Step 3: Enable Data Masking**
1. Configure SSN masking (show last 4 only)
2. Configure bank account masking
3. Document unmasked access requirements

---

### 3.2 Configure Data Retention

**Profile Level:** L2 (Hardened)
**NIST 800-53:** SI-12

#### Description
Implement data retention policies aligned with legal requirements.

#### ClickOps Implementation

1. Navigate to: **Data Retention Policies**
2. Configure retention by data type:
   - Employment records: Per jurisdiction requirements
   - Payroll data: 7 years (US)
   - Performance data: 3-5 years
3. Enable automated purging for expired data

---

## 4. API & Integration Security

### 4.1 Restrict API Scopes

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-6

#### Description
Limit API access to minimum required scopes.

#### Workday API Scopes

| Integration Need | Recommended Scopes |
|-----------------|-------------------|
| Payroll export | `Staffing`, `Payroll` |
| Benefits sync | `Benefits`, `Worker Profile` |
| Org chart | `Organizations`, `Worker Profile (limited)` |
| Reporting | `Reports`, specific report scopes |

#### ClickOps Implementation

1. Navigate to: **API Client Registration**
2. Select only required scopes
3. Document business justification
4. Review annually

---

### 4.2 Secure Workday Studio Integrations

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### Description
Harden custom Workday Studio integrations.

#### Best Practices

1. **Code Review:**
   - Review integration code before deployment
   - Check for hardcoded credentials
   - Validate error handling

2. **Credentials:**
   - Use ISU authentication (not embedded credentials)
   - Store secrets in Workday vault
   - Rotate credentials regularly

3. **Logging:**
   - Enable integration audit logging
   - Monitor for failures and anomalies
   - Alert on unexpected data volumes

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logging

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure comprehensive audit logging for Workday operations.

#### ClickOps Implementation

**Step 1: Configure Audit Settings**
1. Navigate to: **Edit Tenant Setup - Audit**
2. Enable:
   - Sign-on activity
   - Data access
   - Configuration changes
   - Integration activity

**Step 2: Export to SIEM**
1. Create scheduled integration to export audit logs
2. Configure real-time webhooks for critical events
3. Retain logs for compliance period

#### Detection Queries

```sql
-- Detect bulk data access
SELECT user_id, COUNT(*) as record_count
FROM workday_audit_log
WHERE action = 'View'
  AND object_type IN ('Worker', 'Compensation')
  AND timestamp > NOW() - INTERVAL '1 hour'
GROUP BY user_id
HAVING COUNT(*) > 100;

-- Detect ISU anomalies
SELECT isu_name, api_endpoint, COUNT(*) as call_count
FROM api_access_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY isu_name, api_endpoint
HAVING COUNT(*) > 1000;

-- Detect sensitive field access
SELECT user_id, field_name, worker_id
FROM field_access_log
WHERE field_name IN ('SSN', 'Bank_Account', 'Salary')
  AND timestamp > NOW() - INTERVAL '24 hours';
```

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | Workday Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO enforcement | 1.1 |
| CC6.2 | Security groups | 1.2 |
| CC6.7 | Data security | 3.1 |

### NIST 800-53 Mapping

| Control | Workday Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | SSO with MFA | 1.1 |
| AC-6 | ISU restrictions | 2.1 |
| AU-2 | Audit logging | 5.1 |

---

## Appendix A: References

**Official Workday Documentation:**
- [Security Administration Guide](https://doc.workday.com/reader/3tLmLg9E8qTxwPoBnzcqIw/~BLT~6~R)
- [Integration Security](https://doc.workday.com/reader/wsiU0cnNjCc_k7shLNxLEA)

**Incident Reference:**
- 2024 Broadcom/BSH partner breach affected employee data through Workday/ADP integrations

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-14 | 1.0 | Initial Workday hardening guide | How to Harden Community |
