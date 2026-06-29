---
layout: guide
title: "Amplitude Hardening Guide"
vendor: "Amplitude"
slug: "amplitude"
tier: "2"
category: "Data"
description: "Product analytics platform hardening for Amplitude including SAML SSO, project access, and data governance"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Amplitude is a leading product analytics platform serving **thousands of companies** for behavioral analytics and product optimization. As a platform handling user behavior data and product metrics, Amplitude security configurations directly impact data privacy and analytics integrity.

### Intended Audience
- Security engineers managing analytics platforms
- IT administrators configuring Amplitude
- Product teams managing analytics
- GRC professionals assessing data security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Amplitude security including SAML SSO, organization/project access, API security, and data governance.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Security](#3-data-security)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Amplitude users.

#### Rationale
**Why This Matters:**
- Centralizes Amplitude authentication in your corporate IdP, enforcing MFA, conditional access, and password policy on every login
- Local Amplitude password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO paired with SCIM deprovisioning removes departed employees automatically, eliminating orphaned accounts with standing access to behavioral data
- Amplitude holds detailed user-behavior and product datasets, so a single compromised login can expose customer analytics and PII

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Prerequisites
- Amplitude admin access
- Enterprise or Growth plan
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Organization Settings** → **Security**
2. Find SAML SSO section

**Step 2: Configure SAML**
1. Enable SAML SSO
2. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
3. Download Amplitude metadata for IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback access

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Amplitude users.

#### Rationale
**Why This Matters:**
- Adds a second authentication factor so a stolen or guessed password alone cannot grant access to analytics data
- Phishing-resistant MFA for admins blocks attackers who harvest credentials through fake login pages
- Reduces risk from password reuse where credentials leaked in unrelated breaches are replayed against Amplitude
- Protects access to dashboards, data exports, and API keys that expose user behavior and PII

**Attack Prevented:** Credential stuffing, phishing, password reuse, account takeover

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

**Step 2: Enable Amplitude 2FA (non-SSO)**
1. Navigate to: **Settings** → **Security**
2. Enable 2FA requirement
3. Users configure authenticator apps

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout settings.

#### Rationale
**Why This Matters:**
- Idle session timeouts limit the window in which an attacker can hijack an unattended or abandoned session
- Shorter sessions reduce exposure on shared, public, or unmanaged devices
- Forcing periodic re-authentication limits the value of stolen session tokens or cookies
- Protects analytics consoles left open on workstations from opportunistic misuse

**Attack Prevented:** Session hijacking, unattended-session abuse, token replay

#### ClickOps Implementation

**Step 1: Configure Timeout**
1. Navigate to: **Settings** → **Security**
2. Configure session timeout
3. Balance security with usability

---

## 2. Access Controls

### 2.1 Configure Organization Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Amplitude roles.

#### Rationale
**Why This Matters:**
- Least-privilege role assignment ensures users can only perform the actions their job actually requires
- Limiting Admin and Manager roles shrinks the blast radius of any single compromised account
- Read-only Viewer roles let analysts consume data without the ability to alter taxonomy, settings, or exports
- Prevents broad standing access to data exports and configuration changes across the organization

**Attack Prevented:** Privilege escalation, insider misuse, lateral movement, unauthorized configuration changes

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Members**
2. Review available roles:
   - Admin
   - Manager
   - Member
   - Viewer
3. Understand role capabilities

**Step 2: Assign Appropriate Roles**
1. Apply least-privilege principle
2. Use Viewer for read-only access
3. Regular access reviews

---

### 2.2 Configure Project Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to specific projects.

#### Rationale
**Why This Matters:**
- Project-level permissions ensure users only see the datasets relevant to their work
- Separating production and test projects prevents accidental exposure or modification of live customer data
- Restricting sensitive projects limits who can view regulated or high-value behavioral data
- Contains the impact of a compromised account to a single project rather than all organizational data

**Attack Prevented:** Unauthorized data access, cross-project data exposure, insider data exfiltration

#### ClickOps Implementation

**Step 1: Configure Project Permissions**
1. Navigate to project settings
2. Assign users to projects
3. Set project-specific roles

**Step 2: Limit Cross-Project Access**
1. Separate production and test data
2. Restrict sensitive project access
3. Audit project membership

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Admin accounts can change security settings, manage members, and access all projects, making each one a high-value target
- Keeping admins to a small number reduces the attack surface an adversary can aim at for full organizational control
- Requiring SSO and 2FA on admins raises the bar against credential theft and phishing
- Monitoring admin activity surfaces unauthorized configuration or privilege changes early

**Attack Prevented:** Admin account takeover, privilege escalation, unauthorized security-setting changes

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review all admin accounts
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit admin to 2-3 users
2. Require 2FA/SSO for admins
3. Monitor admin activity

---

## 3. Data Security

### 3.1 Configure API Key Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Amplitude API keys.

#### Rationale
**Why This Matters:**
- API keys grant programmatic access to ingest and query analytics data, so a leaked key enables data theft or injection
- Keeping secret keys server-side only prevents exposure in client code, browsers, or mobile app bundles
- Storing keys in a vault and rotating them limits the lifetime and reach of any leaked credential
- Monitoring key usage detects abuse such as bulk data scraping or anomalous export volumes

**Attack Prevented:** API key leakage, unauthorized data ingestion, data exfiltration, credential abuse

#### ClickOps Implementation

**Step 1: Review API Keys**
1. Navigate to: **Settings** → **Projects** → **API Keys**
2. Review all API keys
3. Document key purposes

**Step 2: Secure Keys**
1. Store keys in secure vault
2. Use secret keys server-side only
3. Rotate keys regularly

**Step 3: Monitor Usage**
1. Monitor API key usage
2. Alert on anomalous patterns
3. Revoke compromised keys

---

### 3.2 Configure Data Governance

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Implement data governance controls.

#### Rationale
**Why This Matters:**
- A defined event taxonomy and property classification identify which fields contain PII and need protection
- PII detection and data masking prevent sensitive personal data from being collected or exposed in reports
- Retention and deletion policies enforce data minimization and support GDPR and CCPA subject requests
- Strong governance reduces regulatory exposure and limits the sensitive data available if access is compromised

**Attack Prevented:** PII over-collection, privacy-regulation violations, sensitive-data exposure, non-compliant retention

#### ClickOps Implementation

**Step 1: Configure Data Taxonomy**
1. Define event taxonomy
2. Configure property classifications
3. Apply data governance rules

**Step 2: Configure Privacy Controls**
1. Enable PII detection
2. Configure data masking
3. Support deletion requests

**Step 3: Configure Retention**
1. Set data retention policies
2. Configure data deletion
3. Document compliance requirements

---

## 4. Monitoring & Compliance

### 4.1 Configure Activity Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor activity logs.

#### Rationale
**Why This Matters:**
- Activity logs create an audit trail of authentication, permission, and data-export events for forensics
- Monitoring permission and project changes detects unauthorized privilege escalation
- Tracking data exports surfaces potential exfiltration of behavioral and product data
- Without logging, breaches and insider misuse go undetected and incident response is blind

**Attack Prevented:** Undetected breach, insider data exfiltration, unauthorized privilege changes, audit gaps

#### ClickOps Implementation

**Step 1: Access Logs**
1. Navigate to: **Settings** → **Activity Log**
2. Review logged events
3. Configure retention

**Step 2: Monitor Key Events**
1. User authentication
2. Project changes
3. Permission modifications
4. Data exports

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Amplitude Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Organization roles | [2.1](#21-configure-organization-roles) |
| CC6.7 | API key security | [3.1](#31-configure-api-key-security) |
| CC7.2 | Activity logs | [4.1](#41-configure-activity-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Amplitude Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-6 | Organization roles | [2.1](#21-configure-organization-roles) |
| SC-12 | API key security | [3.1](#31-configure-api-key-security) |
| AU-2 | Activity logs | [4.1](#41-configure-activity-logs) |

---

## Appendix A: References

**Official Amplitude Documentation:**
- [Trust Center](https://trust.amplitude.com/) (powered by Wolfia)
- [Trust, Security and Privacy](https://amplitude.com/security-and-privacy)
- [Amplitude Documentation](https://amplitude.com/docs)
- [Security and Privacy FAQ](https://amplitude.com/docs/faq/security-and-privacy)
- [Data Governance](https://amplitude.com/blog/tackle-data-governance)
- [Data Access Controls](https://amplitude.com/blog/data-access-controls)

**API & Developer Tools:**
- [Analytics APIs](https://www.docs.developers.amplitude.com/analytics/apis/)
- [TypeScript SDK](https://github.com/amplitude/Amplitude-TypeScript)
- [Python SDK](https://github.com/amplitude/Amplitude-Python)
- [Go SDK](https://github.com/amplitude/analytics-go)
- [Node.js SDK](https://github.com/amplitude/Amplitude-Node)
- [iOS SDK](https://github.com/amplitude/Amplitude-iOS)
- [Android SDK](https://github.com/amplitude/Amplitude-Android)
- [GitHub Organization](https://github.com/amplitude)

**Compliance Frameworks:**
- SOC 2 Type II — via [Trust Center](https://trust.amplitude.com/)
- ISO 27001, ISO 27017, ISO 27018 — via [Trust Center](https://trust.amplitude.com/)
- GDPR, CCPA, HIPAA compliance
- Annual third-party penetration testing; private Bug Bounty program

**Security Incidents:**
- **August 2024 — Data Harvesting Lawsuit (DoorDash):** A lawsuit alleged Amplitude's tracking code embedded in the DoorDash app collected geolocation and sensitive user data without consent, sharing it with marketing platforms. In September 2025, a federal judge ruled users could proceed with claims but were bound by DoorDash's arbitration agreement. Amplitude itself was not breached. ([Bloomberg Law Report](https://news.bloomberglaw.com/privacy-and-data-security/amplitude-snares-private-data-of-millions-via-apps-suit-says))
- No major direct platform security breaches identified as of early 2026.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, access controls, and data governance | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
