---
layout: guide
title: "Square Hardening Guide"
vendor: "Square (Block)"
slug: "square"
tier: "2"
category: "Productivity"
description: "Commerce platform hardening for Square including SSO configuration, team permissions, and API security"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Square is a comprehensive commerce platform serving **millions of businesses** for payments, point-of-sale, and business management. As a platform handling payment and customer data, Square security configurations directly impact PCI compliance and business operations.

### Intended Audience
- Security engineers managing commerce platforms
- IT administrators configuring Square
- Business owners managing Square access
- GRC professionals assessing retail security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SSO for Square Dashboard access (Square for Enterprise).

#### Rationale
**Why This Matters:**
- Centralizes Square Dashboard authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local Square password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- IdP-driven deprovisioning removes access the moment an employee leaves, eliminating orphaned accounts that retain standing access to payment and customer data
- A single compromised Square login can expose transaction history, customer PII, and payout banking details

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Square accounts.

#### Rationale
**Why This Matters:**
- Two-factor authentication blocks account takeover even when a password is phished, leaked, or reused from another breach
- Square accounts control payments, refunds, and payout bank accounts, so a password alone is insufficient protection for financial operations
- Requiring 2FA across the whole team closes the weakest-link gap where one unprotected member becomes the entry point
- PCI DSS requires multi-factor authentication for access to the cardholder data environment

**Attack Prevented:** Credential stuffing, phishing, password reuse, account takeover

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Square permissions.

#### Rationale
**Why This Matters:**
- Least-privilege permission sets ensure each team member can only reach the data and actions their role requires
- Over-broad access lets a single compromised staff account expose customer records, sales reports, and settings far beyond its job function
- Separating sales, reporting, customer-data, and settings access contains the blast radius of any one account compromise
- Granular permissions create accountability and make insider misuse easier to detect during access reviews

**Attack Prevented:** Privilege escalation, insider data theft, lateral movement, excessive-access abuse

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control team access to specific locations.

#### Rationale
**Why This Matters:**
- Scoping team members to only their assigned locations limits exposure of sales, customer, and payout data across the business
- A compromised or rogue account confined to one location cannot pull reports or process refunds for the entire organization
- Location-level segmentation enforces separation between production sites and test or pilot locations
- Cross-location access reviews surface accounts that have accumulated unnecessary reach over time

**Attack Prevented:** Lateral movement, cross-location data exposure, excessive-access abuse

#### ClickOps Implementation

**Step 1: Configure Access**
1. Limit team members to required locations
2. Separate production locations
3. Audit cross-location access

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect owner accounts.

#### Rationale
**Why This Matters:**
- Account owners hold the highest privilege in Square (billing, banking, team management, and full data access), so their number must be tightly limited
- Every additional owner account expands the attack surface and the chance of a single compromised credential controlling the whole account
- Requiring 2FA and monitoring activity on owner accounts detects misuse before it escalates
- Tight owner control reduces the risk of standing access lingering after a privileged employee departs

**Attack Prevented:** Privilege escalation, account takeover, insider abuse, orphaned-admin access

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 1.1 |
| NIST 800-53 | CM-8 |

#### Description
Manage Square devices and terminals.

#### Rationale
**Why This Matters:**
- Square terminals and POS devices sit in physically exposed retail environments where theft and tampering are real threats
- Device passcodes and automatic logout prevent an unattended or stolen terminal from processing fraudulent transactions or exposing customer data
- An accurate device inventory makes rogue or unrecognized hardware immediately visible
- Monitoring device activity surfaces anomalous use such as logins from unexpected devices or off-hours transactions

**Attack Prevented:** Physical device theft, unauthorized POS access, terminal tampering, fraudulent transactions

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

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Square API access.

#### Rationale
**Why This Matters:**
- Square API access tokens can read and write payments, customers, and inventory programmatically, so a leaked token is equivalent to a compromised account
- Removing unused connected applications eliminates dormant integrations that retain access no one is monitoring
- Using the sandbox for testing keeps real payment data and live credentials out of development workflows
- Regular credential rotation limits the window an exposed token remains usable

**Attack Prevented:** API token theft, third-party integration abuse, credential leakage, unauthorized data access

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
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and permissions | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
