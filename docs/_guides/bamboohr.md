---
layout: guide
title: "BambooHR Hardening Guide"
vendor: "BambooHR"
slug: "bamboohr"
tier: "5"
category: "HR/Finance"
description: "HR platform security for API keys, access levels, and sensitive field protection"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

BambooHR is a cloud-based HR platform managing employee records, benefits, and performance data. REST API, webhook integrations, and third-party app marketplace access sensitive employee PII. Compromised access exposes SSN, compensation data, and performance reviews.

### Intended Audience
- Security engineers managing HR systems
- BambooHR administrators
- GRC professionals assessing HR compliance
- Third-party risk managers evaluating HRIS integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML single sign-on with multi-factor authentication for all BambooHR access, routing every login through your corporate identity provider.

#### Rationale
**Why This Matters:**
- Centralizes BambooHR authentication in your corporate IdP, enforcing MFA, conditional access, and session policy on every login
- Standalone BambooHR passwords bypass IdP controls and are prime targets for credential stuffing, phishing, and password reuse
- SSO lets you deprovision a departing employee once in the IdP rather than chasing every SaaS account, closing orphaned-access gaps
- BambooHR stores SSNs, compensation, bank details, and performance reviews, so a single compromised login can expose the entire HR record set

**Attack Prevented:** Credential theft, phishing, MFA bypass, password reuse, orphaned-account access

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define granular access levels and field-level permissions so each role (Admin, HR Manager, Manager, Employee) can see and edit only the employee data its job requires.

#### Rationale
**Why This Matters:**
- Enforces least privilege so a manager or employee account cannot read compensation, SSN, or records outside its scope
- Field-level permissions prevent broad over-sharing of sensitive PII to roles that have no business need for it
- Limits the blast radius of a single compromised or insider account to the data that role legitimately accesses
- Default or overly permissive access levels are a common cause of accidental PII exposure across HR platforms

**Attack Prevented:** Privilege escalation, insider data harvesting, unauthorized PII access, excessive-permission exposure

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Manage BambooHR API keys securely.

#### Rationale
**Attack Scenario:** Compromised API key enables full employee database export; SSN, compensation, and personal data exposed.

**Why This Matters:**
- BambooHR API keys often grant broad, programmatic read access to the full employee dataset with no interactive MFA prompt
- Separate keys per integration limit blast radius and let you revoke one integration without breaking the others
- Routine rotation and removal of unused keys shrinks the window a leaked or stale credential can be abused
- Documented key ownership makes anomalous API usage easier to detect and attribute during an incident

**Attack Prevented:** API key compromise, bulk employee-data exfiltration, credential sprawl, stale-key abuse

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review, approve, and periodically audit third-party apps and marketplace integrations connected to BambooHR, scrutinizing the OAuth scopes each one is granted.

#### Rationale
**Why This Matters:**
- Connected apps inherit OAuth access to employee data and become an extension of your attack surface
- Over-scoped or abandoned integrations provide a persistent, often unmonitored path to sensitive HR records
- Requiring admin approval prevents employees from silently authorizing risky apps that exfiltrate data
- A compromised or malicious marketplace vendor can abuse standing access without ever touching a user password

**Attack Prevented:** Supply-chain compromise, OAuth scope abuse, shadow-IT integrations, third-party data exfiltration

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

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Identify the most sensitive employee fields (SSN, compensation, and bank account details) and restrict their visibility and apply masking by access level.

#### Rationale
**Why This Matters:**
- SSNs, salary, and bank account numbers are the highest-value PII in the HR record and the primary target of attackers and insiders
- Restricting field visibility by role enforces need-to-know so most accounts never see this data at all
- Masking limits exposure even for authorized users and reduces what a screenshot, export, or shoulder-surf can reveal
- Concentrating protection on these fields aligns with privacy regulations and breach-notification thresholds for SSN and financial data

**Attack Prevented:** PII and SSN theft, payroll-redirect fraud, insider data harvesting, over-broad data exposure

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

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-21

#### Description
Restrict which users can build and share reports so bulk extracts of employee data cannot be created or distributed without authorization.

#### Rationale
**Why This Matters:**
- Reports can aggregate sensitive fields across the entire workforce into a single high-value export
- Uncontrolled report sharing can leak compensation or PII internally or externally beyond the intended audience
- Limiting report authors keeps bulk-data access tied to a small, accountable set of users
- Reporting tools are a common exfiltration path that bypasses the field-level controls applied to individual record views

**Attack Prevented:** Bulk data exfiltration, unauthorized report sharing, aggregation-based PII exposure

#### ClickOps Implementation

**Step 1: Restrict Report Access**
1. Navigate to: **Reports**
2. Limit who can create reports
3. Restrict report sharing

---

## 4. Monitoring & Detection

### 4.1 Activity Monitoring

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Review BambooHR login history and security logs to monitor failed logins and investigate suspicious or anomalous access to employee records.

#### Rationale
**Why This Matters:**
- Login and activity logs are the primary signal for detecting credential stuffing, account takeover, and insider misuse
- Monitoring failed logins surfaces brute-force and password-spray attempts before they succeed
- Timely review shortens attacker dwell time and supports forensic reconstruction after an incident
- Without active monitoring, unauthorized access to SSNs and compensation data can go undetected until it is reported externally

**Attack Prevented:** Undetected account takeover, brute-force and password-spray attacks, insider misuse, delayed breach detection

#### ClickOps Implementation

**Step 1: Review Login History**
1. Navigate to: **Settings → Security → Login History**
2. Monitor failed logins
3. Investigate suspicious access

#### Detection Focus

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
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial BambooHR hardening guide | Claude Code (Opus 4.5) |
