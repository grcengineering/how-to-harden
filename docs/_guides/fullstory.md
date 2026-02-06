---
layout: guide
title: "Fullstory Hardening Guide"
vendor: "Fullstory"
slug: "fullstory"
tier: "3"
category: "Data & Analytics"
description: "Digital experience intelligence platform hardening for Fullstory including SAML SSO, data privacy controls, and access management"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Fullstory is a digital experience intelligence platform providing session replay and analytics. As a platform capturing user sessions and interaction data, Fullstory security configurations directly impact data privacy and user trust.

### Intended Audience
- Security engineers managing analytics platforms
- IT administrators configuring Fullstory
- Product teams managing digital experience tools
- GRC professionals assessing data security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Fullstory users.

#### Prerequisites
- [ ] Fullstory admin access
- [ ] Enterprise plan
- [ ] SAML 2.0 compatible IdP

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Fullstory users.

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
Implement least privilege using Fullstory roles.

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

## 3. Data Privacy

### 3.1 Configure Privacy Controls

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Configure privacy controls to protect user data.

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

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SI-12 |

#### Description
Configure data retention policies.

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
- [Fullstory Security](https://www.fullstory.com/security/)
- [SSO Configuration](https://help.fullstory.com/hc/en-us/articles/360020624174-Configure-SAML-based-SSO)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and privacy controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
