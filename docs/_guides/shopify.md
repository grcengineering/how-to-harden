---
layout: guide
title: "Shopify Plus Hardening Guide"
vendor: "Shopify"
slug: "shopify"
tier: "2"
category: "Productivity"
description: "E-commerce platform hardening for Shopify Plus including SAML SSO, staff permissions, and store security"
version: "0.1.1"
maturity: "draft"
last_updated: "2026-06-29"
---

## Overview

Shopify is a leading e-commerce platform powering **millions of businesses** worldwide. As a platform handling customer data, payment information, and business transactions, Shopify security configurations directly impact data protection and PCI compliance.

### Intended Audience
- Security engineers managing e-commerce platforms
- IT administrators configuring Shopify Plus
- E-commerce managers securing stores
- GRC professionals assessing retail security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Shopify Plus security including SAML SSO, organization management, staff permissions, and store security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Store Security](#3-store-security)
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
Configure SAML SSO for Shopify Plus organization users.

#### Rationale
**Why This Matters:**
- Centralizes Shopify Plus authentication in your corporate IdP, enforcing MFA and conditional access on every staff login
- Local Shopify password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- Centralized deprovisioning through the IdP removes a departing employee's access instantly, eliminating orphaned accounts with standing reach into orders and customer data
- Shopify admin holds customer PII, order history, and payout settings, so a single compromised staff login can expose all of it

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Prerequisites
- Shopify Plus plan
- Organization owner access
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access Organization Settings**
1. Navigate to: **Shopify admin** → **Settings** → **Users**
2. Access organization settings
3. Find Security section

**Step 2: Configure SAML**
1. Enable SAML authentication
2. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
3. Download Shopify metadata for IdP

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
Require 2FA for all Shopify staff accounts.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks login even when a staff password is stolen, leaked, or reused across sites
- E-commerce admin accounts are high-value targets for takeover that redirects payouts, alters store content, or exfiltrates customer data
- Phishing-resistant factors such as security keys and authenticator apps defeat the credential-replay attacks aimed at retail platforms
- Requiring 2FA organization-wide closes the gap left by individual staff who would otherwise opt out

**Attack Prevented:** Credential stuffing, password reuse, phishing, account takeover

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Settings** → **Users**
2. Enable **Require two-step authentication**
3. All staff must configure 2FA

**Step 2: Configure via IdP**
1. Enable MFA in identity provider
2. Use phishing-resistant methods for admins

---

### 1.3 Configure Login Services

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Control allowed login methods.

#### Rationale
**Why This Matters:**
- Restricting login to SSO-only removes weaker fallback paths that attackers exploit to bypass your IdP
- Disabling unused authentication options shrinks the attack surface and reduces the number of credential sets to defend
- Forcing all access through a single monitored channel ensures every login is subject to MFA and conditional-access policy
- Legacy or social login providers may not enforce your organization's MFA and session controls

**Attack Prevented:** Authentication bypass, MFA downgrade, weak-login-path access

#### ClickOps Implementation

**Step 1: Review Login Options**
1. Configure allowed login services
2. Restrict to SSO only if possible
3. Disable unnecessary auth methods

---

## 2. Access Controls

### 2.1 Configure Staff Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for staff accounts.

#### Rationale
**Why This Matters:**
- Least-privilege permission groups ensure a compromised staff account can only reach the data and actions its role strictly needs
- Separating duties across orders, products, customers, and reports limits the blast radius of any single account takeover or insider misuse
- Over-broad permissions let routine staff export customer PII or change payout settings far beyond their job function
- Regular access reviews catch privilege creep and remove leftover access after role changes

**Attack Prevented:** Privilege escalation, insider data theft, lateral movement, excessive data exposure

#### ClickOps Implementation

**Step 1: Review Permission Groups**
1. Navigate to: **Settings** → **Users**
2. Review available permissions
3. Create custom permission groups

**Step 2: Assign Minimum Access**
1. Assign minimum necessary permissions
2. Separate by function:
   - Store management
   - Orders/fulfillment
   - Products
   - Customers
   - Reports
3. Regular access reviews

---

### 2.2 Configure Store Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to individual stores.

#### Rationale
**Why This Matters:**
- Scoping staff to only the stores they operate prevents one compromised account from reaching every store in the organization
- Separating production from development stores keeps test access from exposing live customer and order data
- Auditing cross-store access surfaces accounts that have quietly accumulated reach beyond their responsibilities
- In multi-store organizations, unpartitioned access multiplies the blast radius of any single breach

**Attack Prevented:** Lateral movement across stores, unauthorized data access, blast-radius expansion

#### ClickOps Implementation

**Step 1: Configure Store Permissions**
1. Limit staff to required stores only
2. Separate production and development
3. Audit cross-store access

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect organization owner accounts.

#### Rationale
**Why This Matters:**
- Organization owners hold the highest privileges, so fewer owners means fewer high-value accounts an attacker can target
- Owners can change billing, add or remove staff, and alter security settings, meaning one compromised owner controls the entire organization
- Requiring 2FA and monitoring owner activity makes takeover of these accounts substantially harder and faster to detect
- Documenting and pruning owner access prevents standing super-admin privileges from outliving their need

**Attack Prevented:** Privilege escalation, full-organization takeover, unauthorized security-setting changes

#### ClickOps Implementation

**Step 1: Inventory Owners**
1. Review organization owners
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit owners to 2-3 users
2. Require 2FA for owners
3. Monitor owner activity

---

## 3. Store Security

### 3.1 Configure API Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure API apps and access tokens.

#### Rationale
**Why This Matters:**
- API apps and access tokens are non-interactive credentials that often bypass MFA, making over-scoped tokens a direct path to bulk data exfiltration
- Removing unnecessary apps shrinks the third-party supply-chain surface, since a breached vendor app can read orders and customer PII
- Minimum-scope tokens limit what a leaked credential can do, and regular rotation shortens the window a stolen token stays valid
- Shopify's history includes third-party app vendors exposing thousands of stores' data through over-privileged integrations

**Attack Prevented:** Token theft, over-scoped API abuse, third-party app compromise, bulk data exfiltration

#### ClickOps Implementation

**Step 1: Review Apps**
1. Navigate to: **Settings** → **Apps and sales channels**
2. Review installed apps
3. Remove unnecessary apps

**Step 2: Secure API Credentials**
1. Use minimum required scopes
2. Protect API credentials
3. Rotate credentials regularly

---

### 3.2 Configure Checkout Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8 |

#### Description
Configure secure checkout settings.

#### Rationale
**Why This Matters:**
- HTTPS on checkout protects payment and personal data in transit from interception and man-in-the-middle attacks
- Fraud analysis flags high-risk orders before fulfillment, reducing chargebacks and abuse from stolen payment cards
- reCAPTCHA blocks automated bots from carding attacks, credential stuffing, and fake-account creation at checkout
- The checkout flow is where customer payment data is most exposed, making it a primary target for skimming and fraud

**Attack Prevented:** Man-in-the-middle interception, payment fraud, carding, bot abuse

#### ClickOps Implementation

**Step 1: Review Checkout Settings**
1. Ensure HTTPS enabled (default)
2. Configure fraud analysis
3. Enable reCAPTCHA

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Shopify Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Staff permissions | [2.1](#21-configure-staff-permissions) |
| CC6.7 | API security | [3.1](#31-configure-api-access) |

### PCI DSS v4.0 Mapping

| Requirement | Shopify Control | Guide Section |
|-------------|-----------------|---------------|
| 7 | Staff permissions | [2.1](#21-configure-staff-permissions) |
| 8 | Authentication | [1.1](#11-configure-saml-single-sign-on) |

---

## Appendix A: References

**Official Shopify Documentation:**
- [Shopify Security](https://www.shopify.com/security)
- [Help Center](https://help.shopify.com/en/)
- [Account Security Best Practices](https://help.shopify.com/en/manual/privacy-and-security/account-security/account-security-best-practices)
- [SAML Configuration](https://help.shopify.com/en/manual/shopify-plus/saml)
- [Staff Permissions](https://help.shopify.com/en/manual/your-account/staff-accounts)

**API & Developer Tools:**
- [Shopify Dev Docs](https://shopify.dev/docs)
- [Admin API Reference](https://shopify.dev/docs/api)
- [Shopify CLI](https://shopify.dev/docs/api/shopify-cli)
- [App Developer Tools & SDKs](https://shopify.dev/docs/apps/tools)

**Compliance Frameworks:**
- PCI DSS Level 1 (Service Provider), SOC 2 Type II, SOC 3 -- via [Compliance Reports](https://www.shopify.com/legal/compliance/reports)
- [Viewing Shopify's Compliance Reports](https://help.shopify.com/en/manual/privacy-and-security/account-security/compliance-reports)

**Security Incidents:**
- (2020) Two rogue support team members accessed data from approximately 200 merchants.
- (2024) Third-party app vendor (Saara) exposed 25 GB of data from 1,800+ Shopify stores via a misconfigured MongoDB database. Separately, a threat actor claimed to have 179,873 rows of user data.
- (2025-01) Critical vulnerability in the Consentik Shopify app exposed 4,180+ stores to code injection and account takeover.

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
