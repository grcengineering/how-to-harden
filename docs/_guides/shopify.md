---
layout: guide
title: "Shopify Plus Hardening Guide"
vendor: "Shopify"
slug: "shopify"
tier: "2"
category: "Productivity"
description: "E-commerce platform hardening for Shopify Plus including SAML SSO, staff permissions, and store security"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
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
- **A verified domain.** Shopify requires domain verification before SAML enforcement can be applied, and domain verification also gates the other organization-level user security features ([User security](https://help.shopify.com/en/manual/organization-settings/users/security))

#### ClickOps Implementation

**Step 1: Access Organization Settings**
1. Navigate to: **Shopify admin** → **Settings** → **Users**
2. Access organization settings
3. Find the **Security** section

**Step 2: Configure SAML**
1. Enable SAML authentication
2. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
3. Download Shopify metadata for IdP

**Step 3: Test and Choose an Enforcement Level**
1. Test SSO authentication before enforcing
2. Set the SAML enforcement level. Shopify documents **three discrete levels** ([SAML](https://help.shopify.com/en/manual/organization-settings/users/security/saml)):

   | Level | Who must use SAML |
   |-------|-------------------|
   | **Required** | All users with a matching email domain — explicitly including store owners and users outside the organization |
   | **Specific users** | Only the users you individually select |
   | **Off** | No one; SAML is available but never enforced |

3. Prefer **Required** — the middle level leaves password-login paths open for everyone you did not enumerate
4. Configure and document admin fallback before enforcing, since **Required** captures store owners too

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
1. Navigate to: **Settings** → **Users** → **Security**
2. Enable the two-step authentication requirement
3. All staff must configure two-step authentication

**Step 2: Prefer Phishing-Resistant Factors**
1. Have staff register **security keys** as their two-step authentication method — hardware keys defeat the credential-replay phishing aimed at retail admin accounts
2. Adopt **passkeys**, which Shopify documents as "a more secure replacement for passwords" ([Account security best practices](https://help.shopify.com/en/manual/privacy-and-security/account-security/account-security-best-practices))
3. Treat SMS as the fallback of last resort

**Step 3: Store Recovery Codes Safely**
1. Have every staff member generate and store their recovery codes in the organization's password manager, not in email or a local file
2. Lost recovery codes plus a lost device is an account-recovery incident; unprotected recovery codes are a second credential an attacker can steal

**Step 4: Configure via IdP**
1. Enable MFA in the identity provider for SSO-brokered logins
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

### 1.4 Automate User Management with SCIM

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.3 |
| NIST 800-53 | AC-2, AC-2(1) |

#### Description
Enable SCIM user management on the Shopify Plus organization and generate the SCIM API token so your identity provider creates, updates, and deactivates Shopify users automatically instead of an admin doing it by hand.

#### Rationale
**Why This Matters:**
- Deprovisioning that fires from the IdP removes a departing employee's Shopify access at the same instant as everything else, closing the offboarding gap that leaves standing access to orders, customer PII, and payout settings
- Manual user administration across a multi-store organization reliably drifts — SCIM makes the IdP the authoritative record of who holds Shopify access
- The SCIM API token is itself a high-value credential: it can manipulate the full user roster, so it must be stored in a secrets manager and rotated on schedule

**Attack Prevented:** Orphaned-account access, offboarding gaps, unauthorized account creation, access drift across stores

#### Prerequisites
- Shopify Plus plan
- Organization owner access
- A verified domain
- An IdP that supports SCIM provisioning

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Shopify admin** → **Settings** → **Users** → **Security**
2. Enable SCIM user management and generate the SCIM API token ([User security](https://help.shopify.com/en/manual/organization-settings/users/security))
3. Copy the token once — treat it as a secret with organization-wide user-management power

**Step 2: Connect the IdP**
1. Configure the Shopify SCIM connector in your identity provider using the generated token
2. Map IdP attributes to Shopify user attributes
3. Enable deactivation-on-deprovision

**Step 3: Protect and Rotate the Token**
1. Store the token in your secrets manager, never in a shared doc or ticket
2. Rotate it on a defined schedule and immediately on any suspected exposure
3. Verify with a test user that IdP deactivation removes Shopify access

---

## 2. Access Controls

### 2.1 Configure Staff Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for staff accounts using Shopify **roles** — predefined roles plus custom roles organized into role categories — and retire any permission sets still carrying the "Legacy access" badge.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure a compromised staff account can only reach the data and actions its role strictly needs
- Separating duties across orders, products, customers, and reports limits the blast radius of any single account takeover or insider misuse
- Over-broad permissions let routine staff export customer PII or change payout settings far beyond their job function
- Accounts still on auto-converted legacy permissions carry whatever they happened to hold at migration, which is rarely what a deliberate role design would grant
- Regular access reviews catch privilege creep and remove leftover access after role changes

**Attack Prevented:** Privilege escalation, insider data theft, lateral movement, excessive data exposure

> **Deprecated mechanism (as of May 1, 2025):** Shopify retired the standalone staff **custom permission groups** model. Legacy permissions were automatically converted to **roles**, and converted assignments surface with a **Legacy access** badge in **Settings** → **Users**. Guidance that tells you to "create a custom permission group" describes a model that no longer exists — build custom roles instead, and treat every remaining "Legacy access" badge as an unreviewed grant. Source: [Migrate to roles](https://help.shopify.com/en/manual/your-account/users/roles/migrate-to-roles)

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Users** → **Roles**
2. Review the **predefined roles** Shopify ships and the **custom roles** your organization has created
3. Review **role categories** to understand how roles are grouped and applied

**Step 2: Clear Legacy Access**
1. In **Settings** → **Users**, filter for accounts carrying the **Legacy access** badge
2. For each, decide the correct predefined or custom role and reassign
3. A remaining Legacy access badge means nobody has consciously approved that user's permission set since the migration

**Step 3: Assign Minimum Access**
1. Assign the least-privileged role that lets the person do their job
2. Separate by function:
   - Store management
   - Orders/fulfillment
   - Products
   - Customers
   - Reports
3. Run regular access reviews

**Step 4: Cover Newly Shipped Permissions**
1. On **2026-07-07** Shopify shipped four new staff permissions covering **payments**, **payouts**, **disputes**, and **tax documents** ([Shopify changelog](https://changelog.shopify.com/))
2. These are exactly the money-movement and financial-record surfaces least-privilege reviews exist to constrain — audit who holds them rather than inheriting a default
3. Add a changelog check to your periodic access review so newly introduced permissions do not accumulate unreviewed

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

### 2.4 Manage Access with User Groups

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-2, AC-6 |

#### Description
On Shopify Plus, use **user groups** to grant roles by membership rather than assigning roles to each staff account individually, so joiners and movers inherit exactly the access their team is supposed to have.

#### Rationale
**Why This Matters:**
- Group-inherited roles make access reviews tractable: you review a handful of groups instead of auditing every account's bespoke role stack
- Onboarding by group membership stops the common failure of copying an existing user's permissions and silently propagating over-broad access
- Group membership changes are a single, auditable event, which makes role changes easier to reconstruct during an investigation
- Access granted individually outside groups tends to be invisible in reviews and outlives the reason it was granted

**Attack Prevented:** Permission creep, over-broad access inheritance, unreviewed standing privileges, incomplete role-change cleanup

#### Prerequisites
- Shopify Plus plan
- Organization owner access

#### ClickOps Implementation

**Step 1: Design Groups Around Job Functions**
1. Create user groups that mirror actual job functions, not org-chart convenience
2. Attach the least-privileged role each function needs to its group ([User groups](https://help.shopify.com/en/manual/your-account/users/groups))

**Step 2: Understand Removal Semantics**
1. Removing a user from a group strips **only the permissions that group granted** — any role assigned to the user directly survives the removal
2. Because of this, directly-assigned roles are the ones that quietly outlive a transfer or departure; audit them separately from group grants
3. When a user changes teams, remove the old group AND re-check their direct assignments

**Step 3: Review**
1. Review group membership and group-attached roles on the same cadence as your staff access review
2. Prefer moving direct assignments into groups so future reviews cover them automatically

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

**Step 3: Meet the Protected Customer Data Requirements**
1. Any app accessing protected customer data must satisfy Shopify's documented requirements ([Protected customer data](https://shopify.dev/docs/apps/launch/protected-customer-data)). Apply the same bar when vetting third-party apps and when building your own:

   | Level | Requirements |
   |-------|--------------|
   | **Level 1** — protected customer data | Data minimization, purpose limitation, retention limits, encryption at rest and in transit |
   | **Level 2** — protected customer fields (name, email, phone, address) | Everything in Level 1, plus encrypted backups, separation of test and production environments, data loss prevention, staff access restrictions, access logging, and a documented incident response policy |

2. Before installing an app that requests protected customer fields, ask the vendor which level it operates at and how it satisfies the Level 2 items — most breaches of Shopify merchant data have come through third-party apps, not Shopify itself
3. For in-house apps, treat this list as the minimum control set, not as guidance

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
- [Help Center](https://help.shopify.com/en/)
- [Account Security Best Practices](https://help.shopify.com/en/manual/privacy-and-security/account-security/account-security-best-practices)
- [SAML Configuration](https://help.shopify.com/en/manual/organization-settings/users/security/saml)
- [User Security (domain verification, SCIM)](https://help.shopify.com/en/manual/organization-settings/users/security)
- [Migrate to Roles](https://help.shopify.com/en/manual/your-account/users/roles/migrate-to-roles)
- [User Groups](https://help.shopify.com/en/manual/your-account/users/groups)
- [Protected Customer Data Requirements](https://shopify.dev/docs/apps/launch/protected-customer-data)
- [Shopify Changelog](https://changelog.shopify.com/)

> **Link note (2026-08-08):** the SAML documentation moved from `/manual/shopify-plus/saml` to `/manual/organization-settings/users/security/saml`; the old path now renders a generic page rather than the SAML article.

**API & Developer Tools:**
- [Shopify Dev Docs](https://shopify.dev/docs)
- [Admin API Reference](https://shopify.dev/docs/api)
- [Shopify CLI](https://shopify.dev/docs/api/shopify-cli)
- [App Developer Tools & SDKs](https://shopify.dev/docs/apps/tools)

**Compliance Frameworks:**
- PCI DSS Level 1 (Service Provider), SOC 2 Type II, SOC 3 — merchants retrieve current attestations through the admin per [Viewing Shopify's Compliance Reports](https://help.shopify.com/en/manual/privacy-and-security/account-security/compliance-reports). Compliance reports describe Shopify's own posture; they are not merchant configuration guidance.

**Security Incidents:**
- (2020) Two rogue support team members accessed data from approximately 200 merchants.
- (2024) Third-party app vendor (Saara) exposed 25 GB of data from 1,800+ Shopify stores via a misconfigured MongoDB database. Separately, a threat actor claimed to have 179,873 rows of user data.
- (2025-01) Critical vulnerability in the Consentik Shopify app exposed 4,180+ stores to code injection and account takeover.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass: rewrite 2.1 around roles after the May 1 2025 retirement of custom permission groups (Legacy access badge) and add the 2026-07-07 payments/payouts/disputes/tax-document permissions; repoint SAML docs to the current canonical URL; document the three SAML enforcement levels and the verified-domain prerequisite; add 1.4 SCIM user management and 2.4 user groups; add passkeys, security keys, and recovery-code handling to 1.2; add the protected customer data Level 1/Level 2 requirements to 3.1; remove the Trust Center and compliance-reports marketing links from Appendix A. Tier 3/4 sources not surveyed this pass. | Claude Code (Opus 5) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO and permissions | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
