---
layout: guide
title: "Outreach Hardening Guide"
vendor: "Outreach"
slug: "outreach"
tier: "2"
category: "Productivity"
description: "Sales engagement platform hardening for Outreach including SAML SSO, user permissions, and data security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Outreach is a sales engagement platform providing automation and analytics for sales teams. As a platform managing customer communications and sales data, Outreach security configurations directly impact data protection and sales operations.

### Intended Audience
- Security engineers managing sales tools
- IT administrators configuring Outreach
- Sales operations managers
- GRC professionals assessing sales platform security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Outreach security including SAML SSO, user permissions, data access, and integration security.

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
Configure SAML SSO for Outreach access.

#### Prerequisites
- Outreach admin access
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Admin Settings** → **Security** → **SAML**
2. Enable SAML authentication

**Step 2: Configure SAML**
1. Configure IdP settings
2. Download Outreach metadata for IdP
3. Test authentication

**Step 3: Enforce SSO**
1. Enable SSO enforcement
2. Configure exceptions if needed
3. Document fallback procedures

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Outreach users.

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA

---

## 2. Access Controls

### 2.1 Configure User Profiles

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using profiles.

#### ClickOps Implementation

**Step 1: Review Profiles**
1. Navigate to: **Admin Settings** → **Profiles**
2. Review available profiles
3. Understand profile permissions

**Step 2: Apply Least Privilege**
1. Create custom profiles if needed
2. Assign minimum necessary permissions
3. Regular access reviews

---

### 2.2 Configure Governance Controls

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Configure governance and compliance controls.

#### ClickOps Implementation

**Step 1: Configure Governance**
1. Navigate to: **Admin Settings** → **Governance**
2. Configure compliance settings
3. Set communication policies

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

### 3.1 Configure Integration Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure third-party integrations.

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Admin Settings** → **Integrations**
2. Review connected apps
3. Remove unnecessary integrations

**Step 2: Apply Least Privilege**
1. Grant minimum permissions
2. Monitor integration activity

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Outreach Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User profiles | [2.1](#21-configure-user-profiles) |

### NIST 800-53 Rev 5 Mapping

| Control | Outreach Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | User profiles | [2.1](#21-configure-user-profiles) |

---

## Appendix A: References

**Official Outreach Documentation:**
- [Trust & Safety Center](https://www.outreach.io/platform/trust)
- [Enterprise Data Security](https://www.outreach.io/platform/security)
- [Help Center](https://support.outreach.io/hc/en-us)
- [SSO Configuration](https://support.outreach.io/hc/en-us/articles/360013377553-SAML-Single-Sign-On-SSO-)
- [Security, Privacy & Data Protection Certifications](https://support.outreach.io/hc/en-us/articles/20211805996187-Outreach-s-latest-Security-Privacy-and-Data-Protection-certifications-and-documentation)

**API Documentation:**
- [Outreach API Reference](https://developers.outreach.io/api/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27701, ISO 42001 (Responsible AI), TRUSTe, GDPR, Privacy Shield — via [Trust & Safety](https://www.outreach.io/platform/trust)

**Security Incidents:**
- No major public security incidents identified. Outreach runs a private bug bounty program through Bugcrowd and conducts annual penetration testing.

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
