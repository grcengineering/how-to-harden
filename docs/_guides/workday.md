---
layout: guide
title: "Workday Hardening Guide"
vendor: "Workday"
slug: "workday"
tier: "2"
category: "HR/Finance"
description: "HCM platform hardening for security groups, integration security, and domain policies"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

**60%+ of Fortune 500** rely on Workday for HR and financial management, processing **365 billion transactions annually**. Integration System Users (ISUs) with OAuth access handle payroll, employee PII (SSN, bank accounts), and compensation data. Non-expiring refresh tokens amplify token theft risk. The 2024 Broadcom employee data breach via ransomware attack on ADP/Workday partner Business Systems House demonstrated third-party ecosystem vulnerabilities.

### Intended Audience
- Security engineers hardening HCM systems
- HR technology administrators
- GRC professionals assessing HR compliance
- Third-party risk managers evaluating payroll integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)
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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure Workday security groups with least-privilege access to HR and financial data.

#### Rationale
**Why This Matters:**
- Workday security groups govern who can view and modify HR, payroll, and financial data — over-broad groups grant standing access far beyond business need
- Least-privilege domain security policies contain the blast radius when any single account is compromised
- Segregation of duties between payroll input and payroll approval prevents one person from both initiating and authorizing fraudulent payments

**Attack Prevented:** Privilege escalation, insider fraud, lateral movement, excessive data exposure

#### ClickOps Implementation

**Step 1: Design Security Group Structure**

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-12

#### Description
Configure session timeout and management policies.

#### Rationale
**Why This Matters:**
- Idle Workday sessions left open on unattended or shared workstations let anyone resume an authenticated session to sensitive PII
- Short timeouts and re-authentication on extension limit the window an attacker has to use a hijacked or stolen session
- Concurrent-session limits make it harder for a stolen credential to be used alongside the legitimate user without detection

**Attack Prevented:** Session hijacking, unattended-workstation takeover, credential reuse

#### ClickOps Implementation

1. Navigate to: **Edit Tenant Setup - Security**
2. Configure:
   - **Session timeout:** 30 minutes (L1) / 15 minutes (L2)
   - **Concurrent sessions:** Limited
   - **Session extension:** Require re-authentication

---

## 2. Integration System User Security

### 2.1 Secure Integration System Users (ISUs)

**Profile Level:** L1 (Crawl) - CRITICAL
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
For each integration, create dedicated ISU.

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5(13)

#### Description
Configure OAuth token policies for integration authentication.

#### Rationale
**Why This Matters:**
- Long-lived or non-expiring refresh tokens for integrations are high-value targets that grant bulk programmatic access to employee data
- Short token lifetimes and regular client-secret rotation shrink the useful lifespan of any leaked credential
- Scoping each OAuth client to the minimum required APIs limits what a stolen token can reach
- Monitoring token issuance and revoking anomalous tokens enables fast containment of a compromise

**Attack Prevented:** Token theft, refresh-token abuse, bulk data exfiltration, replay attacks

#### ClickOps Implementation

**Step 1: Configure OAuth Clients**
1. Navigate to: **Register API Client**
2. For each integration:
   - **Grant type:** Client Credentials (M2M)
   - **Scope:** Minimum required APIs
   - **Token expiration:** 1 hour access token, 7 days refresh (L1) / 24h refresh (L2)

**Step 2: Rotate Client Secrets**

| Integration Type | Rotation Frequency |
|------------------|--------------------|
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

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3

#### Description
Restrict access to sensitive fields based on business need.

#### Rationale
**Why This Matters:**
- Fields like SSN, bank account, and compensation are the most damaging data in the tenant and are often exposed to far more roles than need them
- Field-level restrictions and masking ensure most users see only the data their job requires, even within reports they can otherwise run
- Logging access to sensitive fields creates the audit trail needed to detect and investigate misuse

**Attack Prevented:** PII exposure, identity theft, insider data harvesting, over-broad data access

#### ClickOps Implementation

**Step 1: Identify Sensitive Fields**

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

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-12

#### Description
Implement data retention policies aligned with legal requirements.

#### Rationale
**Why This Matters:**
- Data retained beyond its legal or business need expands the volume of PII exposed in any future breach
- Automated purging of expired records reduces standing liability and supports privacy obligations such as right-to-erasure
- Clear retention schedules prevent stale employment, payroll, and performance records from accumulating as an unmanaged data hoard

**Attack Prevented:** Excessive data exposure, regulatory non-compliance, breach blast-radius amplification

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-6

#### Description
Limit API access to minimum required scopes.

#### Rationale
**Why This Matters:**
- Over-scoped API clients can read and write far more data than their integration needs, magnifying the impact of a compromised client
- Granting only the specific scopes required — for example, Staffing and Payroll for a payroll export — contains what a stolen credential can touch
- Annual scope review with documented justification prevents permission creep as integrations evolve

**Attack Prevented:** Excessive privilege, bulk data exfiltration, scope abuse via compromised integrations

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

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Harden custom Workday Studio integrations.

#### Rationale
**Why This Matters:**
- Custom Studio integrations are application code that can embed hardcoded credentials, mishandle errors, or leak sensitive data if not reviewed
- Using ISU authentication and vault-stored secrets instead of embedded credentials prevents secret sprawl in integration definitions
- Integration audit logging and data-volume anomaly alerting surface compromised or misbehaving connectors before large-scale data loss

**Attack Prevented:** Hardcoded-credential theft, data leakage, supply-chain compromise of custom integrations

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Configure comprehensive audit logging for Workday operations.

#### Rationale
**Why This Matters:**
- Without comprehensive sign-on, data-access, and configuration-change logging, malicious activity in the tenant goes undetected
- Exporting audit logs to a SIEM enables correlation, alerting, and retention beyond what the platform retains natively
- Real-time webhooks on critical events shorten the time to detect and respond to account compromise or privilege changes

**Attack Prevented:** Undetected intrusion, delayed incident response, audit-trail tampering, insider abuse

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
- [Workday Trust -- Security](https://www.workday.com/en-us/why-workday/trust/security.html)
- [Workday Trust -- Compliance](https://www.workday.com/en-us/why-workday/trust/compliance.html)
- [Workday Trust -- Privacy](https://www.workday.com/en-us/why-workday/trust/privacy.html)
- [Workday Documentation Portal](https://doc.workday.com/)
- [Workday Community API Reference](https://community.workday.com/api)
- [Workday SAML SSO with Okta](https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-Workday.html)
- [Workday SSO with Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/saas-apps/workday-tutorial)

**API Documentation:**
- [Workday REST API](https://community.workday.com/sites/default/files/file-hosting/productionapi/index.html)
- [Workday Community API](https://community.workday.com/api)

**Compliance Frameworks:**
- SOC 1, SOC 2 (all five Trust Services Criteria plus NIST CSF and NIST 800-171 via SOC 2+), ISO 27001 (continuously certified since 2010), ISO 27017, ISO 27701 -- via [Workday Compliance](https://www.workday.com/en-us/why-workday/trust/compliance.html)

**Third-Party Security Guides:**
- [Mastering Workday Security](https://www.valencesecurity.com/saas-security-terms/mastering-workday-security-a-practical-guide-for-effective-management)

**Security Incidents:**
- **2024 -- Broadcom/BSH Partner Breach:** Partner Business Systems House (BSH) was compromised via ransomware, exposing employee data from ADP/Workday integrations. Demonstrates third-party ecosystem vulnerability rather than a direct Workday platform compromise.
- **August 2025 -- CRM Social Engineering Campaign:** Threat actors accessed Workday's third-party CRM platform (Salesforce) as part of a broader social engineering campaign, stealing primarily business contact information. No access to customer Workday tenants or tenant data was reported. Discovered August 6, disclosed August 15, 2025.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Workday hardening guide | Claude Code (Opus 4.5) |
