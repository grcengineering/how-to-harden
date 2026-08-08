---
layout: guide
title: "Gong Hardening Guide"
vendor: "Gong"
slug: "gong"
tier: "2"
category: "Productivity"
description: "Revenue intelligence platform hardening for Gong including SAML SSO, data access controls, and recording security"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Gong is a revenue intelligence platform providing conversation analytics and sales insights. As a platform recording and analyzing business communications, Gong security configurations directly impact data privacy and conversation confidentiality.

### Intended Audience
- Security engineers managing sales tools
- IT administrators configuring Gong
- Sales operations managers
- GRC professionals assessing communication security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Gong security including SAML SSO, user permissions, data access controls, and recording policies.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Security](#3-data-security)
4. [Monitoring & Audit](#4-monitoring--audit)
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
Configure SAML SSO for Gong access.

#### Rationale
**Why This Matters:**
- Centralizes Gong authentication in your corporate IdP so MFA, conditional access, and session policies apply to every login
- Local Gong passwords bypass IdP controls and become standalone credentials attackers can phish or stuff
- Centralized SSO lets you instantly revoke access for departed employees, preventing lingering access to recorded sales conversations
- Gong holds recorded calls, deal data, and customer PII, so a single compromised login can expose the entire revenue conversation archive

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Prerequisites
- Gong admin access
- Enterprise plan
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access Sign-In Settings**
1. Navigate to: **Admin center** → **Settings** → **Authentication** (under **Company**)
2. Select the sign-in method and enable SAML authentication

**Step 2: Configure SAML**
1. Configure IdP settings:
   - Entity ID
   - SSO URL
   - Certificate
2. Configure Gong in IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback

**Time to Complete:** ~1-2 hours

#### Validation & Testing
- Attempt an email-and-password sign-in after enforcement and confirm it is refused
- Confirm the session behavior matches expectations for your chosen method (see 1.3) — the session lifetime attached to each sign-in method is itself a security property

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Gong users.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks attackers who have already obtained a valid Gong password
- Sales and revenue teams are frequent phishing targets because their accounts expose customer and deal intelligence
- Phishing-resistant MFA for admins protects the accounts that can change org-wide security and access settings
- Without MFA, a single leaked or reused credential gives direct access to confidential call recordings

**Attack Prevented:** Credential stuffing, phishing, account takeover, password reuse

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

---

### 1.3 Understand and Constrain Session Lifetimes by Sign-In Method

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-11, AC-12 |

#### Description
Choose the sign-in method deliberately, because Gong's session lifetime is a property of the authentication method: email-and-password sessions last two weeks, common IdP sessions follow the IdP's own policy, and SAML SSO defaults to a 30-minute inactivity timeout.

#### Rationale
**Why This Matters:**
- A Gong **email-and-password session lasts two weeks**. That single fact is the strongest argument for enforcing SSO (1.1): every local-password user carries a fortnight-long credential on their device, and revoking the account does not shorten a session already in flight
- **SAML SSO defaults to a 30-minute inactivity timeout** and is customizable, which is roughly two orders of magnitude tighter than the local-password path for the same product
- Sessions established through common identity providers inherit that IdP's policy, documented by Gong as ranging from **10 hours to 90 days** — so an IdP with a lax session policy silently undoes a tight Gong configuration
- Gong sessions reach recorded customer calls, deal intelligence, and PII; the window in which a stolen laptop or hijacked session remains useful is a direct measure of exposure

**Attack Prevented:** Session hijacking, stolen-device access, token replay, delayed effect of account revocation

#### ClickOps Implementation

**Step 1: Choose the Sign-In Method for Session Reasons**
1. Navigate to: **Admin center** → **Settings** → **Authentication** (under **Company**)
2. Prefer **SAML SSO**, whose 30-minute inactivity default is the tightest of the available paths
3. Eliminate email-and-password sign-in wherever possible rather than accepting a two-week session

**Step 2: Tune the SSO Timeout**
1. Adjust the SAML SSO inactivity timeout from its 30-minute default only with a documented reason — lengthening it is a risk decision, not a convenience setting

**Step 3: Audit the IdP Side**
1. Where users sign in through a common identity provider, review that provider's session policy directly — Gong inherits it, so a 90-day IdP session is a 90-day Gong session
2. Align the IdP session policy with the exposure you accepted when you set the Gong timeout

#### Validation & Testing
- Leave a session idle past the configured interval and confirm re-authentication is required
- Enumerate any remaining email-and-password accounts and treat each as a two-week standing session in your risk register
- Re-check after IdP policy changes, which can move Gong's effective session lifetime without any change in Gong

---

### 1.4 Enforce Password Policy and Lockout for Non-SSO Accounts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2, 6.2 |
| NIST 800-53 | IA-5, AC-7 |

#### Description
Know and validate the password and lockout behavior Gong applies to accounts that authenticate locally, and treat those accounts as the residual population to be eliminated.

#### Rationale
**Why This Matters:**
- Any account not covered by SSO falls back on Gong's local password rules: **minimum 8 characters, at least one number and one special character, no fragment of the username, and no reuse of the last four passwords**
- Gong locks an account for **60 minutes after 5 failed sign-in attempts**, which blunts online brute force but does nothing against credential stuffing with a valid leaked password
- These rules are Gong's floor, not your policy — an 8-character minimum is well below what most organizations require, and Gong offers no way to raise it, so the mitigation is to remove local accounts rather than to tune them
- Combined with the two-week local session lifetime (1.3), every surviving password account is a durable, weakly-constrained path into the recording archive

**Attack Prevented:** Password brute force, credential stuffing, password reuse, weak-credential account takeover

#### ClickOps Implementation

**Step 1: Inventory Non-SSO Accounts**
1. Navigate to: **Admin center** → **Settings** → **Authentication** (under **Company**)
2. Identify every account still able to authenticate with a local password, including service and integration users

**Step 2: Migrate or Justify**
1. Move each account to SSO
2. For any account that genuinely cannot move, document the exception, the compensating controls, and a review date — the local password rules cannot be strengthened to compensate

**Step 3: Monitor Lockouts**
1. Treat repeated 60-minute lockouts as a detection signal, not just a helpdesk event — a lockout pattern across multiple accounts is a credential-stuffing indicator
2. Correlate with the access logs from 4.1

#### Validation & Testing
- Confirm the non-SSO account list is empty, or that every entry has a documented, current exception
- Verify lockout events are visible to whoever monitors them; a lockout nobody sees is not a control

---

### 1.5 Automate Provisioning with SCIM

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3, 6.1 |
| NIST 800-53 | AC-2 |

#### Description
Provision and deprovision Gong users automatically from the identity provider so that access grants and revocations follow the authoritative directory rather than a manual admin step.

#### Rationale
**Why This Matters:**
- 1.1's rationale claims SSO lets you "instantly revoke access for departed employees" — that claim only holds if account lifecycle is actually wired to the IdP. Without provisioning, disabling the IdP account blocks new logins while the Gong user record, its permissions, and any in-flight session persist
- Automated deprovisioning is the control that closes the gap between an employee leaving and their access to recorded customer conversations ending
- Attribute-driven provisioning keeps permission profiles (2.1) aligned with directory groups, preventing the privilege drift that manual role assignment produces over time
- Gong documents provisioning integrations for **Okta, Microsoft Entra ID, OneLogin, Rippling, and Salesforce**, plus a **custom SCIM** path for other directories

**Attack Prevented:** Orphaned-account access, offboarding gaps, privilege creep, unauthorized standing access to call recordings

#### Prerequisites
- Gong admin access
- A supported identity provider (Okta, Microsoft Entra ID, OneLogin, Rippling, Salesforce) or a SCIM-capable directory for the custom path

#### ClickOps Implementation

**Step 1: Connect the Directory**
1. Navigate to: **Admin center** → **Settings** → **People**
2. Configure provisioning against your identity provider, or the custom SCIM connector where your directory is not on the supported list

**Step 2: Map Groups to Permission Profiles**
1. Map directory groups to Gong permission profiles (2.1) so role assignment is directory-driven
2. Confirm the mapping produces least privilege by default, not the most permissive profile

**Step 3: Test the Full Lifecycle**
1. Create, modify, and disable a test user in the IdP and confirm each change propagates to Gong
2. Pair deprovisioning with the session facts in 1.3 — a revoked user may still hold a live session, so verify the session outcome rather than assuming it

#### Validation & Testing
- Disable a test IdP account and confirm the corresponding Gong user is deactivated, not merely blocked from new logins
- Reconcile the Gong user list against the directory periodically; a drift count above zero means provisioning is not authoritative

---

## 2. Access Controls

### 2.1 Configure User Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Assign Gong's permission profiles on a least-privilege basis, starting from the built-in profiles rather than inventing an ad-hoc role model.

#### Rationale
**Why This Matters:**
- Least-privilege profiles ensure users only see the calls and data needed for their job, limiting exposure of sensitive conversations
- Over-permissioned accounts expand the blast radius when any single account is compromised
- Visibility and team boundaries keep one team's confidential deal discussions from leaking to unrelated users
- Right-sized profiles reduce the chance of accidental or malicious bulk export of recorded conversations

**Attack Prevented:** Privilege escalation, lateral data access, insider misuse, oversharing of confidential calls

#### ClickOps Implementation

**Step 1: Review Permission Profiles**
1. Navigate to: **Admin center** → **Settings** → **People** → **Permission profiles**
2. Review the built-in profiles:
   - **Business admin**
   - **Standard team member**
   - **Collaborator**
   - Forecast variants of the above, where Forecast is licensed
   - **Technical administrator**, which Gong's security documentation also names
3. Assign the minimum necessary profile; create custom profiles only where a built-in one genuinely does not fit

**Step 2: Configure Visibility**
1. Set visibility permissions
2. Control who sees which calls
3. Apply team boundaries

#### Validation & Testing
- Export the profile assignment list and confirm every **Business admin** and **Technical administrator** is intentional (see 2.3)
- Spot-check a **Collaborator** account and confirm it cannot reach recordings outside its intended scope

---

### 2.2 Configure Recording Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control access to call recordings.

#### Rationale
**Why This Matters:**
- Call recordings often capture pricing, negotiation strategy, customer PII, and other material that should not be broadly visible
- Default-restrictive visibility prevents every user from browsing the entire recording library
- Marking and restricting sensitive calls protects high-risk conversations such as executive, legal, or HR discussions
- Auditing access patterns surfaces unusual viewing that may indicate insider snooping or a compromised account

**Attack Prevented:** Unauthorized data access, insider snooping, confidential-data leakage, regulatory exposure

#### ClickOps Implementation

**Step 1: Configure Access Rules**
1. Set default visibility
2. Configure manager access
3. Limit cross-team visibility

**Step 2: Configure Sensitive Calls**
1. Mark sensitive recordings
2. Restrict access appropriately
3. Audit access patterns

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect the accounts holding administrative permission profiles.

#### Rationale
**Why This Matters:**
- Administrative profiles — **Business admin** and **Technical administrator** (see 2.1) — can change security settings, access all recordings, and manage every user, making them the highest-value target
- Reducing the number of admins shrinks the attack surface and the set of credentials that must be tightly protected
- Requiring MFA and monitoring admin activity detects and slows takeover of these privileged accounts
- A compromised admin can disable controls, export data, or grant attacker access org-wide

**Attack Prevented:** Privilege escalation, admin account takeover, unauthorized configuration changes, mass data exfiltration

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Navigate to: **Admin center** → **Settings** → **People** → **Permission profiles**
2. List every account holding **Business admin** or **Technical administrator**
3. Document admin access and its business justification

**Step 2: Apply Restrictions**
1. Limit administrative profiles to required personnel
2. Require MFA (1.2) and ensure every admin authenticates through SSO, not a local password (1.3, 1.4)
3. Monitor admin activity through the audit logs API (4.1)

#### Validation & Testing
- Re-run the profile inventory on a fixed cadence and diff it against the previous run; unexplained additions are the signal
- Confirm no administrative account remains on email-and-password sign-in

---

## 3. Data Security

### 3.1 Configure Data Retention

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SI-12 |

#### Description
Set an explicit retention period for recorded conversations, and make sure the policy actually reaches calls stored in the library.

#### Rationale
**Why This Matters:**
- Gong's **default retention is the lesser of three years and the length of your tenure as a customer** — a default, not a decision, and three years of recorded customer conversations is a substantial standing liability
- **Library exemption trap:** calls saved to the library are excluded from the retention policy unless **Apply retention policy to calls stored in library** is enabled. Left off, the calls teams deliberately kept — usually the most sensitive and most-referenced ones — are never auto-deleted, and the organization believes it has a retention policy that it does not
- Automatic deletion enforces consistent disposal and removes reliance on manual cleanup
- Defined retention periods support privacy regulations and contractual obligations governing customer conversation data

**Attack Prevented:** Excessive data exposure, compliance violations, data-hoarding liability, breach blast-radius growth

#### ClickOps Implementation

**Step 1: Configure Retention**
1. Navigate to: **Admin center** → **Settings** → **Data protection & privacy**
2. Replace the default with a retention period you have chosen and can justify
3. Configure automatic deletion

**Step 2: Close the Library Exemption**
1. Enable **Apply retention policy to calls stored in library**
2. Without this, library calls are retained indefinitely regardless of the period set in Step 1

**Step 3: Account for Workspace Differences**
1. Where workspaces are in use (3.4), confirm the retention period configured for each — retention is set per workspace, so a policy applied in one does not cover the others

#### Validation & Testing
- Confirm the library toggle is on; this is the single most commonly missed setting in this control
- Verify calls older than the retention period are actually gone, including at least one library call
- Re-check retention in every workspace after any workspace is added

---

### 3.2 Configure Integration Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure third-party integrations.

#### Rationale
**Why This Matters:**
- Connected apps and API tokens can read Gong data, so each integration is a potential path to your recorded conversations
- Removing unnecessary integrations reduces the number of third parties that can be compromised to reach your data
- Least-privilege scopes ensure a breached integration cannot access more than the minimum it needs
- Monitoring integration activity detects abnormal data access from a compromised or rogue connected app

**Attack Prevented:** Supply-chain compromise, token abuse, third-party data exfiltration, OAuth scope abuse

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to the integrations area of the **Admin center**. This guide's other console paths were re-verified in the 2026-08 pass; the exact path for this page was not, and earlier revisions cited **Company Settings** → **Integrations** — confirm the current location in your own tenant
2. Review connected apps
3. Remove unnecessary integrations

**Step 2: Apply Least Privilege**
1. Grant minimum permissions
2. Monitor integration activity through the audit logs API (4.1)

**Step 3: Cover API Credentials Separately**
1. API keys and OAuth applications are managed elsewhere and have their own lifecycle — see 3.3

---

### 3.3 Manage API Credentials

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11, 5.4 |
| NIST 800-53 | IA-5, SC-12 |

#### Description
Issue and track Gong API credentials deliberately, and compensate in process for the revocation path Gong does not document.

#### Rationale
**Why This Matters:**
- Gong's **Get API Key** action issues an access key and secret used as HTTP basic authentication — a long-lived credential that reads conversation data outside the UI and outside the permission profiles that govern human users
- Gong documents credential **renewal notifications** but **no revocation procedure**. The absence is the finding: plan on the assumption that you cannot cleanly retire a leaked key on demand, which makes issuance discipline and secret storage the operative controls rather than incident response
- OAuth applications are a separate mechanism (Gong Collective) with a different lifecycle — conflating the two leads to inventories that miss half the access paths
- A leaked API key reaches the recording archive at machine speed, so the difference between a scoped, inventoried credential and an untracked one is the difference between a contained incident and a full-archive exposure

**Attack Prevented:** API key theft, undetected third-party data access, over-broad integration credentials, supply-chain compromise

#### ClickOps Implementation

**Step 1: Issue Credentials Deliberately**
1. Navigate to: **Admin center** → **Settings** → **Ecosystem** → **API**
2. Use **Get API Key** to generate the access key and secret only for an integration you have approved and recorded
3. Store the secret in a managed secret store; it authenticates as HTTP basic auth and is as sensitive as any password

**Step 2: Separate OAuth Applications**
1. Track Gong Collective OAuth applications as a distinct inventory from API keys
2. Review both when auditing what can read your data

**Step 3: Compensate for the Missing Revocation Path**
1. Record every key's owner, purpose, and issue date
2. Act on renewal notifications rather than letting them lapse silently
3. Document, in your risk register, that a documented on-demand revocation procedure does not exist — and escalate to Gong support if a key must be invalidated urgently

#### Validation & Testing
- Reconcile issued API keys and OAuth applications against the approved integration inventory
- Confirm no key or secret appears in source control, CI logs, or shared documents
- Confirm someone owns the renewal notifications; an unactioned notification is how credentials outlive their integrations

---

### 3.4 Configure Data Protection and Privacy Settings

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.3 |
| NIST 800-53 | SC-28, SI-12, MP-6 |

#### Description
Use Gong's data protection controls — exclusion lists, redaction, workspace segmentation, customer-managed keys, consent profiles, and DSAR deletion — to limit what enters the platform and how it is protected once there.

#### Rationale
**Why This Matters:**
- **Exclusion lists are the strongest control in this section** because they keep sensitive meetings out of Gong entirely. Gong supports exclusion by domain, email address, prefix, meeting title, and subject phrase — so board, legal, HR, and M&A conversations can be prevented from ever being recorded, which no downstream access control can match
- **Numeric and PHI redaction** removes sensitive values from transcripts, reducing what a compromised account or over-broad export can yield. Note the documented limit: redaction applies to **English-language calls only**, so multilingual organizations retain unredacted content and should lean harder on exclusion lists
- **Workspace segmentation** separates data by business unit and carries its own retention period per workspace, which is what makes differentiated retention (3.1) possible for regions or subsidiaries with different obligations
- **Customer-managed keys (BYOK)** put key custody on your side of the boundary; **consent profiles** govern recording notification; and **DSAR deletion** satisfies subject-rights requests — the last being **irreversible**, which makes it a control to exercise carefully and with approval, not a routine cleanup tool

**Attack Prevented:** Over-collection of sensitive conversations, transcript exposure of PII/PHI, cross-business-unit data access, key-custody gaps, privacy and consent violations

#### ClickOps Implementation

**Step 1: Build Exclusion Lists First**
1. Navigate to: **Admin center** → **Settings** → **Data protection & privacy**
2. Add exclusions by domain, email address, prefix, meeting title, and subject phrase for conversation categories that should never be captured
3. Treat this as the primary control — the cheapest data to protect is the data you never collected

**Step 2: Enable Redaction**
1. Enable numeric and PHI redaction
2. Record the English-only limitation as a known gap where your organization runs non-English calls, and cover those with exclusions instead

**Step 3: Segment and Protect**
1. Configure workspaces where business units require separation, and set retention per workspace (3.1)
2. Configure customer-managed keys (BYOK) where key custody is required
3. Configure consent profiles to match the recording-notification obligations of each jurisdiction you operate in

**Step 4: Handle DSAR Deletion Carefully**
1. Use DSAR deletion for subject-rights requests
2. Require approval before execution — deletion is **irreversible** and there is no undo

#### Validation & Testing
- Schedule a test meeting matching an exclusion rule and confirm it is not recorded
- Review a redacted transcript and confirm numeric and PHI values are removed; repeat on a non-English call to confirm the gap for yourself
- Confirm each workspace's retention period matches its intended policy

---

## 4. Monitoring & Audit

### 4.1 Export Audit Logs via the API

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.5, 8.9 |
| NIST 800-53 | AU-2, AU-6, AU-11 |

#### Description
Pull Gong's audit log types through the `/v2/logs` API on a schedule and retain them externally, because the access log is retained for only 14 days inside Gong.

#### Rationale
**Why This Matters:**
- **Gong retains the `AccessLog` type for only 14 days.** Any investigation that starts more than two weeks after the fact has no data to work with, so scheduled export to your own retention is a hard requirement rather than a maturity nicety — this is the control, not the reporting on it
- The `ExternallySharedCallAccess` and `ExternallySharedCallPlay` types are the specific signals that 2.2's rationale cares about: they show recordings being reached and played outside the organization, which is what insider exfiltration of call content actually looks like in the logs
- `UserActivityLog` and `UserCallPlay` provide the per-user behavioral baseline needed to distinguish a manager reviewing their team's calls from an account systematically working through the archive
- Without external retention and correlation, admin changes (2.3), integration access (3.2, 3.3), and export activity are individually visible but never assembled into a picture

**Attack Prevented:** Undetected breach, insider data theft, evidence loss through log expiry, unattributable external sharing of recordings

#### Prerequisites
- Gong API credentials (see 3.3)
- The `api:logs:read` scope
- A destination with retention appropriate to your investigation window — the SIEM or log store, not Gong

#### ClickOps Implementation

**Step 1: Provision API Access**
1. Navigate to: **Admin center** → **Settings** → **Ecosystem** → **API**
2. Issue credentials for a dedicated logging integration, recorded in the inventory from 3.3
3. Ensure the credential carries the `api:logs:read` scope

**Step 2: Schedule Retrieval by Log Type**
1. Call `GET /v2/logs` with a log type and time range, iterating over the types you need:
   - `AccessLog`
   - `UserActivityLog`
   - `UserCallPlay`
   - `ExternallySharedCallAccess`
   - `ExternallySharedCallPlay`
2. Schedule the job to run well inside the **14-day** `AccessLog` window — a weekly cadence leaves no margin for a failed run, so run it daily and alert on failure

**Step 3: Alert on the Exfiltration Signals**
1. Build detections on `ExternallySharedCallAccess` and `ExternallySharedCallPlay` for volume anomalies and for access to calls flagged sensitive (2.2)
2. Correlate `UserCallPlay` volume against role — a **Collaborator** working through hundreds of recordings is not normal behavior

#### Validation & Testing
- Confirm each scheduled export completed by checking record counts, not just job exit status; a successful call returning zero rows is the failure mode to catch
- Deliberately test the 14-day boundary once: request `AccessLog` data older than 14 days and confirm it is unavailable, so the team understands the constraint is real
- Verify a test external share appears in `ExternallySharedCallAccess` end to end, from Gong through to your SIEM

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Gong Control | Guide Section |
|-----------|--------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User permissions | [2.1](#21-configure-user-permissions) |
| CC6.3 | SCIM provisioning | [1.5](#15-automate-provisioning-with-scim) |
| CC6.7 | Data retention | [3.1](#31-configure-data-retention) |
| CC7.2 | Audit log export | [4.1](#41-export-audit-logs-via-the-api) |

### NIST 800-53 Rev 5 Mapping

| Control | Gong Control | Guide Section |
|---------|--------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-2 | SCIM provisioning | [1.5](#15-automate-provisioning-with-scim) |
| AC-3 | Recording access | [2.2](#22-configure-recording-access) |
| AC-6 | User permissions | [2.1](#21-configure-user-permissions) |
| AC-12 | Session lifetimes | [1.3](#13-understand-and-constrain-session-lifetimes-by-sign-in-method) |
| AU-2 | Audit log export | [4.1](#41-export-audit-logs-via-the-api) |
| SC-28 | Data protection settings | [3.4](#34-configure-data-protection-and-privacy-settings) |

---

## Appendix A: References

**Official Gong Documentation:**
- [Help Center](https://help.gong.io/)
- [Summary of Security Features](https://help.gong.io/docs/summary-of-security-features)
- [Set Sign-In Method](https://help.gong.io/docs/set-sign-in-method)
- [About Permission Profiles](https://help.gong.io/docs/about-permission-profiles)
- [Data Retention Policy](https://help.gong.io/docs/data-retention-policy)
- [Security and Compliance](https://help.gong.io/docs/security-compliance)
- [Receive Access to the API](https://help.gong.io/docs/receive-access-to-the-api)
- [Security, Privacy and Compliance FAQ](https://help.gong.io/docs/faqs-for-security-privacy-and-compliance)

**API & Developer Tools:**
- [Gong API Documentation (public)](https://help.gong.io/apidocs/)
- [Retrieve Logs Data by Type and Time Range (`GET /v2/logs`)](https://help.gong.io/apidocs/retrieve-logs-data-by-type-and-time-range-v2logs)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 27017, ISO 27018, ISO 27701, ISO/IEC 42001:2023, PCI DSS (SAQ D), CSA STAR

**Security Incidents:**
- No major public security incidents identified as of February 2026.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against Tier 1 Gong Help Center, which publishes an `llms.txt` index and serves clean markdown at `/docs/{slug}.md` — the documentation is fully reachable, correcting this guide's earlier assumption that it was partially gated. Corrected console paths throughout to the **Admin center** structure (authentication, permission profiles, data protection & privacy) and replaced the invented Admin/Manager/Team member role model in 2.1 with Gong's actual built-in permission profiles (Business admin, Standard team member, Collaborator, Forecast variants, Technical administrator). Corrected 3.1 with the real default (lesser of three years and customer tenure) and the library exemption trap. New controls: 1.3 session lifetimes by sign-in method (email/password sessions last two weeks — the argument for SSO), 1.4 password policy and lockout, 1.5 SCIM provisioning, 3.3 API credential management (including the undocumented revocation path), 3.4 data protection settings (exclusion lists, redaction, workspaces, BYOK, consent, DSAR). Added new section 4 Monitoring & Audit with the `/v2/logs` audit API and its 14-day `AccessLog` retention limit; the compliance reference section moved from 4 to 5. Pruned Trust Center and marketing security pages from References and replaced the tenant-authenticated API doc link with the public one. Note for future passes: Gong's "IP allow list" page documents Gong's **egress** IPs for customer firewall rules — it is not an inbound access restriction, and no inbound IP-restriction control was added on its basis. Tier 2 (CIS/DISA/CISA) and Tier 3/4 expert sources not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
