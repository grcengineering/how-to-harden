---
layout: guide
title: "Heap Hardening Guide"
vendor: "Heap (Contentsquare)"
slug: "heap"
tier: "3"
category: "Data"
description: "Digital insights platform hardening for Heap including SAML SSO, environment access, and data governance"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Heap is a digital insights platform providing autocapture analytics for product teams. As a platform collecting user interaction data automatically, Heap security configurations directly impact data privacy and analytics integrity.

### Intended Audience
- Security engineers managing analytics platforms
- IT administrators configuring Heap
- Product teams managing analytics
- GRC professionals assessing data security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Heap security including SAML SSO, environment access, API security, and data governance.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Security](#3-data-security)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Heap users.

#### Rationale
**Why This Matters:**
- Centralizes Heap login in your corporate IdP, enforcing MFA and conditional access on every authentication
- Local username/password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO with SCIM provisioning deprovisions departed users automatically, eliminating orphaned accounts that retain standing access to analytics data
- Heap autocaptures user interaction data that can include sensitive product behavior, so a single compromised login can expose broad datasets

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Prerequisites
- Heap admin access
- Business or Enterprise plan
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Account** → **Manage** → **SSO**
2. Enable SAML SSO

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Download Heap metadata for IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Heap users.

#### Rationale
**Why This Matters:**
- Adds a second factor so a stolen, guessed, or reused password alone cannot grant access to Heap
- Defends against credential stuffing fueled by password reuse from unrelated third-party breaches
- Admin and Architect accounts can alter data collection, export datasets, and manage users, so protecting those sessions is critical
- Phishing-resistant factors for admins block real-time credential relay and proxy phishing attacks

**Attack Prevented:** Credential stuffing, password reuse, phishing, account takeover

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

---

## 2. Access Controls

### 2.1 Configure User Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Heap roles.

#### Rationale
**Why This Matters:**
- Granting the minimum necessary role limits what a compromised or insider account can view and change
- Assigning Read-only to most users prevents accidental or malicious modification of event definitions, dashboards, and reports
- Restricting Architect and Admin roles reduces the number of accounts that can alter data capture or export raw datasets
- Regular access reviews catch privilege creep and stale grants before they become an attack path

**Attack Prevented:** Privilege escalation, insider misuse, lateral movement, unauthorized data modification

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Account** → **Manage** → **Users**
2. Review available roles:
   - Owner
   - Admin
   - Architect
   - Analyst
   - Read-only
3. Assign minimum necessary role

**Step 2: Apply Least Privilege**
1. Use Read-only for most users
2. Limit Architect/Admin access
3. Regular access reviews

---

### 2.2 Configure Environment Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to different environments.

#### Rationale
**Why This Matters:**
- Separating production from development limits exposure of real user data to lower-trust test workflows
- Restricting production environment access shrinks the population of accounts that can reach live analytics data
- Environment-scoped permissions prevent a development-only user from reading or altering production datasets
- Isolating sensitive-data environments contains the blast radius of any single compromised account

**Attack Prevented:** Cross-environment data exposure, unauthorized production access, blast-radius expansion

#### ClickOps Implementation

**Step 1: Configure Environment Permissions**
1. Separate production and development
2. Limit production environment access
3. Restrict sensitive data environments

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
- Owner and admin accounts control SSO configuration, user management, data collection, and exports, making each a high-value target
- Fewer privileged accounts means fewer credentials an attacker can phish or steal to gain full control of the workspace
- Requiring SSO for admins routes privileged logins through enforced MFA and conditional access
- Monitoring admin activity surfaces suspicious configuration changes or bulk data exports early

**Attack Prevented:** Account takeover, privilege abuse, unauthorized configuration change, insider misuse

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review owner/admin accounts
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit owners to 2-3 users
2. Require SSO for admins
3. Monitor admin activity

---

## 3. Data Security

### 3.1 Configure Data Governance

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Implement data governance controls.

#### Rationale
**Why This Matters:**
- Heap autocaptures interactions by default, which can sweep in PII or sensitive fields unless redaction and blocking are configured
- Data masking and PII protection reduce the sensitivity of stored analytics, limiting harm if the data store is exposed
- Blocking sensitive-data capture keeps regulated values such as payment, health, or credential fields out of the analytics store entirely
- Supporting deletion requests sustains compliance with privacy regulations like GDPR and CCPA and honors user data rights

**Attack Prevented:** PII leakage, sensitive-data overcollection, regulatory non-compliance, privacy violations

#### ClickOps Implementation

**Step 1: Configure Data Collection**
1. Review autocaptured data
2. Block sensitive data capture
3. Configure data redaction

**Step 2: Configure Privacy Controls**
1. Enable PII protection
2. Configure data masking
3. Support deletion requests

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Heap Control | Guide Section |
|-----------|--------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User roles | [2.1](#21-configure-user-roles) |
| CC6.7 | Data governance | [3.1](#31-configure-data-governance) |

### NIST 800-53 Rev 5 Mapping

| Control | Heap Control | Guide Section |
|---------|--------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | User roles | [2.1](#21-configure-user-roles) |

---

## Appendix A: References

**Official Heap Documentation:**
- [Trust Center](https://heap.io/trust-center)
- [Heap Security & Privacy](https://www.heap.io/platform/security)
- [Help Center](https://help.heap.io/hc/en-us)
- [SSO Configuration](https://help.heap.io/administration/account-management/sso/)

**API & Developer Tools:**
- [Heap Developer Documentation](https://developers.heap.io/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, ISO 27701 -- via [Trust Center](https://heap.io/trust-center)
- Contentsquare (parent company) Trust Portal: [trust.contentsquare.com](https://trust.contentsquare.com/)

**Security Incidents:**
- No major public security incidents identified as of February 2026.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
