---
layout: guide
title: "BambooHR Hardening Guide"
vendor: "BambooHR"
slug: "bamboohr"
tier: "5"
category: "HR/Finance"
description: "HR platform security for API keys, access levels, and sensitive field protection"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-12-14"
---


## Overview

BambooHR is a cloud-based HR platform managing employee records, benefits, and performance data. REST API, webhook integrations, and third-party app marketplace access sensitive employee PII. Compromised access exposes SSN, compensation data, and performance reviews.

### Intended Audience
- Security engineers managing HR systems
- BambooHR administrators
- GRC professionals assessing HR compliance
- Third-party risk managers evaluating HRIS integrations


### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries


### Scope
This guide covers BambooHR security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-2(1)

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Settings → Security → Single Sign-On**
2. Configure SAML IdP
3. Enable SSO requirement

**Step 2: Enable 2FA**
1. Navigate to: **Settings → Security**
2. Enable: **Require 2FA**
3. Configure backup methods

---

### 1.2 Access Level Configuration

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AC-3, AC-6

#### ClickOps Implementation

**Step 1: Define Access Levels**

| Level | Permissions |
|-------|-------------|
| Admin | Full access |
| HR Manager | HR functions |
| Manager | Team access |
| Employee | Self-service |

**Step 2: Configure Field Permissions**
1. Navigate to: **Settings → Access Levels**
2. Create custom access levels
3. Configure field-level visibility

---

## 2. API Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Baseline)
**NIST 800-53:** IA-5

#### Description
Manage BambooHR API keys securely.

#### Rationale
**Attack Scenario:** Compromised API key enables full employee database export; SSN, compensation, and personal data exposed.

#### ClickOps Implementation

**Step 1: Audit API Keys**
1. Navigate to: **Settings → API Keys**
2. Review all active keys
3. Remove unused keys

**Step 2: Key Best Practices**
1. Create separate keys per integration
2. Document key purposes
3. Rotate keys annually

---

### 2.2 Third-Party App Security

**Profile Level:** L1 (Baseline)
**NIST 800-53:** CM-7

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Apps → Installed Apps**
2. Review all connected apps
3. Remove unused integrations

**Step 2: App Approval**
1. Require admin approval for new apps
2. Review OAuth scopes
3. Audit app access quarterly

---

## 3. Data Security

### 3.1 Protect Sensitive Fields

**Profile Level:** L1 (Baseline)
**NIST 800-53:** SC-28

#### ClickOps Implementation

**Step 1: Configure Field Security**
1. Navigate to: **Settings → Employee Fields**
2. Identify sensitive fields (SSN, salary, bank info)
3. Restrict visibility by access level

**Step 2: Mask Sensitive Data**
1. Configure SSN masking
2. Limit bank account visibility
3. Audit sensitive data access

---

### 3.2 Report Security

**Profile Level:** L2 (Hardened)
**NIST 800-53:** AC-21

#### ClickOps Implementation

**Step 1: Restrict Report Access**
1. Navigate to: **Reports**
2. Limit who can create reports
3. Restrict report sharing

---

## 4. Monitoring & Detection

### 4.1 Activity Monitoring

**Profile Level:** L1 (Baseline)
**NIST 800-53:** AU-2, AU-3

#### ClickOps Implementation

**Step 1: Review Login History**
1. Navigate to: **Settings → Security → Login History**
2. Monitor failed logins
3. Investigate suspicious access

#### Detection Focus

```sql
-- Detect bulk data exports
SELECT user_email, report_name, record_count
FROM bamboo_activity
WHERE action = 'report_export'
  AND record_count > 100
  AND timestamp > NOW() - INTERVAL '24 hours';

-- Detect API abuse
SELECT api_key, endpoint, COUNT(*) as calls
FROM api_log
WHERE timestamp > NOW() - INTERVAL '1 hour'
GROUP BY api_key, endpoint
HAVING COUNT(*) > 500;
```

---

## Appendix A: Edition Compatibility

| Control | Essentials | Advantage |
|---------|------------|-----------|
| SAML SSO | Add-on | ✅ |
| 2FA | ✅ | ✅ |
| Custom Access Levels | ✅ | ✅ |
| API Access | ✅ | ✅ |

---

## Appendix B: References

**Official BambooHR Documentation:**
- [Trust Center](https://trust.bamboohr.com/) (powered by SafeBase)
- [Security](https://www.bamboohr.com/legal/security)
- [BambooHR Help Center](https://help.bamboohr.com/s/)
- [Third-Party SAML](https://help.bamboohr.com/s/article/587788)
- [BambooHR SAML SSO with Okta](https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-BambooHR.html)
- [BambooHR SSO with Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/saas-apps/bamboo-hr-tutorial)
- [Data Processing Agreement](https://www.bamboohr.com/legal/data-processing-agreement)

**API & Developer Tools:**
- [API Getting Started](https://documentation.bamboohr.com/docs/getting-started)
- [API Documentation](https://documentation.bamboohr.com/)
- [Official PHP SDK](https://github.com/BambooHR/bhr-api-php) (MIT license)
- [Official SDKs Overview](https://documentation.bamboohr.com/docs/sdks)
- [GitHub Organization](https://github.com/BambooHR)

**Compliance Frameworks:**
- SOC 1 and SOC 2 Type II (annual third-party audits) — via [Trust Center](https://trust.bamboohr.com/)
- Records maintained in accordance with ISO 27001 standards — via [Security Page](https://www.bamboohr.com/legal/security)
- Third-party penetration testing; Defense in Depth and Zero Trust security models
- Industry-standard encryption for data at rest and in transit

**Security Incidents:**
- **February 2019 — TRAXPayroll Breach:** An unauthorized third party accessed TRAXPayroll (a BambooHR-related payroll service) between February 5-13, 2019, exposing employee names, SSNs, states of residence, wage types, and tax codes. The attacker attempted to redirect payroll deposits. The BambooHR core platform was not breached. ([DataBreaches.net Report](https://databreaches.net/bamboohr-discloses-breach-involving-traxpayroll/))
- No major public security incidents identified for the BambooHR core platform in the 2023-2025 timeframe.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-12-14 | 0.1.0 | draft | Initial BambooHR hardening guide | Claude Code (Opus 4.5) |
