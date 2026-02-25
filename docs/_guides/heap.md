---
layout: guide
title: "Heap Hardening Guide"
vendor: "Heap (Contentsquare)"
slug: "heap"
tier: "3"
category: "Data"
description: "Digital insights platform hardening for Heap including SAML SSO, environment access, and data governance"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Heap is a digital insights platform providing autocapture analytics for product teams. As a platform collecting user interaction data automatically, Heap security configurations directly impact data privacy and analytics integrity.

### Intended Audience
- Security engineers managing analytics platforms
- IT administrators configuring Heap
- Product teams managing analytics
- GRC professionals assessing data security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Heap users.

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

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Heap users.

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
Implement least privilege using Heap roles.

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

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to different environments.

#### ClickOps Implementation

**Step 1: Configure Environment Permissions**
1. Separate production and development
2. Limit production environment access
3. Restrict sensitive data environments

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

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Implement data governance controls.

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
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
