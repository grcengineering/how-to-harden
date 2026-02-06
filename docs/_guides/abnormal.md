---
layout: guide
title: "Abnormal Security Hardening Guide"
vendor: "Abnormal Security"
slug: "abnormal"
tier: "2"
category: "Security & Compliance"
description: "Email security platform hardening for Abnormal Security including SSO configuration, admin access, and integration security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Abnormal Security is an AI-powered email security platform providing advanced threat detection. As a platform analyzing email communications and detecting sophisticated attacks, Abnormal security configurations directly impact threat visibility and response capabilities.

### Intended Audience
- Security engineers managing email security
- IT administrators configuring Abnormal
- SOC analysts managing threat detection
- GRC professionals assessing email security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Abnormal portal security including SSO, admin access, and integration security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Integration Security](#3-integration-security)
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
Configure SAML SSO for Abnormal portal access.

#### Prerequisites
- [ ] Abnormal admin access
- [ ] SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **SSO**
2. Enable SAML authentication

**Step 2: Configure SAML**
1. Configure IdP settings:
   - Entity ID
   - SSO URL
   - Certificate
2. Configure Abnormal in IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure fallback access

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Abnormal users.

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
Implement least privilege for portal access.

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Users**
2. Review available roles
3. Assign minimum necessary role

**Step 2: Apply Least Privilege**
1. Use read-only for analysts
2. Limit admin access
3. Regular access reviews

---

### 2.2 Limit Admin Access

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

## 3. Integration Security

### 3.1 Configure API Integration Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure email platform integrations.

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Settings** → **Integrations**
2. Review connected platforms
3. Verify permissions

**Step 2: Apply Least Privilege**
1. Grant minimum required permissions
2. Monitor integration activity
3. Review regularly

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Abnormal Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User roles | [2.1](#21-configure-user-roles) |

### NIST 800-53 Rev 5 Mapping

| Control | Abnormal Control | Guide Section |
|---------|------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | User roles | [2.1](#21-configure-user-roles) |

---

## Appendix A: References

**Official Abnormal Documentation:**
- [Abnormal Security](https://abnormalsecurity.com/)
- [Documentation](https://help.abnormalsecurity.com/)

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
