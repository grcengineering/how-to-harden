---
layout: guide
title: "NetSuite Hardening Guide"
vendor: "NetSuite"
slug: "netsuite"
tier: "2"
category: "Data"
description: "ERP security for role-based access, SuiteScript controls, and integration hardening"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

NetSuite serves **43,000+ customers** with the SuiteCloud platform hosting **600+ SuiteApp integrations**. Token-based authentication (TBA) for third-party apps, if not rotated quarterly, creates persistent access to financial records, customer payment data, and inventory systems. As a cloud ERP containing financial data, NetSuite is a high-value target for attackers seeking billing fraud or financial data exfiltration.

### Intended Audience
- Security engineers hardening ERP systems
- Finance IT administrators
- GRC professionals assessing financial system compliance
- Third-party risk managers evaluating SuiteApp integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers NetSuite security configurations including authentication, SuiteApp governance, token management, and financial data protection.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Token-Based Authentication Security](#2-token-based-authentication-security)
3. [SuiteApp & Integration Security](#3-suiteapp--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### Description
Require 2FA for all NetSuite users, especially those with financial data access.

#### ClickOps Implementation

**Step 1: Configure 2FA**
1. Navigate to: **Setup → Company → Two-Factor Authentication**
2. Enable: **Require 2FA for all roles**
3. Configure methods:
   - Authenticator app (recommended)
   - SMS (not recommended)
   - Email (backup only)

**Step 2: Role-Based 2FA**
1. Navigate to: **Setup → Users/Roles → Manage Roles**
2. For each role, configure:
   - **Require Two-Factor Authentication:** Yes

**Step 3: Configure Session Timeout**
1. Navigate to: **Setup → Company → General Preferences**
2. Set: **Session timeout:** 30 minutes (L1) / 15 minutes (L2)

---

### 1.2 Implement Role-Based Access Control

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### Description
Configure NetSuite roles with least-privilege access to financial data.

#### ClickOps Implementation

**Step 1: Design Role Structure**

{% include pack-code.html vendor="netsuite" section="1.2" %}

**Step 2: Configure Role Permissions**
1. Navigate to: **Setup → Users/Roles → Manage Roles**
2. For each role:
   - Select specific permissions
   - Restrict subsidiary access
   - Limit report access

**Step 3: Implement Segregation of Duties**
- Separate payment creation from approval
- Separate journal entry creation from posting
- Document and monitor conflicting roles

---

### 1.3 Configure IP Address Rules

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3(7)

#### Description
Restrict NetSuite access to known IP addresses.

#### ClickOps Implementation

**Step 1: Configure IP Address Rules**
1. Navigate to: **Setup → Company → Company Information → Access**
2. Add IP address rules:
   - Corporate network ranges
   - VPN egress IPs
   - Approved integration IPs

**Step 2: Role-Based IP Restrictions**
1. Navigate to: **Setup → Users/Roles → Manage Roles**
2. For sensitive roles (Administrator, Financial Controller):
   - Configure specific IP restrictions

---

## 2. Token-Based Authentication Security

### 2.1 Secure TBA Configuration

**Profile Level:** L1 (Baseline) - CRITICAL
**NIST 800-53:** IA-5

#### Description
Harden Token-Based Authentication (TBA) for API integrations.

#### Rationale
**Why This Matters:**
- TBA tokens provide persistent API access
- Static tokens don't expire without rotation
- Compromised tokens enable financial data extraction

**Attack Scenario:** Static integration token enables extraction of financial statements and credit card data.

#### ClickOps Implementation

**Step 1: Audit Existing Tokens**
1. Navigate to: **Setup → Users/Roles → Access Tokens**
2. Review all active tokens:
   - Creation date
   - Associated user/role
   - Integration purpose
3. Identify tokens older than 90 days

**Step 2: Create Role-Specific Integration Users**
1. Create dedicated integration users:
   - `INT-Salesforce` (CRM sync)
   - `INT-Payroll` (payroll export)
   - `INT-Reporting` (BI tool)
2. Assign minimal required permissions

**Step 3: Implement Token Rotation**

| Token Type | Rotation Frequency |
|------------|--------------------|
| Production integrations | Quarterly |
| Development tokens | Monthly |
| One-time exports | Immediately after use |

**Step 4: Configure TBA Settings**
1. Navigate to: **Setup → Company → Enable Features → SuiteCloud**
2. Review: **Token-Based Authentication**
3. Limit: Who can create tokens (Administrators only)

---

### 2.2 OAuth 2.0 for SuiteApps

**Profile Level:** L2 (Hardened)
**NIST 800-53:** IA-5(13)

#### Description
Prefer OAuth 2.0 over TBA for SuiteApp authentication.

#### Implementation

For new integrations:
1. Use OAuth 2.0 authorization code flow
2. Configure short token lifetimes
3. Implement token refresh

---

## 3. SuiteApp & Integration Security

### 3.1 SuiteApp Approval Workflow

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### Description
Implement approval process for SuiteApp installations.

#### ClickOps Implementation

**Step 1: Review Installed SuiteApps**
1. Navigate to: **Customization → SuiteBundler → Search & Install Bundles**
2. Review installed bundles:
   - Installation date
   - Permissions required
   - Business justification

**Step 2: Create Approval Process**
Before installing any SuiteApp:
- [ ] Review bundle permissions
- [ ] Check vendor security certifications
- [ ] Evaluate data access requirements
- [ ] Document business justification
- [ ] Test in sandbox first

**Step 3: Restrict Installation**
1. Limit bundle installation to Administrators
2. Require change management approval
3. Document all installations

---

### 3.2 RESTlet and SuiteScript Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** CM-7

#### Description
Secure custom RESTlets and SuiteScripts.

#### Best Practices

{% include pack-code.html vendor="netsuite" section="3.2" %}

---

## 4. Data Security

### 4.1 Field-Level Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-3

#### Description
Restrict access to sensitive financial fields.

#### ClickOps Implementation

**Step 1: Identify Sensitive Fields**
- Credit card numbers
- Bank account details
- SSN/Tax IDs
- Salary information

**Step 2: Configure Field Restrictions**
1. Navigate to: **Customization → Forms → Entry Forms**
2. For sensitive fields:
   - Hide from unauthorized roles
   - Enable encryption where available

---

### 4.2 Audit Trail Configuration

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2

#### Description
Enable comprehensive audit trails for financial transactions.

#### ClickOps Implementation

**Step 1: Configure System Notes**
1. Navigate to: **Setup → Company → General Preferences**
2. Enable: **System Notes for all transactions**

**Step 2: Configure Login Audit Trail**
1. Navigate to: **Setup → Company → Enable Features → SuiteCloud**
2. Enable: **Login Audit Trail**

---

## 5. Monitoring & Detection

### 5.1 Security Alerts

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SI-4

#### Detection Queries (via Saved Searches)

{% include pack-code.html vendor="netsuite" section="5.1" %}

---

## 6. Compliance Quick Reference

### SOC 2 Mapping

| Control ID | NetSuite Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | 2FA enforcement | 1.1 |
| CC6.2 | Role-based access | 1.2 |
| CC8.1 | Change management | 3.1 |

### SOX Compliance

- Implement segregation of duties
- Enable comprehensive audit trails
- Document access approvals
- Regular access reviews

---

## Appendix A: References

**Official NetSuite Documentation:**
- [NetSuite Operational Security](https://www.netsuite.com/portal/platform/infrastructure/operational-security.shtml)
- [NetSuite Product Documentation](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/index.html)
- [Security Best Practices](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/chapter_N285366.html)
- [Token-Based Authentication](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/section_4247337262.html)

**API Documentation:**
- [SuiteTalk REST Web Services](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/book_1559132836.html)
- [SuiteScript 2.x API Reference](https://docs.oracle.com/en/cloud/saas/netsuite/ns-online-help/set_1502135122.html)

**Compliance Frameworks:**
- SOC 1 Type II, SOC 2 Type II, ISO 27001, ISO 27018, PCI DSS, PA-DSS, TX-RAMP — via [NetSuite Operational Security](https://www.netsuite.com/portal/platform/infrastructure/operational-security.shtml)
- [NetSuite Compliance-Ready Audited Reports (PDF)](https://www.netsuite.com/portal/assets/pdf/wp-compliance-ready-ns-third-party-audited-reports.pdf)

**Security Incidents:**
- No major public security incidents specific to Oracle NetSuite identified. NetSuite operates within Oracle's broader security infrastructure. Monitor Oracle's [Security Alerts](https://www.oracle.com/security-alerts/) for current advisories.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial NetSuite hardening guide | Claude Code (Opus 4.5) |
