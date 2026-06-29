---
layout: guide
title: "Rippling Hardening Guide"
vendor: "Rippling"
slug: "rippling"
tier: "5"
category: "HR/Finance"
description: "Workforce platform security for app provisioning, device management, and SCIM controls"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---


## Overview

Rippling is a unified workforce platform managing HR, IT, payroll, and spend. REST API, SSO configurations, and deep SaaS integrations through device management access employee PII, financial data, and IT systems. Compromised access has cascading effects across multiple business functions.

### Intended Audience
- Security engineers managing workforce platforms
- Rippling administrators
- GRC professionals assessing unified platform security
- Third-party risk managers evaluating HR/IT integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Rippling security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Integration Security](#2-integration-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Configure SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Rippling access, routing every login through your corporate identity provider and enforcing phishing-resistant second factors.

#### Rationale
**Why This Matters:**
- Centralizes Rippling authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local password logins bypass IdP controls and are a prime target for credential stuffing and phishing
- Rippling holds HR, payroll, IT, and spend data, so a single compromised admin login can cascade across every connected business function
- Phishing-resistant MFA (FIDO2/WebAuthn) defeats real-time proxy and push-fatigue attacks that bypass weaker factors

**Attack Prevented:** Credential theft, phishing, MFA bypass, account takeover

#### ClickOps Implementation

**Step 1: Configure SSO**
1. Navigate to: **Settings → Security → Single Sign-On**
2. Configure SAML IdP
3. Enable SSO enforcement

**Step 2: Enable MFA**
1. Navigate to: **Settings → Security → Multi-Factor Authentication**
2. Require MFA for all users
3. Configure phishing-resistant methods

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define least-privilege permission sets and custom roles so each administrator and employee can access only the HR, IT, finance, or self-service functions their job requires.

#### Rationale
**Why This Matters:**
- Rippling spans HR, payroll, device management, and spend, so broad admin grants give any single compromised account control over multiple business domains
- Least-privilege roles contain the blast radius of a stolen or misused credential to one functional area
- Separating HR, IT, and finance duties enforces segregation of duties and limits insider abuse
- Custom permission sets prevent privilege creep as employees change teams and accumulate access

**Attack Prevented:** Privilege escalation, lateral movement, insider abuse, excessive standing access

#### ClickOps Implementation

**Step 1: Define Permission Sets**

| Role | Permissions |
|------|-------------|
| Super Admin | Full access |
| HR Admin | HR/payroll functions |
| IT Admin | Device/app management |
| Finance Admin | Spend management |
| Manager | Team access |
| Employee | Self-service |

**Step 2: Configure Custom Roles**
1. Navigate to: **Settings → Permissions**
2. Create custom permission sets
3. Apply least privilege

---

## 2. Integration Security

### 2.1 App Management Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Secure Rippling app integrations.

#### Rationale
**Attack Scenario:** Compromised Rippling admin provisions access to connected apps; single compromise cascades across all integrated SaaS.

**Why This Matters:**
- Rippling acts as an identity and provisioning hub, so a compromised admin can grant or modify access across every connected SaaS application
- Unused or orphaned app integrations widen the attack surface and often retain standing OAuth grants long after they are needed
- Over-scoped SCIM auto-provisioning can silently push access or accounts into downstream apps without review
- Regular review of connected apps and deprovisioning flows ensures departed users lose access everywhere, not just in Rippling

**Attack Prevented:** Supply chain compromise, OAuth token abuse, orphaned-account access, over-provisioning

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Apps → Installed Apps**
2. Audit all connected applications
3. Remove unused integrations

**Step 2: SCIM Security**
1. Review SCIM provisioning
2. Limit auto-provisioning scope
3. Audit deprovisioning

---

### 2.2 Device Management Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Configure device management policies in Rippling IT to require enrollment and enforce baseline security controls on every endpoint that accesses workforce data.

#### Rationale
**Why This Matters:**
- Devices enrolled through Rippling access corporate apps and employee PII, so unmanaged endpoints are a direct path into sensitive data
- Enforced enrollment and security policies such as encryption, screen lock, and OS patching reduce data loss from lost or stolen devices
- Device posture checks let you block compromised or non-compliant endpoints before they reach connected SaaS
- Centralized device control supports rapid remote wipe and access revocation during offboarding or incidents

**Attack Prevented:** Endpoint compromise, data exfiltration from lost/stolen devices, non-compliant device access

#### ClickOps Implementation

**Step 1: Device Policies**
1. Navigate to: **IT → Device Management**
2. Configure security policies
3. Require device enrollment

---

## 3. Data Security

### 3.1 Protect Employee Data

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Restrict field-level visibility and reporting so sensitive employee data such as SSNs, bank accounts, and compensation is exposed only to roles with a legitimate need.

#### Rationale
**Why This Matters:**
- Rippling stores highly sensitive PII and financial data that carries legal, regulatory, and identity-theft consequences if exposed
- Field-level access controls enforce need-to-know and prevent managers or analysts from viewing data outside their scope
- Limiting bulk exports and report access stops large-scale data scraping by a single compromised or malicious account
- Auditing data access creates accountability and supports breach detection and compliance evidence

**Attack Prevented:** PII exposure, identity theft, mass data exfiltration, unauthorized data access

#### ClickOps Implementation

**Step 1: Configure Field Access**
1. Limit visibility of sensitive fields
2. Restrict SSN/bank account access
3. Configure manager visibility

**Step 2: Report Security**
1. Limit report access
2. Restrict bulk exports
3. Audit data access

---

### 3.2 Payroll Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Limit payroll administrator access and require approvals for payroll changes so direct-deposit and compensation modifications cannot be made by a single unchecked account.

#### Rationale
**Why This Matters:**
- Payroll controls direct-deposit destinations and pay amounts, making it a high-value target for financial fraud
- Restricting payroll admin access reduces the number of accounts that can redirect funds or alter compensation
- Requiring approval for payroll changes enforces dual control and catches fraudulent or erroneous edits before money moves
- Tight payroll permissions limit the damage an attacker or malicious insider can do with a single compromised credential

**Attack Prevented:** Payroll diversion fraud, direct-deposit hijacking, unauthorized compensation changes, insider fraud

#### ClickOps Implementation

**Step 1: Payroll Access**
1. Navigate to: **Settings → Permissions**
2. Limit payroll admin access
3. Require approval for changes

---

## 4. Monitoring & Detection

### 4.1 Audit Logs

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable and regularly review Rippling audit logs to capture administrative activity and configuration changes across HR, IT, payroll, and access management.

#### Rationale
**Why This Matters:**
- Audit logs provide the forensic record needed to detect, investigate, and scope unauthorized activity across Rippling's many functions
- Monitoring admin actions and configuration changes surfaces privilege abuse, suspicious provisioning, and policy weakening early
- Without comprehensive logging, attacker and insider activity goes unnoticed and breaches are impossible to reconstruct
- Retained audit trails support compliance obligations such as SOC 2 and ISO 27001 and provide incident response evidence

**Attack Prevented:** Undetected intrusion, insider abuse, audit-trail gaps, delayed breach detection

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Settings → Audit Logs**
2. Review admin activities
3. Monitor configuration changes

#### Detection Focus

---

## Appendix A: Feature Availability

| Control | Availability |
|---------|--------------|
| SAML SSO | ✅ |
| MFA | ✅ |
| Custom Roles | ✅ |
| Audit Logs | ✅ |
| SCIM | ✅ |

---

## Appendix B: References

**Official Rippling Documentation:**
- [Help Center](https://help.rippling.com/)
- [Security & Trust](https://www.rippling.com/security)
- [Trust Center](https://trust.rippling.com/)
- [7 Steps to Secure Your Rippling Tenant](https://www.rippling.com/blog/seven-powerful-simple-steps-to-secure-your-rippling-tenant)

**API & Developer Resources:**
- [REST API Documentation](https://developer.rippling.com/documentation/rest-api)

**Compliance & Certifications:**
- SOC 1 Type II, SOC 2 Type II, ISO 27001, ISO 27018, ISO 42001, CSA STAR Level 2 -- via [Rippling Trust Center](https://trust.rippling.com/)

**Security Incidents:**
- **Deel Corporate Espionage Incident (March 2025):** Rippling filed a lawsuit against competitor Deel alleging a planted insider (spy) who accessed proprietary sales data, customer information, and competitive intelligence via Slack over several months. This was not a platform breach -- it was an insider threat from a Deel-affiliated employee. Rippling detected the scheme using a honeypot trap.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Rippling hardening guide | Claude Code (Opus 4.5) |
