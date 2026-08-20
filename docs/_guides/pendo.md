---
layout: guide
title: "Pendo Hardening Guide"
vendor: "Pendo"
slug: "pendo"
tier: "3"
category: "Data"
description: "Product experience platform hardening for Pendo including SAML SSO, subscription access, and data privacy controls"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Pendo is a product experience platform providing analytics, in-app guidance, and feedback tools. As a platform collecting user behavior data and enabling in-app messaging, Pendo security configurations directly impact data privacy and application security.

### Intended Audience
- Security engineers managing product experience platforms
- IT administrators configuring Pendo
- Product teams managing analytics and guidance
- GRC professionals assessing data security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Pendo security including SAML SSO, subscription access, API security, and data privacy controls.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Security](#3-data-security)
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
Configure SAML SSO to centralize authentication for Pendo users.

#### Rationale
**Why This Matters:**
- Centralizes Pendo authentication in your corporate IdP so MFA, conditional access, and session policies apply to every login
- Local Pendo passwords bypass IdP controls and are prime targets for credential stuffing and phishing
- Centralized provisioning and deprovisioning removes departed users automatically, eliminating orphaned accounts with access to product analytics
- Pendo holds detailed user behavior data and controls in-app messaging that reaches your end users, so a single compromised login has broad reach

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Prerequisites
- Pendo admin access
- Enterprise plan
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Subscription Settings** → **Single Sign-On**
2. Enable SAML SSO

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Download Pendo metadata for IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback

**Time to Complete:** ~1-2 hours

#### References
- [SAML SSO overview](https://support.pendo.io/hc/en-us/articles/360032953392) (content verified via the vendor's help-center API, 2026-08)
- [Set up SAML SSO](https://support.pendo.io/hc/en-us/articles/29586397277595) (content verified via the vendor's help-center API, 2026-08)
- [SAML metadata and certificates](https://support.pendo.io/hc/en-us/articles/360042521712) (content verified via the vendor's help-center API, 2026-08)

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Pendo users.

#### Rationale
**Why This Matters:**
- A second factor blocks account takeover even when a password is stolen, guessed, or phished
- Admin accounts can edit in-app guides, export analytics, and manage integration keys, so a single takeover carries outsized impact
- Phishing-resistant methods such as FIDO2/WebAuthn defeat real-time relay and push-fatigue attacks against high-value admins

**Attack Prevented:** Credential stuffing, phishing, password reuse, MFA push fatigue

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

---

### 1.3 Set Up SCIM Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.3 |
| NIST 800-53 | AC-2, AC-2(4) |

#### Description
Configure SCIM provisioning between your identity provider and Pendo so user accounts and role assignments are created, updated, and deactivated automatically rather than by hand.

#### Rationale
**Why This Matters:**
- SSO authenticates users but does not remove them — the automatic deprovisioning that [1.1](#11-configure-saml-single-sign-on) relies on is delivered by SCIM, not by SSO
- Without SCIM, a departed employee's Pendo account persists until someone remembers to remove it, retaining access to product analytics and, for admins, the ability to publish in-app guides to your end users
- Provisioning from the IdP keeps role assignment consistent with team membership, closing the gap where manually created accounts accumulate privileges nobody reviews

**Attack Prevented:** Orphaned-account access after offboarding, standing access for departed staff, manual provisioning errors, privilege drift

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Settings** → **Users and teams**
2. Enable SCIM provisioning and generate the SCIM token for your identity provider
3. Configure the Pendo application in your IdP with the SCIM endpoint and token

**Step 2: Scope and Map**
1. Push only the groups that need Pendo access
2. Map each group to the least-privilege role set from [2.1](#21-configure-user-roles)

**Step 3: Verify Deprovisioning**
1. Disable a test user in the IdP and confirm the Pendo account is deactivated
2. Treat the SCIM token as a high-value credential — it can manage your entire Pendo user population

#### References
- [Set up SCIM in Pendo](https://support.pendo.io/hc/en-us/articles/4412768395803) (content verified via the vendor's help-center API, 2026-08)

---

## 2. Access Controls

### 2.1 Configure User Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Pendo's actual role model: one subscription-level administrator role, a set of app-level roles scoped per application, and granular subscription-level permissions granted independently of those roles.

#### Rationale
**Why This Matters:**
- Least-privilege role assignment limits what a compromised or careless account can see and change
- Pendo's roles are app-scoped rather than global, so a user can legitimately hold Guide Publisher on a sandbox app and nothing at all on production — a flat "Admin / User / Read-only" mental model hides that distinction and over-grants by default
- Guide Publisher and Resource Center Publisher push content to your live end users, which makes them a content-integrity control, not just an analytics permission
- Granular subscription-level permissions (segment editing, product areas, Data Sync, event properties) are granted independently of app roles, so a user with a modest app role can still hold broad subscription-level reach if those boxes were ticked without review
- Restricting Subscription Admin to a few users shrinks the attack surface for privilege abuse and accidental misconfiguration

**Attack Prevented:** Privilege escalation, insider misuse, unauthorized in-app content publication to end users, accidental data exposure, lateral movement between apps

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Users and teams**
2. Review each user's **subscription-level** role — Subscription Admin is the only one, and it carries full control of the subscription
3. Review each user's **app-level** roles, which are assigned per application:
   - App Admin
   - Guide Creator
   - Guide Content Editor
   - Guide Publisher
   - Tagging Editor
   - Resource Center Author
   - Resource Center Publisher
   - Replay User
   - AI Agent Admin
4. Assign the minimum necessary role, and assign it only on the apps where the user actually works

**Step 2: Review Granular Subscription Permissions**
1. In the same screen, review the subscription-level permissions granted independently of app roles:
   - Share/edit segments
   - Manage product areas
   - Configure Data Sync
   - Manage event properties
2. Grant each one deliberately — these do not follow from an app role and are easy to leave switched on after a one-off task

**Step 3: Apply Least Privilege**
1. Separate viewing from publishing: analysts should not hold Guide Publisher or Resource Center Publisher
2. Limit Subscription Admin to the smallest workable number of people
3. Run regular access reviews covering both app roles and the granular subscription permissions

> **There is no built-in "Read-only" role.** Earlier revisions of this guide described an Admin / User / Read-only model that does not exist in Pendo. Read-only-style access is achieved by assigning no publishing or editing roles on an app. If you need role definitions beyond the built-in set, Pendo offers **Custom Roles** as a paid add-on. ([Roles and permissions](https://support.pendo.io/hc/en-us/articles/360058639932-Roles-and-permissions), content verified via the vendor's help-center API, 2026-08)

---

### 2.2 Configure Subscription Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to different subscriptions/apps.

#### Rationale
**Why This Matters:**
- Separating production and development subscriptions prevents test users from touching live customer analytics and guides
- Scoping access per subscription contains the blast radius if one set of credentials is compromised
- Segmentation enforces need-to-know boundaries between teams that manage different applications

**Attack Prevented:** Cross-environment data exposure, lateral movement, unauthorized access to production data

#### ClickOps Implementation

**Step 1: Configure Access**
1. Separate production and development apps
2. Limit access per subscription
3. Apply role restrictions

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect Pendo's two tiers of administrator: the subscription-wide Subscription Admin, and the per-application App Admin.

#### Rationale
**Why This Matters:**
- Subscription Admins can modify in-app guides, export behavior data, and create integration keys that reach every app and environment in the subscription, making them the highest-value targets in Pendo
- App Admin is a genuinely narrower role — scoped to one application — so treating every administrator as equivalent both over-restricts app owners and under-scrutinises subscription-wide access
- Keeping the Subscription Admin count small and requiring SSO reduces the number of credentials an attacker can target
- Reviewing admin assignments surfaces unauthorized changes and supports incident investigation and audit

**Attack Prevented:** Admin account takeover, privilege abuse, unauthorized configuration changes, subscription-wide blast radius from a single compromised account

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Navigate to: **Settings** → **Users and teams**
2. List every **Subscription Admin** separately from every per-app **App Admin** — they are not the same level of access
3. Document the business reason for each, and identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit Subscription Admins to the smallest workable number of people
2. Prefer App Admin scoped to a single application wherever subscription-wide access is not genuinely required
3. Require SSO for all administrators
4. Re-review admin assignments on a fixed cadence

#### References
- [Roles and permissions](https://support.pendo.io/hc/en-us/articles/360058639932-Roles-and-permissions) (content verified via the vendor's help-center API, 2026-08)

---

## 3. Data Security

### 3.1 Configure Integration Key Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Take custody of a Pendo integration key at the moment it is created — the value is displayed only once and is never listed in the UI afterwards — and manage the key population through an out-of-band inventory plus create-new-and-retire-old replacement.

#### Rationale
**Why This Matters:**
- Integration keys authenticate programmatic access to Pendo data and must be treated as secrets
- A key's value is shown **only at creation** and is never displayed again anywhere in the Pendo UI, so any custody process that assumes you can go back and look up a key later will fail — the key must go into a secrets manager in the same sitting it is created
- A single integration key grants access to **all apps and all environments** in the subscription, so there is no such thing as a low-blast-radius key; a key issued for a sandbox integration reaches production data
- Non-admin users can use existing integration keys without restriction, so the population of people who can act with a key is wider than the population who can create one
- Pendo provides no rotation primitive: replacing a key means creating a new one, cutting consumers over, and retiring the old one — a process that only works if you know which consumers exist

**Attack Prevented:** API key leakage, unauthorized cross-environment data access, secret exposure in source code, unmanaged credential persistence

#### ClickOps Implementation

**Step 1: Create Keys With Custody in Place**
1. Navigate to: **Settings** → **Integrations** → **Integration Keys**
2. Before clicking **+ Add Integration Key**, have the destination secrets manager open and the consuming system identified
3. Create the key and store the displayed value immediately — it will not be shown again
4. Record the key's purpose, owner, and consuming system in your own inventory at the same moment; Pendo will not tell you later

**Step 2: Maintain the Inventory Out of Band**
1. Keep the authoritative key inventory outside Pendo (secrets manager metadata, a CMDB entry, or an owned register) because the UI does not list key values
2. Re-reconcile the inventory against the systems that consume Pendo on the same cadence as your access reviews

**Step 3: Replace Rather Than Rotate**
1. Create the replacement key first
2. Cut every consuming system over to it and verify
3. Delete the superseded key only once the new key is proven in production

> **Two properties change how you must handle these keys.** A key value is displayed only at creation and never listed in the UI afterwards, and any single key grants access to every app and environment in the subscription. An earlier revision of this guide instructed administrators to "review integration keys" and "document key usage" from the Pendo console — that is not possible as written, which is why this control is built around create-time custody instead. ([Pendo integration keys](https://support.pendo.io/hc/en-us/articles/9491198203547-Pendo-integration-keys), content verified via the vendor's help-center API, 2026-08)

---

### 3.2 Configure Data Privacy

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Configure data privacy controls.

#### Rationale
**Why This Matters:**
- Excluding sensitive fields and masking values prevents PII from being collected into Pendo unnecessarily
- Minimizing collected metadata reduces the impact of any breach and aligns with data-minimization principles
- Supporting deletion and GDPR/CCPA requests keeps the organization compliant and avoids regulatory penalties

**Attack Prevented:** PII over-collection, privacy violations, regulatory non-compliance, sensitive data exposure

#### ClickOps Implementation

**Step 1: Configure Data Collection**
1. Review collected metadata against Pendo's documented data collection prevention strategies
2. Exclude sensitive fields, and use HTML attributes to control what the agent is allowed to capture from the DOM
3. Configure data masking

**Step 2: Support Privacy Requests**
1. Configure deletion workflow
2. Support GDPR/CCPA requests
3. Document data handling

**Step 3: Constrain Pendo at the Network Edge**
1. Where egress is restricted, allowlist Pendo's published public IP addresses rather than opening broad egress for the agent

#### References
- [Data collection prevention strategies](https://support.pendo.io/hc/en-us/articles/17541315915035) (content verified via the vendor's help-center API, 2026-08)
- [HTML attributes in data collection](https://support.pendo.io/hc/en-us/articles/360031863152) (content verified via the vendor's help-center API, 2026-08)
- [Data collection and compliance](https://support.pendo.io/hc/en-us/articles/360031862372-Security-and-privacy-in-Pendo) (content verified via the vendor's help-center API, 2026-08)
- [Pendo public IP addresses](https://support.pendo.io/hc/en-us/articles/22713210834843) (content verified via the vendor's help-center API, 2026-08)

---

### 3.3 Configure Session Replay Privacy Before Activation

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.3 |
| NIST 800-53 | SC-28, AC-3 |

#### Description
Choose the Session Replay Starting Privacy Configuration deliberately before activating Session Replay — the choice is made once, at activation, and cannot be changed afterwards without involving Pendo support — then layer selector-level masking, audience scoping, and exclusion rules on top of it.

#### Rationale
**Why This Matters:**
- The **Starting Privacy Configuration is irreversible through self-service**: it is selected once when Session Replay is activated, and changing it later requires Pendo support, so a permissive choice made during a rushed rollout becomes the standing posture for every recording after it
- Session Replay captures what a user actually sees on screen, which is a materially different data class from event analytics — a replay of a support agent's screen can contain customer records that were never intended to leave the application
- Pendo always masks password, email, telephone, and numeric input types regardless of configuration, but everything outside those types is governed by the mode and rules you choose
- Recording only a defined audience and honouring exclusion lists limits collection to the population you have a basis to record

**Attack Prevented:** Over-collection of on-screen sensitive data, PII capture in replays, privacy and regulatory violations, irreversible mis-configuration of a high-sensitivity data source

#### Prerequisites
- Decide the privacy posture **before** activation. This is the one setting in this guide you cannot walk back yourself.

#### ClickOps Implementation

**Step 1: Choose the Starting Privacy Configuration (One Time Only)**
1. Select the privacy mode at activation:
   - **Maximum Privacy** — the recommended L1 default; the most restrictive capture
   - **Inputs Only**
   - **Minimum** (web only)
2. Choose **Maximum Privacy** unless you have a specific, documented reason not to. Loosening later is a support request; tightening later does not retroactively protect what was already recorded.

**Step 2: Add Selector-Level Rules**
1. Use CSS selectors to **mask**, **unmask**, or **block** specific elements
2. Apply the equivalent rules through the Visual Design Studio where you work visually
3. On mobile, review the image-capture toggle — screen imagery is a separate decision from text capture

**Step 3: Scope Who Is Recorded**
1. Use audience segmentation so replay is collected only from the population you intend
2. Confirm exclusion lists and Do Not Process settings are honoured — visitors covered by them are not recorded

**Step 4: Confirm the Retention and Filtering Behaviour**
1. Replays are filtered client-side before transmission, so masked content is not sent to Pendo rather than being hidden after arrival
2. Replays auto-delete after 30 days by default, or 90 days with extended retention — set this to match your policy

#### References
- [Session Replay privacy](https://support.pendo.io/hc/en-us/articles/18049064847515-Session-Replay-privacy) (content verified via the vendor's help-center API, 2026-08)

---

### 3.4 Sign Visitor and Account Metadata with RS256

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10, 16.11 |
| NIST 800-53 | SC-8, IA-9 |

#### Description
Sign the visitor and account metadata your application passes to Pendo as an RS256 JWT verified against a JWKS URI, so Pendo can prove the metadata originated from your servers rather than from the browser.

#### Rationale
**Why This Matters:**
- Metadata passed from the client is fully forgeable — anyone who can open developer tools can change their own visitor ID, account ID, role, or plan tier before it reaches Pendo
- Forged metadata is not just an analytics quality problem: guide targeting, Resource Center content, and audience segmentation are driven by it, so a user who can rewrite their own attributes can serve themselves in-app content intended for someone else
- Signing the metadata server-side with an RS256 JWT (RFC 7519) and publishing the public key at a JWKS URI lets Pendo verify origin without your application sharing a secret with the browser
- Enforcing signed-only metadata closes the fallback path where unsigned client values are still accepted

**Attack Prevented:** Metadata forgery, unauthorized guide and Resource Center targeting, segment manipulation, analytics poisoning

#### Prerequisites
- Server-side capability to mint JWTs and host a JWKS endpoint
- L2/L3 environments where guide targeting or segmentation carries security or commercial weight

#### ClickOps Implementation

**Step 1: Enable Signed Metadata**
1. Navigate to Pendo's **Install Settings** and enable signed metadata with public keys (RS256)
2. Register your JWKS URI so Pendo can retrieve the public key

**Step 2: Sign Server-Side**
1. Mint the JWT containing the visitor and account metadata on your server, never in the browser
2. Pass the signed token through `initialize()` (or `startSession()` for session-based flows) rather than passing raw metadata objects

**Step 3: Enforce**
1. Once every client path is emitting signed metadata, enable the option to accept **signed metadata only**
2. Rotate the signing key through the JWKS URI rather than by re-registering keys by hand

#### References
- [Send signed metadata with public keys (RS256)](https://support.pendo.io/hc/en-us/articles/52224691240859-Send-signed-metadata-with-public-keys-RS256) (content verified via the vendor's help-center API, 2026-08)

---

### 3.5 Govern Agent Analytics (AI) Data Collection

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.3 |
| NIST 800-53 | AC-3, SI-12 |

#### Description
Understand and constrain what Pendo's Agent Analytics collects from AI agent conversations — raw prompts and transcripts, restricted to a narrow set of viewers, retained for 18 months, and sanitized by pattern-based redaction that the vendor documents as imperfect.

#### Rationale
**Why This Matters:**
- Agent Analytics captures raw prompts and conversation transcripts, which are among the highest-sensitivity content in any product because users type things into an assistant they would never enter into a form field
- Pendo restricts visibility of that raw content to subscription admins and the AI Agent Admin role, which makes the assignment of those two roles a data-access decision, not just an administrative one ([2.1](#21-configure-user-roles))
- Redaction is regex-based and Pendo documents the limitation plainly: sensitive information entered in non-standard formats might not be sanitized — so the control that actually works is discouraging sensitive input at the agent level, not relying on the filter
- Visitors on an exclusion list or covered by Do Not Process generate no Agent Analytics data at all, which makes those lists the reliable lever for populations you must not collect from
- The 18-month retention period is materially longer than most product-analytics expectations and should be reconciled with your own retention policy

**Attack Prevented:** Over-collection of sensitive conversational content, unauthorized access to user prompts, retention of regulated data beyond policy, over-reliance on imperfect redaction

#### ClickOps Implementation

**Step 1: Control Who Can Read Raw Content**
1. Enumerate every subscription admin and every holder of the **AI Agent Admin** role — these are the only identities that can view raw prompts and transcripts
2. Treat additions to either as a data-access grant requiring the same approval as any other sensitive-data entitlement

**Step 2: Reduce What Is Collected at the Source**
1. Configure your agents to actively discourage users from entering sensitive information, rather than depending on downstream redaction
2. Do not treat the regex-based sanitization as a compensating control for regulated data — Pendo documents that non-standard formats may pass through

**Step 3: Use Exclusion Lists for Populations You Cannot Collect From**
1. Add visitors covered by regulatory or contractual restrictions to the exclusion list, or rely on Do Not Process — no Agent Analytics data is generated for them

**Step 4: Reconcile Retention**
1. Confirm the 18-month Agent Analytics retention is compatible with your data retention policy, and document the decision either way

#### References
- [Data collection and security for Agent Analytics](https://support.pendo.io/hc/en-us/articles/41103184012315-Data-collection-and-security-for-Agent-Analytics) (content verified via the vendor's help-center API, 2026-08)

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Pendo Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User roles | [2.1](#21-configure-user-roles) |
| CC6.7 | Key security | [3.1](#31-configure-integration-key-security) |

### NIST 800-53 Rev 5 Mapping

| Control | Pendo Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | User roles | [2.1](#21-configure-user-roles) |
| SC-12 | Key security | [3.1](#31-configure-integration-key-security) |

---

## Appendix A: References

**Official Pendo Documentation:**

> `support.pendo.io/hc` returns HTTP 403 to automated fetchers. The articles below were verified through the vendor's Zendesk help-center JSON API in 2026-08; the human-readable `/hc/` URLs are given here for readers.

- [Help Center](https://support.pendo.io/hc/en-us)
- [Security and Privacy in Pendo](https://support.pendo.io/hc/en-us/articles/360031862372-Security-and-privacy-in-Pendo)
- [Roles and permissions](https://support.pendo.io/hc/en-us/articles/360058639932-Roles-and-permissions)
- [SAML SSO overview](https://support.pendo.io/hc/en-us/articles/360032953392) · [Set up SAML SSO](https://support.pendo.io/hc/en-us/articles/29586397277595) · [SAML metadata and certificates](https://support.pendo.io/hc/en-us/articles/360042521712)
- [Set up SCIM in Pendo](https://support.pendo.io/hc/en-us/articles/4412768395803)
- [Pendo integration keys](https://support.pendo.io/hc/en-us/articles/9491198203547-Pendo-integration-keys)
- [Session Replay privacy](https://support.pendo.io/hc/en-us/articles/18049064847515-Session-Replay-privacy)
- [Send signed metadata with public keys (RS256)](https://support.pendo.io/hc/en-us/articles/52224691240859-Send-signed-metadata-with-public-keys-RS256)
- [Data collection and security for Agent Analytics](https://support.pendo.io/hc/en-us/articles/41103184012315-Data-collection-and-security-for-Agent-Analytics)
- [Data collection prevention strategies](https://support.pendo.io/hc/en-us/articles/17541315915035) · [Pendo public IP addresses](https://support.pendo.io/hc/en-us/articles/22713210834843)

**API Documentation:**
- [Pendo Developer Portal](https://developers.pendo.io/)

**Compliance Frameworks:**
- SOC 2 Type II, ISO 27001, ISO 42001, HIPAA, GDPR, CCPA

**Security Incidents:**
- No major public security incidents identified. Pendo conducts annual third-party security audits and penetration testing twice per year.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass: replaced the non-existent Admin/User/Read-only role model in 2.1 and 2.3 with Pendo's actual Subscription Admin + app-level roles + granular subscription permissions (and the paid Custom Roles add-on); rewrote 3.1 around create-time key custody because integration key values are shown only at creation, are never listed in the UI, and grant access to every app and environment; new controls 1.3 (SCIM), 3.3 (Session Replay privacy — the Starting Privacy Configuration is irreversible without Pendo support), 3.4 (RS256 signed metadata), and 3.5 (Agent Analytics data controls); enriched 3.2 with the data-collection-prevention and egress-allowlisting documentation; replaced the unverifiable SSO article with the current SAML SSO set and removed Trust Center/marketing references. `support.pendo.io/hc` 403s automated fetchers — all cited articles were content-verified through the vendor's help-center JSON API. Tier 2: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline covers Pendo. Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
