---
layout: guide
title: "KnowBe4 Hardening Guide"
vendor: "KnowBe4"
slug: "knowbe4"
tier: "2"
category: "Security"
description: "Security awareness training platform hardening for KnowBe4 including SAML SSO, admin access, and campaign security"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

KnowBe4 is a leading security awareness training platform providing phishing simulations and training. As a platform managing employee training data and conducting security tests, KnowBe4 security configurations directly impact training integrity and data protection.

This guide covers the **KnowBe4 Security Awareness Training (KSAT) console** — the vendor's own term for the training and phishing-simulation admin console. The wider KnowBe4 estate now also includes the Egress-derived products (Defend, Prevent, and Secure Workspace), which carry their own system roles, MFA configuration, and audit surfaces. Those are **out of scope here** and are a candidate for a future platform breakout.

### Intended Audience
- Security engineers managing awareness programs
- IT administrators configuring KnowBe4
- Security awareness managers
- GRC professionals assessing training programs

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers the KnowBe4 Security Awareness Training (KSAT) console: SAML SSO, admin access and Security Roles, campaign configuration, API and provisioning tokens, and the KSAT Audit Log. It does **not** cover the Egress-derived KnowBe4 products (Defend, Prevent, Secure Workspace), which have separate role, MFA, and audit surfaces.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Campaign Security](#3-campaign-security)
4. [Monitoring & Auditing](#4-monitoring--auditing)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for KSAT console access and disable the non-SAML login paths, which are publicly reachable by default.

#### Rationale
**Why This Matters:**
- Centralizes KnowBe4 console authentication in your corporate IdP, applying MFA, conditional access, and session policy to every admin login
- Local KnowBe4 passwords bypass IdP controls and are prime targets for credential stuffing and phishing
- IdP-driven provisioning and deprovisioning removes departed admins automatically, eliminating orphaned accounts that retain access to training data and campaign tooling
- A compromised KSAT admin can view employee PII and training records and launch fake phishing campaigns that erode the program's credibility
- KnowBe4 states that **the bypass SSO URL is public** — both the standard login page and `/ui/users/login` remain reachable — so SAML alone does not remove the password path unless it is explicitly disabled

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access, SSO bypass via the public password login

#### Prerequisites
- KSAT admin access
- A SAML 2.0 compatible IdP
- **No subscription tier is required to connect SAML SSO** — free accounts can configure it. Subscription level gates the **Users tab and provisioning** features, not the SAML connection itself.

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Account Settings** → **Account Integrations** → **SAML**
2. Enable SAML authentication

**Step 2: Configure SAML**
1. Configure IdP settings:
   - Entity ID
   - SSO URL
   - Certificate
2. Download KnowBe4 metadata for IdP
3. Enable **Sign SP AuthnRequest** so the service-provider request is signed
4. Configure the certificate **expiration notification** so an expiring IdP certificate does not silently break authentication

**Step 3: Close the Bypass Paths**
1. Enable **Disable non-SAML Logins for All Users**. This kills password-based logins and the bypass SSO URLs.
2. Leave **Allow Account Creation from SAML Login** **OFF** — when enabled, any identity that successfully completes SAML is auto-provisioned an account, turning a mis-scoped IdP assignment into unauthorized console access.
3. Decide deliberately about **Allow Admins with MFA to Bypass SAML Login**:
   - Leaving it **off** is the strictest posture, but note that account admins retain a password login as KnowBe4's own lockout safeguard
   - If you enable it, the bypass account **must** have MFA enrolled ([1.2](#12-enforce-multi-factor-authentication)) — an MFA-less bypass admin is an unauthenticated-by-IdP door into the console

> **The bypass URL is public.** KnowBe4 documents that the bypass SSO URL is public, reachable via the login page and `/ui/users/login`, and that account admins retain password login as a safeguard against lockout. Treat the bypass path as internet-exposed: either disable non-SAML logins outright, or ensure every account that can still use it is MFA-protected. — [KnowBe4 Console Account Settings: Account Integrations](https://support.knowbe4.com/hc/en-us/articles/12769050560403-KnowBe4-Console-Account-Settings-Account-Integrations)

**Step 4: Test**
1. Test SSO authentication with a non-admin account before enforcing
2. Confirm the password login path behaves as intended after the change

**Time to Complete:** ~1-2 hours

#### Validation & Testing
- From a private browser session, visit the console login page and `/ui/users/login` and confirm the password path is refused (or, if intentionally retained for admins, that it challenges for MFA).
- Attempt a SAML login as an identity with no KSAT account and confirm no account is auto-created.

**Sources:** [Set Up SAML SSO for the SAT Console](https://support.knowbe4.com/hc/en-us/articles/360041935913-Set-Up-SAML-Single-Sign-on-SSO-for-the-Security-Awareness-Training-Console) · [KnowBe4 Console Account Settings: Account Integrations](https://support.knowbe4.com/hc/en-us/articles/12769050560403-KnowBe4-Console-Account-Settings-Account-Integrations)

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Enable MFA account-wide for the KSAT console, and obtain phishing-resistant factors through the IdP, since KnowBe4's native MFA is TOTP-only.

#### Rationale
**Why This Matters:**
- MFA blocks account takeover even when an admin password is phished, leaked, or reused from another breach
- KSAT admin accounts control phishing simulations and employee training data, so a single stolen password should never be enough to reach them
- KnowBe4's native console MFA is **TOTP only** — there is no native FIDO2/WebAuthn option — so time-based codes remain relayable by an adversary-in-the-middle proxy; phishing resistance is only achievable by forcing logins through an IdP that offers it ([1.1](#11-configure-saml-single-sign-on))
- The platform's purpose is anti-phishing, so an admin account compromised by phishing would directly undermine the program's goals

**Attack Prevented:** Credential stuffing, password reuse, phishing, account takeover via the public bypass login path

#### ClickOps Implementation

**Step 1: Enforce MFA Account-Wide**
1. Navigate to: **Account Settings** → **User Management**
2. Enable the account-wide MFA requirement so it applies to all console users rather than being left to individual opt-in

**Step 2: Verify and Enroll Individual Users**
1. Per-user MFA is managed either from the user's own **Profile** → **Multi-Factor Authentication**, or by an admin at **Users** → select the user → **User Information**
2. Confirm every account that retains a password login path — especially any admin permitted to bypass SAML — is enrolled

**Step 3: Obtain Phishing Resistance via the IdP**
1. Native KSAT MFA offers TOTP only; do not treat it as phishing-resistant
2. Enforce FIDO2/WebAuthn or platform passkeys in the IdP and route console access through SAML SSO
3. Keep at least one admin able to authenticate — **the console must retain at least one admin**, so never remove or lock out the final administrative account

#### Validation & Testing
- Attempt a console login as a test user without an enrolled factor and confirm enrollment is compelled.
- Confirm the account retains at least one working administrator after any MFA or role change.

**Sources:** [Enable Two-Factor or Multi-Factor Authentication on Your Account](https://support.knowbe4.com/hc/en-us/articles/225681448-Enable-Two-Factor-or-Multi-Factor-Authentication-on-Your-Account) · [KnowBe4 Console Account Settings: User Management](https://support.knowbe4.com/hc/en-us/articles/12731036715411-KnowBe4-Console-Account-Settings-User-Management)

---

## 2. Access Controls

### 2.1 Configure Admin Access and Security Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Grant the KSAT admin toggle to as few users as possible, and use Security Roles — assigned to groups — to give everyone else scoped access instead.

#### Rationale
**Why This Matters:**
- KSAT admin access is a **per-user toggle, not a graduated role**: turning it on grants that user **every tab and all data** in the console, including employee PII, training records, and campaign tooling
- Because the toggle is all-or-nothing, least privilege in KSAT is achieved through **Security Roles**, which scope what a user can see and do — there is no built-in intermediate admin tier
- Security Roles are assigned to **groups**, not to individual users, so group membership hygiene is the real access control and must be reviewed alongside the roles themselves
- An over-granted admin toggle gives an attacker full control over training data, user records, and simulation configuration in a single step

**Attack Prevented:** Privilege escalation, insider misuse, bulk PII exfiltration, excessive blast radius from a single compromised account

#### Prerequisites
- **Security Roles require SAT Advanced, Platinum, or Diamond.** On lower tiers the admin toggle is the only access lever available, which makes minimizing the number of admins the entire control.

#### ClickOps Implementation

**Step 1: Inventory and Minimize Admin Grants**
1. Navigate to the **Users** tab
2. Review which users carry the admin toggle — remember each one has access to all tabs and all data
3. Remove the toggle from anyone who does not need full console administration
4. The console must retain **at least one admin**; never remove the last one

**Step 2: Build Scoped Security Roles**
1. Navigate to: **Users** tab → **Security Roles** subtab
2. Create roles that reflect real job functions (for example, a reporting-only role for analysts who need results but not configuration)
3. Grant each role the minimum permission set for that function

**Step 3: Assign Roles to Groups**
1. Assign each Security Role to the appropriate **group** — roles attach to groups, not to individual users
2. Keep group membership tied to your directory or provisioning source so joiners and leavers flow through automatically
3. Audit group membership on the same cadence as the roles, since membership is what actually confers the permissions

**Step 4: Regular Access Reviews**
1. Review the admin-toggle list and the Security Role-to-group assignments quarterly
2. Confirm departures have lost both the admin toggle and their group memberships
3. Cross-check changes against the Audit Log ([4.1](#41-review-and-export-the-ksat-audit-log))

#### Validation & Testing
- Sign in as a member of a scoped Security Role group and confirm restricted tabs are genuinely unavailable.
- Confirm the admin-toggle list matches the documented set of approved administrators.

**Sources:** [Assign and Remove Admin Functions from a User](https://support.knowbe4.com/hc/en-us/articles/205015187-Assign-and-Remove-Admin-Functions-from-a-User) · [Security Roles Guide](https://support.knowbe4.com/hc/en-us/articles/115015389767-Security-Roles-Guide)

---

### 2.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect admin accounts.

#### Rationale
**Why This Matters:**
- Fewer Account Owner and Full Admin accounts means fewer high-value targets for attackers to phish or compromise
- Maintaining an inventory of admins makes unauthorized or orphaned privileged accounts visible during access reviews
- Requiring MFA and monitoring activity on every admin account detects and slows misuse before damage spreads
- Each unnecessary admin is standing access to employee PII, training records, and campaign tooling that can be abused

**Attack Prevented:** Account takeover, insider misuse, orphaned-account access, undetected privileged activity

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review all admin accounts
2. Document admin access

**Step 2: Apply Restrictions**
1. Limit owners to 2-3 users
2. Require MFA for all admins
3. Monitor admin activity

---

## 3. Campaign Security

### 3.1 Configure Phishing Campaign Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 17.3 |
| NIST 800-53 | AT-2 |

#### Description
Secure phishing simulation campaigns.

#### Rationale
**Why This Matters:**
- Notifying IT and security and allowlisting simulation domains prevents your own teams from chasing simulated phishing as a live incident
- Restricting access to campaign results protects sensitive data on which employees clicked or failed, preventing it from being used to single out or shame staff
- Configuring data retention limits how long employee click and failure data is stored, reducing exposure if the account is breached
- Misconfigured landing pages or leaked results can themselves become a vector for harvesting credentials or damaging employee trust

**Attack Prevented:** Simulation data leakage, employee privacy exposure, wasted false-incident response, landing-page abuse

#### ClickOps Implementation

**Step 1: Configure Campaign Notifications**
1. Notify IT/security of campaigns
2. Allowlist simulation domains
3. Configure landing pages securely

**Step 2: Protect Campaign Data**
1. Limit access to results
2. Configure data retention
3. Protect employee privacy

---

### 3.2 Secure API and Provisioning Tokens

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Manage the reporting API key and the ADI Sync and SCIM provisioning tokens as first-class secrets, all of which live on the Account Integrations surface.

#### Rationale
**Why This Matters:**
- KnowBe4 API keys grant programmatic access to user lists, training records, and phishing results, so a leaked key exposes all of it without a login
- The **ADI Sync Token** and **SCIM Token** are equally sensitive and often overlooked: they drive user provisioning, so a leaked one can be used to enumerate or manipulate the console's user population
- These tokens are **single-view, regenerable secrets** — shown once and replaced rather than retrieved — so any copy that escapes into a ticket, chat, or config file is the only copy an attacker needs, and rotation is the only remedy
- Regular rotation limits the window in which a leaked or copied credential remains usable, and monitoring API usage surfaces anomalous bulk data pulls

**Attack Prevented:** Credential leakage, bulk data exfiltration, unauthorized provisioning changes, stale-key abuse

#### ClickOps Implementation

**Step 1: Locate the API Surface**
1. Navigate to: **Account Settings** → **Account Integrations**
2. API reporting now lives here alongside SAML, Phish Alert Button (PAB), and PhishER — it is no longer a separate top-level API page
3. Inventory every credential on this surface: the reporting API key, the **ADI Sync Token**, and the **SCIM Token**

**Step 2: Secure the Secrets**
1. Capture each token directly into a secret manager at the moment it is generated — it is displayed once
2. Never paste tokens into tickets, chat, source control, or CI configuration files
3. Record the owner and purpose of each credential so an unexplained one is identifiable

**Step 3: Rotate on a Schedule and on Suspicion**
1. Regenerate the reporting API key, ADI Sync Token, and SCIM Token on a defined rotation schedule
2. Regenerate immediately on suspected exposure or when an owner leaves
3. Note that the KSAT Audit Log does **not** record API key changes ([4.1](#41-review-and-export-the-ksat-audit-log)), so rotation events must be tracked in your own change record

**Step 4: Monitor Usage**
1. Watch for anomalous bulk pulls of user or results data
2. Investigate provisioning changes that do not correspond to a known directory event

#### Validation & Testing
- Confirm no API key, ADI Sync Token, or SCIM Token appears in source control, CI variables, or documentation.
- Confirm each credential has a recorded owner and a rotation date inside the agreed interval.

**Sources:** [KnowBe4 Console Account Settings: Account Integrations](https://support.knowbe4.com/hc/en-us/articles/12769050560403-KnowBe4-Console-Account-Settings-Account-Integrations) · [KnowBe4 Console Account Settings: User Management](https://support.knowbe4.com/hc/en-us/articles/12731036715411-KnowBe4-Console-Account-Settings-User-Management)

---

## 4. Monitoring & Auditing

### 4.1 Review and Export the KSAT Audit Log

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.10 |
| NIST 800-53 | AU-2, AU-6, AU-11 |

#### Description
Use the KSAT Audit Log to review admin, agent, and Security Role changes, and export it on a schedule that beats its 180-day retention window.

#### Rationale
**Why This Matters:**
- The Audit Log is the record of who was granted admin access, who changed Security Roles, and who altered console configuration — exactly the events that precede or constitute a console compromise
- Retention is **180 days**, so any investigation reaching further back is impossible unless the log has already been exported into your own retention tier
- The log has documented blind spots — it does **not** track password changes or API key changes — so those must be covered by compensating records rather than assumed to be logged
- Alerting on admin grants and SAML setting changes catches an attacker granting themselves access or re-opening the bypass login path ([1.1](#11-configure-saml-single-sign-on))

**Attack Prevented:** Undetected privilege grants, silent SSO weakening, repudiation of console changes, evidence loss past the retention window

#### Prerequisites
- Available on **SAT Foundation and above**

#### ClickOps Implementation

**Step 1: Access the Audit Log**
1. Click your **[email address]** in the top-right of the console
2. Select **Audit Log**
3. Review admin changes, agent changes, and Security Role changes

**Step 2: Filter and Export**
1. Use the available filters, including **API Events Only**, to scope a review or investigation
2. Export to CSV — note the export is **capped at 1,000 rows**, so scope filters tightly rather than attempting a single bulk pull

**Step 3: Beat the Retention Window**
1. Schedule a recurring export well inside the **180-day** retention period so no window is lost
2. Store exports in your own log platform or evidence repository with longer retention

**Step 4: Alert on High-Signal Events**
1. Alert on admin-toggle grants ([2.1](#21-configure-admin-access-and-security-roles))
2. Alert on changes to SAML settings — particularly anything that re-enables non-SAML logins or SAML-based account creation
3. Alert on Security Role and group-assignment changes

> **Known logging gaps.** The KSAT Audit Log does not track password changes or API key changes. Cover API and provisioning-token rotation ([3.2](#32-secure-api-and-provisioning-tokens)) in your own change-management record — absence of an entry here is not evidence that no change occurred.

#### Validation & Testing
- Make a benign, reversible admin change and confirm it appears in the Audit Log with the expected actor and timestamp.
- Confirm the scheduled export has produced a continuous series with no gap approaching 180 days.

**Source:** [KnowBe4 Audit Log Overview](https://support.knowbe4.com/hc/en-us/articles/23542330166163-KnowBe4-Audit-Log-Overview)

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | KnowBe4 Control | Guide Section |
|-----------|-----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on), [1.2](#12-enforce-multi-factor-authentication) |
| CC6.2 | Admin access and Security Roles | [2.1](#21-configure-admin-access-and-security-roles) |
| CC6.3 | API and provisioning credentials | [3.2](#32-secure-api-and-provisioning-tokens) |
| CC7.2 | Audit logging | [4.1](#41-review-and-export-the-ksat-audit-log) |

### NIST 800-53 Rev 5 Mapping

| Control | KnowBe4 Control | Guide Section |
|---------|-----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.2](#12-enforce-multi-factor-authentication) |
| IA-5 | Token management | [3.2](#32-secure-api-and-provisioning-tokens) |
| AC-6 | Admin access and Security Roles | [2.1](#21-configure-admin-access-and-security-roles) |
| AT-2 | Training | [3.1](#31-configure-phishing-campaign-security) |
| AU-2 | Audit logging | [4.1](#41-review-and-export-the-ksat-audit-log) |
| AU-11 | Audit record retention | [4.1](#41-review-and-export-the-ksat-audit-log) |

---

## Appendix B: References

**Official KnowBe4 Documentation (KSAT console):**
- [Knowledge Base](https://support.knowbe4.com/hc/en-us)
- [Set Up SAML SSO for the Security Awareness Training Console](https://support.knowbe4.com/hc/en-us/articles/360041935913-Set-Up-SAML-Single-Sign-on-SSO-for-the-Security-Awareness-Training-Console)
- [KnowBe4 Console Account Settings: Account Integrations](https://support.knowbe4.com/hc/en-us/articles/12769050560403-KnowBe4-Console-Account-Settings-Account-Integrations)
- [KnowBe4 Console Account Settings: User Management](https://support.knowbe4.com/hc/en-us/articles/12731036715411-KnowBe4-Console-Account-Settings-User-Management)
- [Assign and Remove Admin Functions from a User](https://support.knowbe4.com/hc/en-us/articles/205015187-Assign-and-Remove-Admin-Functions-from-a-User)
- [Security Roles Guide](https://support.knowbe4.com/hc/en-us/articles/115015389767-Security-Roles-Guide)
- [Enable Two-Factor or Multi-Factor Authentication on Your Account](https://support.knowbe4.com/hc/en-us/articles/225681448-Enable-Two-Factor-or-Multi-Factor-Authentication-on-Your-Account)
- [KnowBe4 Audit Log Overview](https://support.knowbe4.com/hc/en-us/articles/23542330166163-KnowBe4-Audit-Log-Overview)
- [SAML Integration Overview](https://support.knowbe4.com/hc/en-us/articles/206293387-SAML-Integration-Overview)
- [SCIM Configuration Guide](https://support.knowbe4.com/hc/en-us/articles/360052380374-SCIM-Configuration-Guide)

**Out-of-Scope Products (Egress-derived — separate hardening surfaces):**
- [Understanding System Roles and Permissions](https://support.knowbe4.com/hc/en-us/articles/48662967223955-Understanding-System-Roles-and-Permissions)
- [Configure Multi-Factor Authentication (MFA) for Workspace](https://support.knowbe4.com/hc/en-us/articles/48663011928211-Configure-Multi-Factor-Authentication-MFA-for-Workspace)

**API Documentation:**
- [KnowBe4 Developer Portal](https://developer.knowbe4.com/)
- [Reporting API Overview](https://support.knowbe4.com/hc/en-us/articles/115016090908-Reporting-API-Overview)

**Compliance Frameworks:**
- [FedRAMP Moderate Authorization Announcement](https://www.knowbe4.com/press/knowbe4-is-now-fedramp-federal-risk-and-authorization-management-program-moderate-authorized)

**Security Incidents:**
- [How a North Korean Fake IT Worker Tried to Infiltrate Us (July 2024)](https://blog.knowbe4.com/how-a-north-korean-fake-it-worker-tried-to-infiltrate-us)
- [North Korean Fake IT Worker FAQ](https://blog.knowbe4.com/north-korean-fake-it-worker-faq)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: scope guide explicitly to the KSAT console (Egress-derived products noted out of scope); correct 1.1 (SAML needs no Platinum/Diamond tier; add real Account Integrations settings and the public bypass-URL warning), 1.2 (account-wide and per-user MFA paths, TOTP-only — no native FIDO2), 2.1 (admin is an all-or-nothing per-user toggle; least privilege comes from group-assigned Security Roles, tier-gated), and 3.2 (API now under Account Integrations; add ADI Sync and SCIM token rotation). Add section 4 Monitoring & Auditing with 4.1 KSAT Audit Log (180-day retention, 1,000-row CSV cap, no password/API-key coverage). Purge Trust Center and marketing security page from references. Tier 3/4 research sweep out of scope for this pass (search budget) | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and campaign security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
