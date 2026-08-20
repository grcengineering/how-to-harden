---
layout: guide
title: "Fullstory Hardening Guide"
vendor: "Fullstory"
slug: "fullstory"
tier: "3"
category: "Data"
description: "Digital experience intelligence platform hardening for Fullstory including SAML SSO, data privacy controls, and access management"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Fullstory is a digital experience intelligence platform providing session replay and analytics. As a platform capturing user sessions and interaction data, Fullstory security configurations directly impact data privacy and user trust.

### Intended Audience
- Security engineers managing analytics platforms
- IT administrators configuring Fullstory
- Product teams managing digital experience tools
- GRC professionals assessing data security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Fullstory users.

#### Rationale
**Why This Matters:**
- Centralizes Fullstory authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local password logins bypass IdP controls and are a prime target for credential stuffing and phishing
- SSO enables automatic deprovisioning so departed employees immediately lose access to recorded session data
- Fullstory captures full user sessions that can contain PII, so a single compromised login can expose sensitive customer interaction data

**Attack Prevented:** Credential theft, phishing, credential stuffing, orphaned-account access

#### Prerequisites
- Fullstory **Admin** role
- Enterprise plan
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Account Management** → **SSO**
2. Enable SAML SSO

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Download Fullstory metadata for IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO-only login enforcement (see 1.3)
3. Document your emergency access procedure before enforcing

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Fullstory users.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks account takeover even when a password is leaked, reused, or guessed
- Fullstory dashboards expose recorded sessions, heatmaps, and analytics that can contain customer PII
- Phishing-resistant factors for admins stop attackers from using stolen credentials to alter security settings
- Enforcing MFA at the IdP applies it uniformly across every SSO user without per-account configuration

**Attack Prevented:** Password reuse, credential stuffing, phishing, account takeover

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

---

### 1.3 Require SSO for All Teammates

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.4 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Turn on Fullstory's **Require SSO for all teammates** setting so email/password login is closed and every covered seat must authenticate through your identity provider.

#### Rationale
**Why This Matters:**
- Configuring SAML without enforcing it leaves the local password path open, so an attacker with a leaked or reused password never has to touch your IdP or its MFA
- Enforcement is what makes IdP deprovisioning actually terminate access — without it, a disabled IdP account can still hold a working Fullstory password
- Fullstory holds recorded user sessions that can contain customer PII, making any unenforced bypass path a high-value target

**Attack Prevented:** MFA bypass via local password login, credential stuffing, orphaned-account access after IdP deprovisioning

#### Prerequisites
- SAML SSO already configured and tested (see 1.1)
- Fullstory **Admin** role
- Enterprise plan

#### ClickOps Implementation

**Step 1: Verify SSO Works First**
1. Confirm at least one admin can sign in successfully via SAML before enforcing — enforcing with a broken SAML configuration locks the account out
2. Document your break-glass procedure and the support path for recovering access

**Step 2: Enable Enforcement**
1. Navigate to: **Settings** → **Account Management** → **SSO**
2. Enable **Require SSO for all teammates**

**Step 3: Understand the Coverage Gap**
1. Fullstory documents this enforcement as covering **Standard, Admin, Architect, and Umbrella Manager** seats
2. **Guest seats are not listed among the covered roles.** Do not assume Guest logins are forced through the IdP — verify Guest sign-in behavior in your own account, and if Guests can still authenticate locally, treat Guest seats as an access-review item and keep their count near zero

**Step 4: Verify**
1. Attempt an email/password login for a covered seat and confirm it is refused
2. Confirm SAML login still succeeds for each covered role you use

### 2.1 Configure User Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Fullstory roles.

#### Rationale
**Why This Matters:**
- Assigning the minimum necessary role limits what each user can see and change, shrinking the blast radius of a compromised account
- Guest is the true read-only floor — anything above it carries capabilities most viewers do not need
- Over-provisioned accounts let a single phished user export session data or disable privacy controls
- Regular access reviews catch role creep before it becomes a standing risk

**Attack Prevented:** Privilege escalation, insider misuse, excessive data exposure

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Account Management**
2. Fullstory teammate roles are:
   - **Guest** — the most limited role; use this as your read-only floor
   - **Explorer** — available on Enterprise plans only
   - **Standard**
   - **Architect**
   - **Admin**
   - **Umbrella Admin** — manages multiple accounts under an umbrella organization
3. Assign the minimum necessary role

**Step 2: Apply Least Privilege**
1. Use **Guest** for read-only access — there is no "Viewer" role in Fullstory, so a request for "view only" maps to Guest
2. Limit **Admin**, **Architect**, and **Umbrella Admin** to the smallest workable set; these roles can change privacy capture rules, retention behavior, and SSO enforcement
3. Reserve **Explorer** for Enterprise accounts where the extra capability is actually needed
4. Run regular access reviews, paying particular attention to seats that were provisioned automatically (see 2.3)

---

### 2.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Administrators can change privacy masking, retention, and SSO enforcement, making each admin account a high-value target
- Keeping the admin count small reduces the number of credentials an attacker can target to gain full control
- Requiring SSO and MFA for admins ensures these powerful accounts inherit your strongest authentication controls
- Monitoring admin activity surfaces unauthorized configuration changes that could weaken data protections

**Attack Prevented:** Privilege escalation, admin account takeover, unauthorized configuration changes

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

### 2.3 Map Roles From SAML Attributes

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.1 |
| NIST 800-53 | AC-2, AC-6 |

#### Description
Drive Fullstory role assignment from a SAML attribute sent by your identity provider, so role changes follow the IdP rather than being maintained by hand in Fullstory.

#### Rationale
**Why This Matters:**
- Making the IdP authoritative for roles means a demotion or team change in your directory is reflected in Fullstory without anyone remembering to do it manually
- Manual role maintenance is where privilege creep accumulates — a user promoted for a one-off project keeps the role indefinitely
- Just-in-time seat creation without role control silently grants every new user a working seat, so pairing JIT with attribute-driven roles is what keeps automatic provisioning least-privilege

**Attack Prevented:** Privilege creep, stale elevated roles after role change, over-privileged auto-provisioned accounts

#### Prerequisites
- SAML SSO configured (see 1.1)
- Fullstory **Admin** role
- Enterprise plan
- IdP able to emit a custom SAML attribute

#### ClickOps Implementation

**Step 1: Understand the All-or-Nothing Tradeoff**
1. **Enabling SAML role mapping disables manual role updates account-wide.** Once it is on, every role change must come from the IdP — there is no per-user exception, and an admin cannot hand-edit a single teammate's role
2. Confirm your IdP can emit the attribute reliably for every teammate before enabling, including contractors and service accounts, or those users will be stuck at whatever role the attribute (or its absence) produces

**Step 2: Configure the IdP Attribute**
1. Configure your IdP to send the SAML attribute `fullstoryRole`
2. Valid values are: `guest`, `standard`, `explorer`, `admin`, `architect`
3. Drive the value from IdP group membership so role changes are a group operation, not a per-user edit

**Step 3: Enable Mapping in Fullstory**
1. Navigate to: **Settings** → **Account Management** → **SSO**
2. Enable **Map users to roles via SAML attribute**

**Step 4: Handle JIT Provisioning Carefully**
1. The just-in-time toggle is **Automatically create new user accounts (just-in-time seat provisioning)**
2. **JIT-created users default to a Standard seat, not the least-privileged one.** If you enable JIT without role mapping, anyone who can authenticate to the SAML application gets a Standard seat automatically
3. Either enable role mapping alongside JIT so the attribute governs the seat, or leave JIT off and provision seats deliberately

#### Validation & Testing
- Change a test user's IdP group, re-authenticate, and confirm the Fullstory role changes to match
- Confirm the Fullstory UI no longer offers manual role edits once mapping is enabled
- Confirm a JIT-provisioned test user lands on the intended role rather than the Standard default

---

### 2.4 Automate Provisioning With SCIM

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3, 6.2 |
| NIST 800-53 | AC-2, AC-2(1) |

#### Description
Connect your identity provider to Fullstory over SCIM so teammate accounts are created, updated, and deactivated automatically from the directory.

#### Rationale
**Why This Matters:**
- SCIM deprovisioning removes a departed teammate's access to recorded session data as soon as the directory account is disabled, closing the offboarding gap that manual processes leave open
- Directory-driven account lifecycle keeps the Fullstory seat list reconcilable against HR reality instead of drifting
- Group-driven role assignment through SCIM reduces the manual privilege edits that accumulate into over-provisioned accounts

**Attack Prevented:** Orphaned-account access after offboarding, provisioning drift, over-provisioned manual accounts

#### Prerequisites
- Enterprise plan
- Fullstory **Admin** role
- SAML SSO configured first — SCIM builds on the SAML configuration (see 1.1)
- **Okta.** Fullstory's SCIM integration was built and tested against Okta; if your IdP is not Okta, verify support with Fullstory before designing an offboarding process around it

#### ClickOps Implementation

**Step 1: Generate the SCIM Token**
1. Navigate to: **Settings** → **Account Management** → **SSO**
2. Open **Account Provisioning** → **SCIM Provisioning**
3. Click **Generate Authorization Token** and store the token in your secret manager — it is a credential that can create and remove Fullstory accounts

**Step 2: Configure the IdP**
1. Configure SCIM provisioning in Okta using the generated authorization token
2. Enable create, update, and deactivate operations — deactivate is the one that closes the offboarding gap

**Step 3: Map Groups to Roles**
1. IdP groups can be mapped to the **Admin**, **Architect**, **Standard**, **Explorer**, and **Guest** roles
2. **Umbrella Manager is not supported** by SCIM group mapping — those seats must be managed separately, so keep an explicit manual review for them
3. Default new-user groups to **Guest** and grant higher roles by deliberate group membership

**Step 4: Reconcile**
1. Compare the Fullstory teammate list against the directory after the first sync and resolve any account that exists in one and not the other

#### Validation & Testing
- Deactivate a test user in the IdP and confirm the Fullstory seat is deactivated
- Move a test user between mapped groups and confirm the role changes
- Confirm any Umbrella Manager seats are tracked outside the SCIM flow, since SCIM will not manage them

---

## 3. Data Privacy

### 3.1 Configure Privacy Controls

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Configure privacy controls to protect user data.

#### Rationale
**Why This Matters:**
- Element exclusions and field masking prevent Fullstory from ever capturing passwords, payment details, and other sensitive PII
- Private-by-default capture excludes data unless it is explicitly allowed, reducing the chance of accidental collection
- Minimizing what is recorded shrinks the data exposed if the Fullstory account or stored sessions are breached
- Excluding sensitive pages and fields supports GDPR, CCPA, and PCI obligations to avoid storing regulated data

**Attack Prevented:** Sensitive data exposure, PII leakage, regulatory non-compliance

#### ClickOps Implementation

**Step 1: Open the Privacy Settings**
1. Click your account name and navigate to: **Settings** → **Data Capture and Privacy** → **Privacy**
2. This surface requires the **Admin** role and is available on all plans

**Step 2: Work Through the Five Privacy Tabs**
1. **General** — account-wide capture defaults
2. **URL** — exclude or restrict capture on sensitive pages by URL
3. **Element** — element-level rules, split into **Configured**, **Form**, and **Mobile Unmask** sub-surfaces; this is where you mask specific fields and elements
4. **Network** — rules governing captured network activity
5. **Header Privacy Rules** — rules governing captured headers
6. Cover each tab deliberately: a rule set that masks form inputs but leaves a sensitive URL or response header capturing is still leaking

**Step 3: Prefer Exclusion Over Masking for Regulated Data**
1. For payment, credential, and health fields, exclude capture entirely rather than relying on display-time masking
2. Re-review the rules whenever the application ships new pages or forms — privacy rules are matched against markup that changes underneath them

---

### 3.2 Configure Data Retention

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SI-12 |

#### Description
Establish what your plan actually retains — Fullstory retention is plan-driven, with separate windows for session replay and for analytics — and use session deletion to remove data ahead of those windows.

#### Rationale
**Why This Matters:**
- Retention in Fullstory is not a single dial you set: it is determined by your plan, and the replay window and the analytics window are different lengths, so assuming one number governs everything will misstate your actual exposure
- Sessions that fall outside the replay window are purged, so any compliance or investigation process that assumes older replays are still available will fail when it matters
- Explicit session deletion is the mechanism for honoring erasure requests before the plan's window expires, rather than waiting out the retention period

**Attack Prevented:** Excessive data retention, unmet erasure obligations, misjudged exposure window during an incident

#### ClickOps Implementation

**Step 1: Establish Your Actual Retention Windows**
1. Confirm, for your specific plan, both the **session replay retention window** and the **analytics/metrics retention window** — these are different, and the analytics window is typically the longer of the two
2. Record both in your data inventory. When answering "how long do we keep session data," answer with both numbers
3. Note that sessions older than the replay window are purged — replay is not recoverable after that point even though aggregate analytics may persist

**Step 2: Use Session Deletion for Erasure**
1. Fullstory documents session deletion separately from retention, at individual-session, per-user, and bulk granularity
2. Wire the per-user deletion path into your GDPR/CCPA erasure runbook so a request is satisfied on demand rather than by waiting for retention to expire
3. Record deletions so you can evidence the request was honored

**Step 3: Minimize What Is Retained in the First Place**
1. Retention only bounds how long data lives; privacy rules (see 3.1) bound whether it is ever captured
2. Treat capture exclusion as the primary control and retention as the backstop

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
| IA-8 | SSO-only enforcement | [1.3](#13-require-sso-for-all-teammates) |
| AC-2 | SCIM provisioning | [2.4](#24-automate-provisioning-with-scim) |
| AC-6 | User roles | [2.1](#21-configure-user-roles) |
| AC-3 | Privacy controls | [3.1](#31-configure-privacy-controls) |
| SI-12 | Retention and session deletion | [3.2](#32-configure-data-retention) |

---

## Appendix A: References

**Official Fullstory Documentation:**
- [Help Center](https://help.fullstory.com/hc/en-us)
- [How do I configure SSO?](https://help.fullstory.com/hc/en-us/articles/360020623014-How-do-I-configure-SSO)
- [Configuring SCIM for Automated User Provisioning](https://help.fullstory.com/hc/en-us/articles/30544962047383-Configuring-SCIM-for-Automated-User-Provisioning-in-Fullstory)
- [What user roles are available for Fullstory teammates?](https://help.fullstory.com/hc/en-us/articles/360020624774-What-user-roles-are-available-for-Fullstory-teammates)
- [Privacy Settings in Fullstory](https://help.fullstory.com/hc/en-us/articles/34807885576215-Privacy-Settings-in-Fullstory)
- [Fullstory Plan Retention](https://help.fullstory.com/hc/en-us/articles/4559287110039-Fullstory-Plan-Retention)
- [Can I delete sessions?](https://help.fullstory.com/hc/en-us/articles/360020827493-Can-I-delete-sessions)

**API & Developer Documentation:**
- [Fullstory Developer Portal](https://developer.fullstory.com/)

**Security Incidents:**
- No major public security incidents identified affecting the Fullstory platform.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against Fullstory help-center docs: corrected 2.1 (real role list is Guest / Explorer (Enterprise-only) / Standard / Architect / Admin / Umbrella Admin — no "Viewer" role exists; Guest is the read-only floor), 1.1 (SSO lives at Settings > Account Management > SSO), 3.1 (privacy lives at Settings > Data Capture and Privacy > Privacy with five tabs — General, URL, Element, Network, Header Privacy Rules), and 3.2 (retention is plan-driven with distinct replay and analytics windows; sessions outside the replay window are purged; session deletion is a separate documented mechanism); added 1.3 Require SSO for all teammates (noting Guest seats are not listed among covered roles), 2.3 SAML role mapping via the `fullstoryRole` attribute (all-or-nothing — disables manual role edits account-wide; JIT defaults to a Standard seat, not least privilege), and 2.4 SCIM provisioning (Okta-tested; Umbrella Manager unsupported); replaced the mis-cited SSO reference (360020624174 renders a user-management API article) with 360020623014, removed the duplicated 360020624254 rows, and pruned Trust Center, /security marketing, and the compliance-program block from Appendix A. Tier 2 survey found no CIS Benchmark, DISA STIG, or CISA SCuBA baseline for Fullstory; Tier 3/4 not surveyed this pass. Whether Fullstory exposes an admin audit log was not confirmed and is deliberately not claimed either way. | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and privacy controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
