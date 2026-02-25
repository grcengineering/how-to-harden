---
layout: guide
title: "Gong Hardening Guide"
vendor: "Gong"
slug: "gong"
tier: "2"
category: "Productivity"
description: "Revenue intelligence platform hardening for Gong including SAML SSO, data access controls, and recording security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Gong is a revenue intelligence platform providing conversation analytics and sales insights. As a platform recording and analyzing business communications, Gong security configurations directly impact data privacy and conversation confidentiality.

### Intended Audience
- Security engineers managing sales tools
- IT administrators configuring Gong
- Sales operations managers
- GRC professionals assessing communication security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Gong security including SAML SSO, user permissions, data access controls, and recording policies.

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
Configure SAML SSO for Gong access.

#### Prerequisites
- Gong admin access
- Enterprise plan
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Company Settings** → **Security** → **SSO**
2. Enable SAML authentication

**Step 2: Configure SAML**
1. Configure IdP settings:
   - Entity ID
   - SSO URL
   - Certificate
2. Configure Gong in IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Gong users.

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

---

## 2. Access Controls

### 2.1 Configure User Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for Gong access.

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Company Settings** → **Users**
2. Review user roles:
   - Admin
   - Manager
   - Team member
3. Assign minimum necessary role

**Step 2: Configure Visibility**
1. Set visibility permissions
2. Control who sees which calls
3. Apply team boundaries

---

### 2.2 Configure Recording Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control access to call recordings.

#### ClickOps Implementation

**Step 1: Configure Access Rules**
1. Set default visibility
2. Configure manager access
3. Limit cross-team visibility

**Step 2: Configure Sensitive Calls**
1. Mark sensitive recordings
2. Restrict access appropriately
3. Audit access patterns

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect admin accounts.

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review admin accounts
2. Document admin access

**Step 2: Apply Restrictions**
1. Limit admins to required personnel
2. Require MFA
3. Monitor admin activity

---

## 3. Data Security

### 3.1 Configure Data Retention

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SI-12 |

#### Description
Configure recording retention policies.

#### ClickOps Implementation

**Step 1: Configure Retention**
1. Navigate to: **Company Settings** → **Data Management**
2. Set retention period
3. Configure automatic deletion

---

### 3.2 Configure Integration Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure third-party integrations.

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Company Settings** → **Integrations**
2. Review connected apps
3. Remove unnecessary integrations

**Step 2: Apply Least Privilege**
1. Grant minimum permissions
2. Monitor integration activity

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Gong Control | Guide Section |
|-----------|--------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User permissions | [2.1](#21-configure-user-permissions) |
| CC6.7 | Data retention | [3.1](#31-configure-data-retention) |

### NIST 800-53 Rev 5 Mapping

| Control | Gong Control | Guide Section |
|---------|--------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-3 | Recording access | [2.2](#22-configure-recording-access) |
| AC-6 | User permissions | [2.1](#21-configure-user-permissions) |

---

## Appendix A: References

**Official Gong Documentation:**
- [Trust Center](https://trust.gong.io/)
- [Gong Security](https://www.gong.io/security/)
- [Help Center](https://help.gong.io/)
- [Summary of Security Features](https://help.gong.io/docs/summary-of-security-features)
- [Security, Privacy and Compliance FAQ](https://help.gong.io/docs/faqs-for-security-privacy-and-compliance)

**API & Developer Tools:**
- [Gong API Documentation](https://gong.app.gong.io/settings/api/documentation)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, ISO 27701, ISO/IEC 42001:2023, PCI DSS (SAQ D), CSA STAR -- via [Trust Center](https://trust.gong.io/)
- [Compliance at Gong](https://www.gong.io/trust-center/compliance/)

**Security Incidents:**
- No major public security incidents identified as of February 2026.

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
