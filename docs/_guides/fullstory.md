---
layout: guide
title: "Fullstory Hardening Guide"
vendor: "Fullstory"
slug: "fullstory"
tier: "3"
category: "Data"
description: "Digital experience intelligence platform hardening for Fullstory including SAML SSO, data privacy controls, and access management"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Fullstory is a digital experience intelligence platform providing session replay and analytics. As a platform capturing user sessions and interaction data, Fullstory security configurations directly impact data privacy and user trust.

### Intended Audience
- Security engineers managing analytics platforms
- IT administrators configuring Fullstory
- Product teams managing digital experience tools
- GRC professionals assessing data security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Fullstory security including SAML SSO, privacy controls, access management, and data governance.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Privacy](#3-data-privacy)
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
Configure SAML SSO to centralize authentication for Fullstory users.

#### Rationale
**Why This Matters:**
- Centralizes Fullstory authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local password logins bypass IdP controls and are a prime target for credential stuffing and phishing
- SSO enables automatic deprovisioning so departed employees immediately lose access to recorded session data
- Fullstory captures full user sessions that can contain PII, so a single compromised login can expose sensitive customer interaction data

**Attack Prevented:** Credential theft, phishing, credential stuffing, orphaned-account access

#### Prerequisites
- Fullstory admin access
- Enterprise plan
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Security** → **Single Sign-On**
2. Enable SAML SSO

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Download Fullstory metadata for IdP

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
Require 2FA for all Fullstory users.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks account takeover even when a password is leaked, reused, or guessed
- Fullstory dashboards expose recorded sessions, heatmaps, and analytics that can contain customer PII
- Phishing-resistant factors for admins stop attackers from using stolen credentials to alter security settings
- Enforcing MFA at the IdP applies it uniformly across every SSO user without per-account configuration

**Attack Prevented:** Password reuse, credential stuffing, phishing, account takeover

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
Implement least privilege using Fullstory roles.

#### Rationale
**Why This Matters:**
- Assigning the minimum necessary role limits what each user can see and change, shrinking the blast radius of a compromised account
- Viewer and Standard roles keep most analysts away from administrative and configuration functions
- Over-provisioned accounts let a single phished user export session data or disable privacy controls
- Regular access reviews catch role creep before it becomes a standing risk

**Attack Prevented:** Privilege escalation, insider misuse, excessive data exposure

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Team**
2. Review available roles:
   - Admin
   - Standard
   - Viewer
3. Assign minimum necessary role

**Step 2: Apply Least Privilege**
1. Use Viewer for read-only access
2. Limit Admin access
3. Regular access reviews

---

### 2.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Administrators can change privacy masking, retention, and SSO enforcement, making each admin account a high-value target
- Keeping the admin count small reduces the number of credentials an attacker can target to gain full control
- Requiring SSO and MFA for admins ensures these powerful accounts inherit your strongest authentication controls
- Monitoring admin activity surfaces unauthorized configuration changes that could weaken data protections

**Attack Prevented:** Privilege escalation, admin account takeover, unauthorized configuration changes

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review admin accounts
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit admins to 2-3 users
2. Require SSO for admins
3. Monitor admin activity

---

## 3. Data Privacy

### 3.1 Configure Privacy Controls

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Configure privacy controls to protect user data.

#### Rationale
**Why This Matters:**
- Element exclusions and field masking prevent Fullstory from ever capturing passwords, payment details, and other sensitive PII
- Private-by-default capture excludes data unless it is explicitly allowed, reducing the chance of accidental collection
- Minimizing what is recorded shrinks the data exposed if the Fullstory account or stored sessions are breached
- Excluding sensitive pages and fields supports GDPR, CCPA, and PCI obligations to avoid storing regulated data

**Attack Prevented:** Sensitive data exposure, PII leakage, regulatory non-compliance

#### ClickOps Implementation

**Step 1: Configure Exclusions**
1. Navigate to: **Settings** → **Privacy**
2. Configure element exclusions
3. Mask sensitive form fields
4. Exclude sensitive pages

**Step 2: Configure Data Masking**
1. Enable private by default mode
2. Mask input fields
3. Block sensitive data capture

---

### 3.2 Configure Data Retention

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SI-12 |

#### Description
Configure data retention policies.

#### Rationale
**Why This Matters:**
- Bounding retention ensures recorded sessions are automatically deleted once they are no longer needed, limiting long-term exposure
- Less retained data means a smaller pool of PII for an attacker to steal if the platform is compromised
- Configurable deletion supports GDPR and CCPA right-to-erasure requests within required timeframes
- Shorter retention reduces storage of stale customer interaction data that provides no ongoing business value

**Attack Prevented:** Excessive data retention, regulatory non-compliance, sensitive data exposure

#### ClickOps Implementation

**Step 1: Configure Retention**
1. Set appropriate retention period
2. Configure data deletion
3. Support deletion requests (GDPR/CCPA)

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Fullstory Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User roles | [2.1](#21-configure-user-roles) |
| CC6.7 | Privacy controls | [3.1](#31-configure-privacy-controls) |

### NIST 800-53 Rev 5 Mapping

| Control | Fullstory Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | User roles | [2.1](#21-configure-user-roles) |
| AC-3 | Privacy controls | [3.1](#31-configure-privacy-controls) |

---

## Appendix A: References

**Official Fullstory Documentation:**
- [Trust Center (SafeBase)](https://trust.fullstory.com/)
- [Fullstory Security](https://www.fullstory.com/security/)
- [Help Center](https://help.fullstory.com/hc/en-us)
- [Comprehensive Compliance Program](https://help.fullstory.com/hc/en-us/articles/360020624254-Fullstory-s-Comprehensive-Compliance-Program)
- [Security and Privacy Documentation Overview](https://help.fullstory.com/hc/en-us/articles/360020624254-Security-and-Privacy-Documentation-Overview)
- [SSO Configuration](https://help.fullstory.com/hc/en-us/articles/360020624174-Configure-SAML-based-SSO)

**API & Developer Documentation:**
- [Fullstory Developer Portal](https://developer.fullstory.com/)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001:2022, ISO 27017, ISO 27018, ISO 27701, ISO 42001 — via [Trust Center](https://trust.fullstory.com/)
- First in its industry to achieve ISO 42001 (AI Management System) certification
- Annual comprehensive internal and independent external audits

**Security Incidents:**
- No major public security incidents identified affecting the Fullstory platform.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and privacy controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
