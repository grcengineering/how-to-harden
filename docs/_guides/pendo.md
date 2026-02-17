---
layout: guide
title: "Pendo Hardening Guide"
vendor: "Pendo"
slug: "pendo"
tier: "3"
category: "Data"
description: "Product experience platform hardening for Pendo including SAML SSO, subscription access, and data privacy controls"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Pendo is a product experience platform providing analytics, in-app guidance, and feedback tools. As a platform collecting user behavior data and enabling in-app messaging, Pendo security configurations directly impact data privacy and application security.

### Intended Audience
- Security engineers managing product experience platforms
- IT administrators configuring Pendo
- Product teams managing analytics and guidance
- GRC professionals assessing data security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Pendo security including SAML SSO, subscription access, API security, and data privacy controls.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Security](#3-data-security)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Pendo users.

#### Prerequisites
- [ ] Pendo admin access
- [ ] Enterprise plan
- [ ] SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Subscription Settings** → **Single Sign-On**
2. Enable SAML SSO

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Download Pendo metadata for IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Pendo users.

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

---

## 2. Access Controls

### 2.1 Configure User Roles

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Pendo roles.

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Users**
2. Review available roles:
   - Admin
   - User
   - Read-only
3. Assign minimum necessary role

**Step 2: Apply Least Privilege**
1. Use Read-only for viewers
2. Limit Admin access
3. Regular access reviews

---

### 2.2 Configure Subscription Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to different subscriptions/apps.

#### ClickOps Implementation

**Step 1: Configure Access**
1. Separate production and development apps
2. Limit access per subscription
3. Apply role restrictions

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

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

## 3. Data Security

### 3.1 Configure Integration Key Security

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Pendo integration keys.

#### ClickOps Implementation

**Step 1: Review Keys**
1. Navigate to: **Settings** → **Subscription Settings**
2. Review integration keys
3. Document key usage

**Step 2: Secure Keys**
1. Store keys securely
2. Never expose in client-side code publicly
3. Rotate if compromised

---

### 3.2 Configure Data Privacy

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Configure data privacy controls.

#### ClickOps Implementation

**Step 1: Configure Data Collection**
1. Review collected metadata
2. Exclude sensitive fields
3. Configure data masking

**Step 2: Support Privacy Requests**
1. Configure deletion workflow
2. Support GDPR/CCPA requests
3. Document data handling

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Pendo Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User roles | [2.1](#21-configure-user-roles) |
| CC6.7 | Key security | [3.1](#31-configure-integration-key-security) |

### NIST 800-53 Rev 5 Mapping

| Control | Pendo Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | User roles | [2.1](#21-configure-user-roles) |
| SC-12 | Key security | [3.1](#31-configure-integration-key-security) |

---

## Appendix A: References

**Official Pendo Documentation:**
- [Trust Center](https://trust.pendo.io/)
- [Data Privacy & Security](https://www.pendo.io/data-privacy-security/)
- [Help Center](https://support.pendo.io/hc/en-us)
- [Security and Privacy in Pendo](https://support.pendo.io/hc/en-us/articles/360031862372-Security-and-privacy-in-Pendo)
- [SSO Configuration](https://support.pendo.io/hc/en-us/articles/360032201631-Single-Sign-On-SSO-)

**API Documentation:**
- [Pendo Developer Portal](https://developers.pendo.io/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 42001, HIPAA, GDPR, CCPA — via [Trust Center](https://trust.pendo.io/)

**Security Incidents:**
- No major public security incidents identified. Pendo conducts annual third-party security audits and penetration testing twice per year.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
