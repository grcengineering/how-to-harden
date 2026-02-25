---
layout: guide
title: "Square Hardening Guide"
vendor: "Square (Block)"
slug: "square"
tier: "2"
category: "Productivity"
description: "Commerce platform hardening for Square including SSO configuration, team permissions, and API security"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Square is a comprehensive commerce platform serving **millions of businesses** for payments, point-of-sale, and business management. As a platform handling payment and customer data, Square security configurations directly impact PCI compliance and business operations.

### Intended Audience
- Security engineers managing commerce platforms
- IT administrators configuring Square
- Business owners managing Square access
- GRC professionals assessing retail security

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Square Dashboard security including SSO, team permissions, device security, and API management.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Device Security](#3-device-security)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure Single Sign-On

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SSO for Square Dashboard access (Square for Enterprise).

#### Prerequisites
- Square for Enterprise plan
- Account owner access
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Square Dashboard** → **Account & Settings** → **Security**
2. Find Single Sign-On section

**Step 2: Configure SSO**
1. Enable SSO
2. Configure IdP settings
3. Test authentication

**Step 3: Enforce SSO**
1. Enable SSO enforcement
2. Configure exceptions
3. Document fallback procedures

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Square accounts.

#### ClickOps Implementation

**Step 1: Enable 2FA**
1. Navigate to: **Account & Settings** → **Security**
2. Enable two-step verification
3. Configure verification method

**Step 2: Require for Team**
1. Require 2FA for all team members
2. Verify compliance
3. Monitor enrollment

---

## 2. Access Controls

### 2.1 Configure Team Permissions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Square permissions.

#### ClickOps Implementation

**Step 1: Review Permission Sets**
1. Navigate to: **Team** → **Permissions**
2. Review available permissions
3. Create custom permission sets

**Step 2: Assign Minimum Access**
1. Assign minimum necessary permissions
2. Separate by function:
   - Sales access
   - Reports access
   - Customer data access
   - Settings access
3. Regular access reviews

---

### 2.2 Configure Location Access

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control team access to specific locations.

#### ClickOps Implementation

**Step 1: Configure Access**
1. Limit team members to required locations
2. Separate production locations
3. Audit cross-location access

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect owner accounts.

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review account owners
2. Document admin access

**Step 2: Apply Restrictions**
1. Limit owners to 2-3 users
2. Require 2FA
3. Monitor activity

---

## 3. Device Security

### 3.1 Configure Device Management

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 1.1 |
| NIST 800-53 | CM-8 |

#### Description
Manage Square devices and terminals.

#### ClickOps Implementation

**Step 1: Inventory Devices**
1. Navigate to: **Devices**
2. Review all registered devices
3. Document device purposes

**Step 2: Configure Security**
1. Enable device passcodes
2. Configure automatic logout
3. Monitor device activity

---

### 3.2 Configure API Security

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Square API access.

#### ClickOps Implementation

**Step 1: Review Applications**
1. Navigate to: **Developer Dashboard**
2. Review connected applications
3. Remove unnecessary apps

**Step 2: Secure Credentials**
1. Protect access tokens
2. Use sandbox for testing
3. Rotate credentials regularly

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Square Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-single-sign-on) |
| CC6.2 | Team permissions | [2.1](#21-configure-team-permissions) |
| CC6.7 | API security | [3.2](#32-configure-api-security) |

### PCI DSS v4.0 Mapping

| Requirement | Square Control | Guide Section |
|-------------|----------------|---------------|
| 7 | Team permissions | [2.1](#21-configure-team-permissions) |
| 8 | Authentication | [1.2](#12-enforce-two-factor-authentication) |

---

## Appendix A: References

**Official Square Documentation:**
- [Square Security](https://squareup.com/us/en/security)
- [Help Center](https://squareup.com/help/us/en)
- [Privacy and Security Measures](https://squareup.com/help/us/en/article/3796-privacy-and-security)
- [Secure Payments](https://squareup.com/us/en/payments/secure)
- [Team Management](https://squareup.com/help/us/en/article/5068-manage-team-members-in-your-square-account)

**API & Developer Tools:**
- [Square API Reference](https://developer.squareup.com/reference/square)
- [Square Developer Portal](https://developer.squareup.com/)
- SDKs available for multiple languages -- via [Developer Portal](https://developer.squareup.com/)

**Compliance Frameworks:**
- PCI DSS Level 1 (Service Provider), ISO 27001 -- via [Square Security](https://squareup.com/us/en/security)
- Square sits on the PCI Board of Advisors and helped evolve PCI Data Security Standards
- [ISO 27001 Certification Announcement](https://squareup.com/us/en/press/iso-27001-certification)

**Security Incidents:**
- (2021-12) A former Block (Square) employee accessed Cash App Investing reports after employment ended, exposing full names, brokerage account numbers, and portfolio data for approximately 8.2 million current and former customers. Disclosed April 2022.
- (2023-09) Multi-hour system outage affected merchants; forensic analysis ruled out cyberattack -- no data breach confirmed.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and permissions | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
