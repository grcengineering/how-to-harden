---
layout: guide
title: "Stripe Hardening Guide"
vendor: "Stripe"
slug: "stripe"
tier: "1"
category: "Productivity"
description: "Payment platform hardening for Stripe including SSO configuration, team permissions, and API key security"
version: "0.3.0"
maturity: ["ai-drafted", "ai-validated"]
last_updated: "2026-09-24"
---

## Overview

Stripe is a leading payment processing platform serving **millions of businesses** for online transactions. As a platform handling sensitive payment data, Stripe security configurations directly impact PCI compliance and financial data protection.

### Intended Audience
- Security engineers managing payment platforms
- IT administrators configuring Stripe
- Finance teams managing payment processing
- GRC professionals assessing payment security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Stripe Dashboard security including SSO, team permissions, API key management, and webhook security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [API Security](#3-api-security)
4. [Logging & Monitoring](#4-logging--monitoring)
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
Configure SAML SSO for Stripe Dashboard access.

#### Rationale
**Why This Matters:**
- Centralizes Stripe Dashboard authentication in your corporate IdP, applying MFA, conditional access, and device posture checks to every login
- Local email-and-password logins bypass IdP controls and are prime targets for phishing and credential stuffing
- IdP-driven deprovisioning removes Dashboard access the moment an employee leaves, eliminating orphaned accounts with standing access to payment data
- The Dashboard exposes live payment flows, payout settings, customer PII, and API key management — a single compromised login can redirect funds or exfiltrate cardholder data

**Attack Prevented:** Credential theft, phishing, account takeover, orphaned-account access

#### Prerequisites
- Account owner access
- SAML 2.0 compatible IdP
- DNS access to publish a domain-verification `TXT` record for each email domain your team signs in with

No plan gate: the **Single sign-on (SSO)** tab and its setup wizard were offered on a pay-as-you-go, unactivated account (live console, 2026-09-24).

#### ClickOps Implementation

**Step 1: Open SSO Setup**
1. Navigate to: **Settings** → **Team and security** → **Single sign-on (SSO)** tab, then click **Get started**
2. Answer the wizard's first question, **How do you want to assign roles?**:
   - **Stripe Dashboard** — team member roles are assigned and managed in the Dashboard, and new users are invited there or created through SCIM. Choose this if roles should follow SCIM-synchronized groups ([1.4](#14-configure-scim-provisioning-and-idp-role-mapping))
   - **Identity provider** — roles arrive in SAML assertions from your IdP, using each role's SSO Role ID ([1.4](#14-configure-scim-provisioning-and-idp-role-mapping))

> **Verification note (2026-09-24):** Step 1 was observed on a live Stripe console. Steps 2 and 3 follow Stripe's [SAML setup guide](https://docs.stripe.com/get-started/account/sso/other) and were not walked live: configuring SSO on an account whose only member is its Super Administrator risks locking that member out.

**Step 2: Verify Your Domain and Connect the IdP**
1. On the **Single sign-on (SSO)** page, click **+ Add domain**, publish the `stripe-verification=` value as a DNS `TXT` record, then click **Save and verify**. Keep the record afterwards — Stripe re-checks it, and deleting it can cost you Dashboard access
2. In the IdP, create a SAML application with ACS URL `https://dashboard.stripe.com/login/saml/consume`, Entity ID `https://dashboard.stripe.com/saml/metadata`, the member's email address as Name ID, and `RSA-SHA256` / `SHA256` signing
3. In Stripe, enter the IdP's **Issuer ID**, **Identity provider URL**, and **Identity provider certificate**

**Step 3: Test and Enforce**
1. Click **Test** — Stripe saves the settings only after the test succeeds
2. Select the enforcement mode: **Off**, **Optional**, or **Required**. **Required** turns off email-and-password sign-in for the account
3. Run at **Optional** until every administrator has completed an SSO sign-in, then move to **Required**

**Automation:** ClickOps only — Stripe exposes no write interface for SSO configuration: its published API has no SSO, SAML, or domain-verification endpoint in the GA, public-preview, or private-preview OpenAPI specs, and the Stripe CLI only calls that API ([API reference](https://docs.stripe.com/api), [OpenAPI specs](https://github.com/stripe/openapi), 2026-09-24).

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Stripe team members.

#### Rationale
**Why This Matters:**
- Adds a second authentication factor so a stolen or guessed password alone cannot grant Dashboard access
- Brute-force, password-spray, and credential-stuffing attacks that succeed against reused passwords are blocked at the second factor
- Passkeys and hardware security keys resist phishing and adversary-in-the-middle proxy attacks that defeat SMS or TOTP — Stripe describes them as "resistant to phishing" and recommends them over other factors
- Stripe accounts control real money movement and customer financial data, making single-factor access an unacceptable risk

**Attack Prevented:** Password reuse compromise, credential stuffing, brute force, phishing, SIM-swap interception

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Console path, toggle label and per-user factor paths re-read on a live test-mode account; toggle not changed" date="2026-09-24" %}

**Step 1: Require Two-Step Authentication**
1. Navigate to: **Settings** → **Team and security** → **Two-step authentication** tab
2. Turn on **Require two-step authentication for your team** — any member without a second factor must enable one the next time they sign in
3. The requirement is account-wide; Stripe has no per-role two-step setting

**Step 2: Configure Methods**

> **Stripe's stated preference order:** Stripe recommends **passkeys or hardware security keys** because they are resistant to phishing, and states that SMS should be used **only as a last resort** ([Security at Stripe](https://docs.stripe.com/security)). Treat SMS as a fallback to be retired, not as a supported backup factor.

1. Each member enrols their own factors at **Settings** → **Personal details**: **Passkeys** → **Add passkey**, or **Two-step authentication** → **Add authentication method** (hardware security key, authenticator app, or phone number; Touch ID and Windows Hello can be added only after another method). An administrator cannot enrol factors on another member's behalf
2. Require administrators and anyone who can move money to add a passkey or hardware security key, and check it during access reviews
3. Use authenticator apps where a hardware factor is not yet feasible
4. Drive SMS enrolment to zero — it is a last-resort factor, exposed to SIM-swap and interception

**Automation:** ClickOps only — Stripe exposes no write interface for the two-step requirement or for member factors: no such endpoint exists in its GA, public-preview, or private-preview OpenAPI specs ([API reference](https://docs.stripe.com/api), [OpenAPI specs](https://github.com/stripe/openapi), 2026-09-24).

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Limit how long a Dashboard session stays usable. Stripe offers no session-timeout or automatic-logout setting, so session lifetime is enforced at the identity provider and stale sessions are signed out per user.

> **Verification note (2026-09-24):** Checked on a live Stripe console: none of the **Settings** → **Team and security** tabs (Team, Single sign-on (SSO), Two-step authentication, Security history, Access requests, MCP and CLI access) carries a session-timeout or automatic-logout setting. The only session control is per user, under **Settings** → **Personal details** → **Sessions**.

#### Rationale
**Why This Matters:**
- Session lifetime limits the window an unattended or hijacked Dashboard session stays usable
- Signing out other sessions protects against walk-up access on shared, lost, or unlocked devices
- Shorter session lifetimes reduce the value of a stolen session cookie or token to an attacker
- Because the Dashboard can initiate payouts and refunds, a lingering authenticated session is a direct path to financial fraud

**Attack Prevented:** Session hijacking, cookie theft, unattended-workstation abuse

#### ClickOps Implementation

**Step 1: Enforce Session Lifetime at the IdP**
1. Stripe exposes no Dashboard session-timeout setting, so do not look for one under **Settings** → **Team and security**
2. Once SSO is **Required** ([1.1](#11-configure-saml-single-sign-on)), set sign-in frequency and re-authentication policy in the IdP. The IdP's policy applies each time a member signs in through SSO; it does not end a Stripe session that is already open

**Step 2: Sign Out Stale Sessions**
1. Each member reviews **Settings** → **Personal details** → **Sessions** and uses **Sign out all other sessions** after using a shared, lost, or borrowed device
2. For a departing or compromised member, remove them from **Settings** → **Team and security** → **Team**, or deprovision them through SCIM ([1.4](#14-configure-scim-provisioning-and-idp-role-mapping)) — Stripe documents this as the way to remove access immediately rather than at session expiry

**Automation:** ClickOps only — Stripe exposes no session-timeout setting in any interface: none in the Dashboard (checked live, 2026-09-24) and no session-policy endpoint in its GA, public-preview, or private-preview OpenAPI specs ([OpenAPI specs](https://github.com/stripe/openapi), 2026-09-24).

---

### 1.4 Configure SCIM Provisioning and IdP Role Mapping

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.3, 6.1, 6.2 |
| NIST 800-53 | AC-2, AC-2(1), AC-2(4) |

#### Description
Enable SCIM provisioning alongside SAML SSO so Stripe user accounts are created, updated, and — critically — deprovisioned automatically from your identity provider, and map IdP groups to Stripe roles using each role's SSO Role ID so privilege is assigned by the IdP rather than by hand in the Dashboard.

#### Rationale
**Why This Matters:**
- Stripe documents a specific gap: **without SCIM, revoking a user in the IdP does not propagate to Stripe until the user's existing Stripe session expires**, leaving a terminated or compromised account able to keep operating in a payments console during that window
- Just-in-time (JIT) provisioning creates accounts on first SSO login, and Stripe documents no automatic removal path for them, so a JIT-only deployment depends on someone remembering to delete each departed user
- Mapping IdP groups to Stripe roles via SSO Role IDs makes privilege a property of group membership, so an access review in the IdP is an access review of Stripe — manual role assignment drifts silently
- Supporting both IdP-initiated and SP-initiated SSO ensures users cannot fall back to a password path that bypasses IdP conditional access

**Attack Prevented:** Persistent access after offboarding, orphaned accounts, privilege drift, unrevoked sessions following IdP termination

#### Prerequisites
- SAML SSO configured and working ([1.1](#11-configure-saml-single-sign-on))
- An identity provider supporting SCIM 2.0 provisioning
- **Administrator** or **Super Administrator** role
- A live-mode account or organization — Stripe enables SCIM only there, and accounts that belong to an organization configure SSO and SCIM from the organization

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Settings** → **Team and security** → **SCIM provisioning** and click **Enable**
2. Copy the **SCIM endpoint URL** and **SCIM API key** into your IdP's provisioning application, store the key in your secrets manager, then run an initial sync

**Step 2: Map Groups to Roles**
1. Match the mapping to the role-assignment mode chosen in [1.1](#11-configure-saml-single-sign-on). With **Identity provider** mode, collect the **SSO Role ID** for each role and map each IdP group to it in the SAML attribute statements. With **Stripe Dashboard** mode, push groups through SCIM and assign a role to each synced group in the Dashboard
2. Do not mix the two for one user — Stripe does not accept a role through both a SAML assertion and a SCIM-synced group
3. Confirm that no user receives a role higher than their group's mapping through a leftover manual assignment

**Step 3: Verify Deprovisioning**
1. Suspend a test user in the IdP and confirm the SCIM sync removes them from the Stripe team list — Stripe treats both deactivation and deletion as deleting the user from the account
2. Document the residual exposure for any account **not** covered by SCIM: revocation there takes effect only when the existing Stripe session expires, unless you delete the user from **Team** by hand

> **Verification note (2026-09-24):** Not walked live. The account available for validation was a test-mode account whose only member is its Super Administrator: SCIM cannot be enabled there, and configuring the SSO it depends on would risk locking that member out. No **SCIM provisioning** entry appeared among that account's **Team and security** tabs. The steps follow Stripe's [SCIM provisioning guide](https://docs.stripe.com/get-started/account/sso/scim).

**Automation:** ClickOps only for enabling SCIM and assigning roles — Stripe's published API has no SCIM-enablement or role endpoint in its GA, public-preview, or private-preview OpenAPI specs ([OpenAPI specs](https://github.com/stripe/openapi), 2026-09-24). Provisioning itself is automated by design: once enabled, your IdP drives Stripe's SCIM 2.0 endpoint (`/scim/v2/Users`, `/scim/v2/Groups`) with the SCIM API key ([Set up SCIM provisioning](https://docs.stripe.com/get-started/account/sso/scim), 2026-09-24).

Source: [Single sign-on (SSO) at Stripe](https://docs.stripe.com/get-started/account/sso)

#### Validation & Testing
1. Create a user in the mapped IdP group and confirm the account appears in Stripe with the expected role and no additional permissions
2. Remove the user from the group and confirm the role change or deactivation propagates
3. Review the Stripe team list against the IdP group membership list — any account present only in Stripe is unmanaged and must be justified or removed

#### Compliance Mappings

| Framework | Control | How This Maps |
|-----------|---------|---------------|
| CIS Controls v8 | 5.1 Establish and Maintain an Inventory of Accounts | SCIM keeps the Stripe account list authoritative |
| CIS Controls v8 | 5.3 Disable Dormant Accounts | Automated deprovisioning from the IdP |
| NIST 800-53 Rev 5 | AC-2(1) Automated System Account Management | SCIM-driven lifecycle |
| NIST 800-53 Rev 5 | AC-2(4) Automated Audit Actions | Provisioning events recorded by the IdP |

---

## 2. Access Controls

### 2.1 Configure Team Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Stripe roles. The role catalogue is materially larger than the classic five — it now includes administrative roles such as **Super Administrator** and **IAM Admin** (documented as IAM Administrator) alongside narrow task roles such as **Dispute Analyst** and **Refund Analyst**, and Stripe documents further task roles such as **Transfer Analyst** and **Tax Analyst** that not every account is offered — so assignment should start from the narrowest task role that fits the job, not from Administrator.

#### Rationale
**Why This Matters:**
- Assigning the minimum necessary role limits what any single account can do if it is compromised
- Narrow task roles (Dispute, Refund, Tax Analyst) let staff do their jobs without the ability to move money, change payout settings, or manage keys
- **Roles that can invite team members are a compromise-amplification path**: an attacker who takes over an invite-capable account does not need to escalate that account's own privileges — they can create a new one at whatever level the invite permission allows, and the new account survives remediation focused on the original
- **Transfer Analyst requires account-level two-step verification** for a non-administrator to initiate transfers, so leaving 2SV unenforced silently blocks the least-privilege path and pushes teams to over-assign Administrator instead
- Over-permissioned accounts hand an attacker who phishes one user full control over payments, refunds, and customer data

**Attack Prevented:** Privilege escalation, insider misuse, lateral movement, persistence via attacker-created team members, blast-radius expansion

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Team tab and Add member role picker re-read on a live test-mode account; invite cancelled" date="2026-09-24" %}

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Team and security** → **Team**
2. Open **Add member** to see the roles your account can actually assign (cancel without sending an invite), and compare them with the current catalogue in [Stripe user roles](https://docs.stripe.com/get-started/account/teams/roles). The two differ: a new pay-as-you-go account offered 19 roles in 8 groups, without **Transfer Analyst** or **Tax Analyst** (live console, 2026-09-24)
3. Assign the narrowest role that covers the job: prefer **Dispute Analyst**, **Refund Analyst**, **Tax Analyst** (where offered), or **View Only** over **Analyst**, and **Analyst** over **Administrator**

**Step 2: Apply Least Privilege**
1. Use **View Only** for read access
2. Limit **Administrator**, **Super Administrator**, and **IAM Admin** to a named, justified few — these carry account-wide authority
3. Inventory which assigned roles can invite team members and treat every one of them as an administrative account for monitoring and 2SV purposes
4. Where your account offers **Transfer Analyst**, enforce account-level two-step verification so the role is usable, rather than granting Administrator to work around the requirement
5. Expect a delay after a change: Stripe warns that recently invited members, or members whose roles changed recently, may be unable to perform some sensitive actions for 2 days
6. Regular access reviews

**Automation:** ClickOps only — Stripe's published API has no team-member or role endpoint in its GA, public-preview, or private-preview OpenAPI specs ([OpenAPI specs](https://github.com/stripe/openapi), 2026-09-24). Where SSO is in use, roles can instead arrive in SAML assertions or attach to SCIM-synced groups ([1.4](#14-configure-scim-provisioning-and-idp-role-mapping)).

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
- Administrator accounts can change payout bank details, manage API keys, and add or remove team members — the highest-value targets in the account
- Keeping admins to a small, monitored set reduces the attack surface for account takeover
- Requiring 2FA and monitoring admin activity makes compromise harder and detection faster
- A single compromised admin can silently redirect payouts or grant persistent access, so minimizing their number is critical
- **Super Administrator** and **IAM Admin** are distinct account-wide roles beyond the classic Administrator — an inventory that counts only "Administrator" understates how many accounts actually hold account-wide authority
- Any role that can invite team members is effectively administrative for blast-radius purposes: it lets an attacker mint fresh access that outlives revocation of the account they compromised

**Attack Prevented:** Admin account takeover, payout redirection, unauthorized privilege grants, attacker-created persistent accounts

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Team Roles column and Communication preferences row re-read on a live test-mode account" date="2026-09-24" %}

**Step 1: Inventory Admins**
1. Navigate to: **Settings** → **Team and security** → **Team** and read the **Roles** column. A member holding several roles shows as, for example, "Super Administrator, + 1 others", so open the member to see every role
2. Review administrator accounts, including **Super Administrator** and **IAM Admin** assignments, against the current role list in [Stripe user roles](https://docs.stripe.com/get-started/account/teams/roles)
3. Document admin access
4. Identify unnecessary privileges, and separately flag every role holding team-invite permission

**Step 2: Apply Restrictions**
1. Limit admins to 2-3 users
2. Turn on the account-wide two-step requirement ([1.2](#12-enforce-two-factor-authentication)) — Stripe has no per-role requirement — and require administrators to use passkeys or hardware security keys by policy
3. Monitor admin activity, and review new team-member invitations as a security event rather than an HR one ([4.1](#41-review-security-history)): each reviewer turns on **Settings** → **Communication preferences** → **Team member changes on your account**

**Automation:** ClickOps only — Stripe's published API has no team-member or role endpoint in its GA, public-preview, or private-preview OpenAPI specs ([OpenAPI specs](https://github.com/stripe/openapi), 2026-09-24). For read-only evidence, the Activity Logs API (public preview) reports invitation and role changes ([4.1](#41-review-security-history)).

---

## 3. API Security

### 3.1 Configure API Key Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Inventory and secure Stripe API keys, using restricted API keys (RAKs) as the default credential for new integrations and reserving secret keys for uses that genuinely cannot be expressed as a restricted key.

> **Changed recommendation:** Stripe now states that it **does not recommend using secret keys for new use cases** and directs teams to migrate to restricted API keys ([API keys](https://docs.stripe.com/keys)). Restricted keys are the baseline posture in this guide, not an optional hardening step. Accounts created before May 2026 may have **zero restricted keys** provisioned — an empty restricted-key list is the expected starting state, not evidence that RAKs are unavailable.

> **Terminology change:** Stripe's test mode is now delivered through **sandboxes** — isolated environments with their own data. Keys prefixed `pk_test_`, `rk_test_`, and `sk_test_` are **sandbox keys**, not "test mode keys" on the live account. Treat a sandbox as a separate environment boundary, and never let sandbox credentials reach production or vice versa.

#### Rationale
**Why This Matters:**
- Secret API keys can charge cards, issue refunds, and read customer data, so a leaked key is equivalent to full programmatic account access — which is precisely why Stripe has de-recommended them for new integrations
- Restricted keys scoped to minimum permissions limit what a leaked key can do, turning a total-account compromise into a bounded one
- Sandbox isolation prevents accidental real-money operations during development, and makes a leaked development credential inert against production data
- Rotation is a supported dashboard operation with a defined overlap window, so there is no technical excuse for indefinitely-lived keys
- Organization keys and keys managed by a hosting platform exist and behave differently from ordinary account keys; an inventory that misses them misstates the account's real exposure

**Attack Prevented:** API key leakage, unauthorized charges and refunds, data exfiltration, cross-account abuse via organization-scoped keys

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Developers menu, API keys page, key menus and Suspicious API activity re-read live; a key was rotated with immediate expiry in the same run" date="2026-09-24" %}

**Step 1: Review API Keys**
1. Navigate to: **Developers** → **API keys** ([dashboard.stripe.com/apikeys](https://dashboard.stripe.com/apikeys)). The page lists **Restricted keys** and **Standard keys** with **Name**, **Token**, **Access policy**, **Last used**, and **Created** columns
2. Review all API keys and document each key's purpose and owning integration
3. Review the **Suspicious API activity** tab next to **API keys** for flagged requests (rotate any key behind a request you do not recognise), and its **Restricted features** section, which lists features Stripe deactivated automatically because they had not been used recently
4. Include the key classes that are easy to miss:

| Key class | Prefix / form | Note |
|-----------|---------------|------|
| Restricted API key (live) | `rk_live_` | The recommended default for new integrations |
| Secret key (live) | `sk_live_` | De-recommended for new use cases; migrate to RAKs |
| Publishable key | `pk_live_` | Client-side, not a secret |
| Sandbox keys | `pk_test_`, `rk_test_`, `sk_test_` | Belong to an isolated sandbox environment |
| Organization API key | `sk_org_` | Operates across accounts in the organization |
| Managed API key (preview) | Issued by a hosting platform's integration | The platform creates and rotates it; it is labelled with the platform's name and cannot be revealed, and you can still expire it ([Managed API keys](https://docs.stripe.com/keys/managed-api-keys)) |

**Step 2: Apply Best Practices**
1. Create restricted keys with minimum permissions for every new integration (see [3.3](#33-configure-restricted-keys))
2. Never expose secret keys; keep them in a secrets manager and out of source control, logs, and client-side code
3. Use sandbox credentials for development, and treat the sandbox as a distinct environment rather than a mode toggle
4. Attach an access policy to every live-mode key (see [3.4](#34-configure-api-key-access-policies))

**Step 3: Key Rotation**

Stripe's documented rotation mechanics ([API keys](https://docs.stripe.com/keys)) — build the rotation runbook on these, not on assumptions:

- **Rotate key** (the key's overflow menu) keeps **both the old and the new key valid for up to 7 days**, so cutovers do not need a maintenance window
- The rotate dialog's **Expiration** choice decides the old key's fate: **Now** deletes it immediately, a later time schedules its expiry
- **Expire key** revokes a key immediately. On the account walked for this guide it appeared only in the restricted keys' menus — the standard secret key's menu offered **Rotate key** but no **Expire key**
- Keys unused for payouts or transfers for **more than 180 days** are placed in a limited-access state and need **Restore access** before they can create payouts or transfers again

1. Rotate keys on a schedule, using the overlap window to migrate integrations; before the old key expires, check its **View request logs** until its traffic is zero
2. On suspected compromise, use **Expire key**, or **Rotate key** with **Expiration** set to **Now** — never a scheduled expiration, because the overlap that helps a planned migration also extends an attacker's access
3. Update integrations and confirm the old key is expired, not merely superseded
4. Reconcile dormant keys: a key sitting in limited access for inactivity is a key nobody owns — delete it rather than restoring it reflexively

#### Code Implementation

{% include pack-code.html vendor="stripe" section="3.1" %}

---

### 3.2 Configure Webhook Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8 |

#### Description
Secure webhook endpoints — signature verification, sender IP allowlisting, replay tolerance, endpoint-secret rotation, and TLS requirements — for the event destinations configured in Workbench.

#### Rationale
**Why This Matters:**
- Verifying Stripe's webhook signature ensures events actually originate from Stripe and were not forged by an attacker
- Without signature verification, an attacker can POST fake events to mark orders paid, trigger fulfillment, or corrupt application state
- Stripe publishes its webhook sender IP ranges and advises using an IP allowlist **alongside** signature verification rather than instead of it — defence in depth, because each control fails differently
- The `Stripe-Signature` header carries a timestamp checked against a tolerance window; disabling the tolerance turns a captured-and-replayed legitimate event into a permanently valid one
- Webhooks often drive critical business logic, so a forged event can translate directly into fraud or free goods

**Attack Prevented:** Webhook spoofing, forged payment events, replay attacks, signature-scheme downgrade, fulfillment fraud

#### ClickOps Implementation

**Step 1: Configure Webhooks**
1. Navigate to: **Developers** → **Webhooks**, which opens the **Webhooks** tab of **Workbench** ([dashboard.stripe.com/workbench/webhooks](https://dashboard.stripe.com/workbench/webhooks)). Workbench is the surface Stripe recommends; the older Developers Dashboard still works. If the deep link lands on the Home page, open Workbench once from the **Developers** menu and retry it
2. Review the webhook endpoints, which Workbench lists as event destinations (**Add destination** creates one); confirm each one is still owned and still needed
3. Confirm every live endpoint is **HTTPS with TLS 1.2 or 1.3** — Stripe requires it for live-mode endpoints
4. Stay within the documented limit of **16 endpoints** per account; hitting the cap by accretion means dead endpoints are lingering

**Step 2: Verify Signatures**
1. Always verify the `Stripe-Signature` header against the endpoint's signing secret before processing an event
2. Keep the **default 5-minute timestamp tolerance**. Setting the tolerance to `0` disables replay protection entirely — a captured event stays replayable forever
3. **Ignore signature schemes other than `v1`.** The header can carry multiple schemes; accepting an unknown or older scheme is a downgrade path that lets an attacker choose the weakest verification you support
4. Reject unverified events with an error response and do not process them

**Step 3: Allowlist Stripe's Sender IPs**
1. Restrict the webhook endpoint at the network or WAF layer to Stripe's published webhook sender IP ranges
2. Use **both** the IP allowlist and signature verification — Stripe's own guidance is to combine them, since an allowlist alone cannot detect a forged payload from a shared egress and a signature alone cannot stop endpoint scanning

**Step 4: Rotate Endpoint Secrets and Watch Delivery**
1. Roll each endpoint's signing secret on a schedule, using the **maximum 24-hour overlap** during which both the old and new secret are accepted; complete the deployment inside that window
2. Treat a **3xx response as a delivery failure** — Stripe does not follow redirects for webhook delivery, so an endpoint that "works" in a browser because of a redirect is silently failing
3. Monitor delivery failures as a security signal, not just an availability one: a sudden failure spike can indicate endpoint tampering or a misapplied allowlist

Source: [Receive Stripe events in your webhook endpoint](https://docs.stripe.com/webhooks)

#### Code Implementation

The Terraform pack declares a security-events endpoint with the official `stripe/stripe` provider; the API pack audits existing endpoints and can optionally create the same endpoint. Neither handles the signing secret for you: Terraform keeps it in state, and the API pack deliberately does not print it — reveal it from the destination in Workbench and store it in your secrets manager.

{% include pack-code.html vendor="stripe" section="3.2" %}

---

### 3.3 Configure Restricted Keys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Use restricted API keys (RAKs) as the default credential for every integration, scoped to the minimum permissions that integration needs. Stripe de-recommends secret keys for new use cases and directs migration to restricted keys, so this is baseline posture rather than an enhanced control.

> **Migration note:** Accounts provisioned before May 2026 may show an empty restricted-key list. That is the expected starting state — it means no RAKs have been created yet, not that the account is ineligible. Treat every existing `sk_live_` key as a migration candidate ([API keys](https://docs.stripe.com/keys)).

#### Rationale
**Why This Matters:**
- Restricted keys grant only the specific permissions an integration needs, so a compromised key cannot perform unrelated actions
- Per-integration keys isolate failures — revoking one leaked key does not break every other integration
- Scoping keys to read-only or single-resource access limits the damage from a leak in third-party code or logs
- Using one all-powerful secret key everywhere means any single leak exposes the entire account, which is why Stripe no longer recommends secret keys for new integrations

**Attack Prevented:** Over-privileged key compromise, lateral abuse across integrations, full-account exposure from a single leak

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Create restricted key flow walked live to the permission grid; no key created" date="2026-09-24" %}

**Step 1: Create Restricted Keys**
1. Navigate to: **Developers** → **API keys** ([dashboard.stripe.com/apikeys](https://dashboard.stripe.com/apikeys)) and click **Create restricted key**
2. Answer **How will you be using this key?**: **Powering an integration you built**, **Providing this key to a third-party application**, or **Authorizing an AI agent**. Tag every key an autonomous agent uses as an agent key — Stripe recommends this for agents, and agent-tagged keys are subject to two-party approval rules for sensitive actions such as payouts, refunds, and account configuration changes (**Settings** → **Approvals**; [API keys for autonomous agents](https://docs.stripe.com/keys#agent-keys))
3. Skip the use-case templates (One-time payments, Recurring subscriptions and billing, and so on) and select **Choose your own**, then set each resource to **None**, **Read**, or **Write** — grant Read where Write is not required, and leave every unused resource at **None**

**Step 2: Apply Per-Integration**
1. Use separate keys per integration
2. Document key purposes and owners
3. Audit key usage through the **Last used** column and each key's overflow menu → **View request logs**

**Step 3: Migrate Off Secret Keys**
1. Enumerate every `sk_live_` key still in use and identify the permissions each integration actually exercises
2. Issue an equivalently scoped restricted key, cut the integration over, then retire the secret key with **Expire key** or with **Rotate key** and **Expiration** set to **Now** ([3.1](#31-configure-api-key-security))
3. Keep secret keys only where a documented capability is unavailable to restricted keys, and record that justification

#### Code Implementation

Run the pack with the integration's own restricted key: it probes resources a narrowly scoped key should be denied and passes only on an explicit `403`. It exits `0` only when every probe is denied, `3` (needs review) when the key can read a probed resource — a full-access secret key always lands here — and `1` when a probe cannot be assessed, such as a rejected key or no connection.

{% include pack-code.html vendor="stripe" section="3.3" %}

---

### 3.4 Configure API Key Access Policies

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 13.4 |
| NIST 800-53 | AC-3, AC-17, SC-7 |

#### Description
Attach an access policy to every live-mode API key so the key only works from network origins you expect. Stripe offers an **IP policy** (allowed IPv4 addresses and CIDR ranges) and an **Advanced policy** (allow by autonomous system number and country, with categorical blocking of anonymous VPNs, public proxies, residential proxies, and Tor), configured on the **Access policies** tab under **Developers** ([dashboard.stripe.com/api-access-policies](https://dashboard.stripe.com/api-access-policies)).

> **Replaces the old feature:** Access policies **superseded** Stripe's earlier per-key "IP address restrictions". If your runbook still points at IP restrictions on the key detail page, it is describing a retired surface — the configuration now lives on the API access policies page.

#### Rationale
**Why This Matters:**
- Stripe recommends configuring access policies on **all live mode keys** — an unpolicied live key is usable from anywhere on the internet the moment it leaks, which is exactly the scenario key rotation is racing against
- A network-origin policy converts a leaked key from an immediately exploitable credential into one an attacker must also relay through an approved network, adding an obstacle that rotation timelines depend on
- The Advanced policy's categorical blocks (anonymous VPN, public proxy, residential proxy, Tor) cut off the anonymising infrastructure that credential-abuse tooling defaults to, without needing to enumerate individual addresses
- ASN and country scoping suits integrations that run from a cloud provider or a known region, where a fixed egress IP list is impractical but the network origin is still predictable

**Attack Prevented:** Use of leaked API keys from attacker infrastructure, credential abuse via anonymising proxies and Tor, exploitation of keys exfiltrated from source control or logs

#### Prerequisites
- Administrator access to the Stripe Dashboard
- A known egress IP range, ASN, or country set for each integration

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Access policy column, Create a policy wizard through both access methods including the IP-address entry, and Manage access policy dialog walked live; nothing saved" date="2026-09-24" %}

**Step 1: Inventory Live Keys Without a Policy**
1. Navigate to: **Developers** → **API keys** in live mode and read the **Access policy** column — every key showing **None** is the exposure
2. For each key, determine the integration's real egress: fixed NAT addresses, a cloud provider ASN, or a country set

**Step 2: Choose and Create the Policy**
1. Navigate to: **Developers** → **Access policies** ([dashboard.stripe.com/api-access-policies](https://dashboard.stripe.com/api-access-policies)) and click **Create a policy**
2. On **Details**, name the policy. Consider **Default policy for new keys**, which protects keys created later automatically — but only once the policy's allow set covers every integration that will get a new key
3. On **Access method**, choose **IP addresses** (selected by default) where the integration has stable egress addresses — specify individual IPv4 addresses or CIDR ranges
4. Choose **Advanced** where egress is not a fixed address list — allow by **Autonomous system numbers** and **Countries**, and under **Denied sources** block **Anonymous VPNs**, **Public proxies**, **Residential proxies**, and **Tor exit nodes**
5. Keep the allow set as narrow as the integration tolerates; a policy allowing an entire large country adds little

**Step 3: Attach and Verify**
1. Attach the policy from **Developers** → **API keys** → the key's overflow menu → **Manage access policy**, choosing it in the **Access policy** dropdown — start with a non-critical integration
2. Confirm legitimate traffic still succeeds, then extend to remaining live keys
3. Repeat for every live-mode key, including organization keys — Stripe's recommendation is all of them

**Automation:** ClickOps only — Stripe exposes no write interface for access policies: no access-policy endpoint exists in its GA, public-preview, or private-preview OpenAPI specs, and the `stripe/stripe` Terraform provider (0.3.0) has no access-policy resource ([OpenAPI specs](https://github.com/stripe/openapi), [Terraform resources](https://docs.stripe.com/terraform/resources), 2026-09-24).

Source: [API keys](https://docs.stripe.com/keys)

#### Validation & Testing
1. From an allowed origin, make a benign authenticated API call and confirm it succeeds
2. From an origin outside the policy (for example a VPN egress), make the same call and confirm Stripe rejects it
3. Re-read the **Access policy** column on the live-mode **API keys** page and confirm no key shows **None**

#### Compliance Mappings

| Framework | Control | How This Maps |
|-----------|---------|---------------|
| CIS Controls v8 | 4.1 Establish and Maintain a Secure Configuration Process | Policy applied as standard configuration for live keys |
| CIS Controls v8 | 13.4 Perform Traffic Filtering Between Network Segments | Origin-restricted API access |
| NIST 800-53 Rev 5 | AC-3 Access Enforcement | Network-origin condition on credential use |
| NIST 800-53 Rev 5 | AC-17 Remote Access | Restricts where remote API access may originate |
| PCI DSS v4.0 | 7.2.1 | Access restricted by defined need and origin |

---

## 4. Logging & Monitoring

### 4.1 Review Security History

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.5, 8.11 |
| NIST 800-53 | AU-2, AU-6, AU-12 |

#### Description
Use Stripe's security history (**Settings** → **Team and security** → **Security history**) to review account-level security events — logins, API key changes, and bank-account changes among them — and grant the **View security history audit logs** permission deliberately, since the record is invisible to roles that lack it.

#### Rationale
**Why This Matters:**
- Security history is where a payments account's two highest-signal events land: **who logged in** and **when bank account details changed**. Payout redirection is the terminal step of most Stripe account-takeover fraud, so a change recorded here and unreviewed is a fraud that already happened
- Stripe monitors devices and IP addresses used to access the account and emails users about logins from unknown devices — those notifications are an alerting channel only if someone treats them as security events rather than noise
- The history is **user-exportable**, and the preview Activity Logs API exposes key, invitation, and role events programmatically, so periodic evidence collection does not depend on anyone remembering to look
- Access to the record is gated by the **View security history audit logs** role permission — if no one outside the administrators holds it, security review depends entirely on the same accounts an attacker would target first

**Attack Prevented:** Undetected account takeover, unnoticed payout/bank-account redirection, unreviewed logins from attacker-controlled devices

#### Prerequisites
- A role carrying the **View security history audit logs** permission

#### ClickOps Implementation{% include status-mark.html status="ai-validated" evidence="Security history, its Activity Logs API banner and Communication preferences re-read on a live test-mode account" date="2026-09-24" %}

**Step 1: Grant Review Access**
1. Navigate to: **Settings** → **Team and security** → **Team**
2. Confirm at least one non-administrator security reviewer holds a role with the **View security history audit logs** permission, so review does not depend solely on administrator accounts. The **Add member** role picker shows no permission names — check each role's **View details** link or the [Stripe user roles](https://docs.stripe.com/get-started/account/teams/roles) page

**Step 2: Establish the Review**
1. Navigate to: **Settings** → **Team and security** → **Security history** ([dashboard.stripe.com/security_history](https://dashboard.stripe.com/security_history) redirects there). Filter by **Date**, **IP address**, **User**, **API key**, **Device**, or **Action**
2. Review on a defined cadence, prioritising **bank account changes**, **logins**, and **API key** creation and expiry — treat any bank-account change not traceable to a known finance request as an incident until proven otherwise
3. Correlate logins against expected user locations and devices

**Step 3: Export and Retain**
1. Use **Export** on your review cadence and retain the file with your other audit evidence — the page covers roughly the last 180 days, so a longer record exists only if you keep the exports
2. For programmatic collection, Stripe's **Activity Logs API** (`GET /v2/iam/activity_logs`, public preview) returns API key, invitation, and role events for 6 months to a key with the **Activity logs: Read** permission, and can feed a SIEM ([Activity logs](https://docs.stripe.com/activity-logs)). While it is in preview, keep the export as the durable record

**Step 4: Route Unknown-Device Notifications**
1. Each reviewer turns on **Settings** → **Communication preferences** → **Security related alerts** and **Unusual activity on your account** (Email, SMS, or Push). The preferences are per user, so set them for every reviewer, and route the email to a monitored mailbox rather than an individual's inbox filter
2. Define the response for an unrecognised login: force credential reset, expire live API keys ([3.1](#31-configure-api-key-security)), and review security history for subsequent bank-account changes

**Automation:** ClickOps only for the review itself — Stripe exposes no write interface for security history ([OpenAPI specs](https://github.com/stripe/openapi), 2026-09-24). The read surface is the Activity Logs API above; it is in public preview and no pack is shipped for it yet, because this run did not exercise it against a live account ([Activity logs](https://docs.stripe.com/activity-logs), 2026-09-24).

Source: [Security at Stripe](https://docs.stripe.com/security)

#### Validation & Testing
1. Sign in from a new device and confirm the event appears in security history and generates a notification email
2. Confirm a designated non-administrator reviewer can open the security history page
3. Produce a security history export covering the last review period

#### Compliance Mappings

| Framework | Control | How This Maps |
|-----------|---------|---------------|
| CIS Controls v8 | 8.2 Collect Audit Logs | Security history captures account-level events |
| CIS Controls v8 | 8.5 Collect Detailed Audit Logs | Login, device, and bank-change detail |
| CIS Controls v8 | 8.11 Conduct Audit Log Reviews | Defined review cadence |
| NIST 800-53 Rev 5 | AU-6 Audit Record Review, Analysis, and Reporting | Scheduled review and escalation path |
| NIST 800-53 Rev 5 | AU-12 Audit Record Generation | Vendor-generated account security records |
| PCI DSS v4.0 | 10.2 / 10.4 | Access and change events recorded and reviewed |

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Stripe Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User provisioning and deprovisioning (SCIM) | [1.4](#14-configure-scim-provisioning-and-idp-role-mapping) |
| CC6.2 | Team roles | [2.1](#21-configure-team-roles) |
| CC6.6 | API key access policies | [3.4](#34-configure-api-key-access-policies) |
| CC6.7 | API key security | [3.1](#31-configure-api-key-security) |
| CC7.2 | Security history review | [4.1](#41-review-security-history) |

### PCI DSS v4.0 Mapping

| Requirement | Stripe Control | Guide Section |
|-------------|----------------|---------------|
| 7 | Team roles | [2.1](#21-configure-team-roles) |
| 7 | API key access policies | [3.4](#34-configure-api-key-access-policies) |
| 8 | Authentication | [1.1](#11-configure-saml-single-sign-on) |
| 10 | Security history review and export | [4.1](#41-review-security-history) |

---

## Appendix A: References

**Official Stripe Documentation:**
- [Security at Stripe](https://docs.stripe.com/security) -- 2FA guidance, security history, device and IP monitoring
- [Support Center](https://support.stripe.com/)
- [Start a team](https://docs.stripe.com/get-started/account/teams) -- inviting members, editing roles, notification preferences
- [Stripe user roles](https://docs.stripe.com/get-started/account/teams/roles) -- current role catalogue
- [Single sign-on (SSO) at Stripe](https://docs.stripe.com/get-started/account/sso) -- SAML, SCIM, JIT, SSO Role IDs
- [Single sign-on with a SAML identity provider](https://docs.stripe.com/get-started/account/sso/other) -- domain verification, IdP values, enforcement modes
- [Set up SCIM provisioning](https://docs.stripe.com/get-started/account/sso/scim) -- SCIM endpoint and API key, group-based roles
- [API Keys](https://docs.stripe.com/keys) -- key classes, rotation mechanics, access policies, sandboxes, agent keys
- [Set up two-party approvals](https://docs.stripe.com/account/approvals) -- approval rules, including those applied to agent-tagged keys
- [Activity logs](https://docs.stripe.com/activity-logs) -- programmatic access to security history (public preview)

**API & Developer Tools:**
- [API Reference](https://docs.stripe.com/api)
- [Stripe CLI](https://docs.stripe.com/stripe-cli)
- [Stripe SDKs](https://docs.stripe.com/sdks)
- [Stripe Terraform provider](https://docs.stripe.com/terraform) -- resources include `stripe_webhook_endpoint` and `stripe_v2_core_event_destination`
- [Receive Stripe events in your webhook endpoint](https://docs.stripe.com/webhooks) -- signature verification, IP allowlist, replay tolerance, secret rotation

**Compliance Frameworks:**
- PCI DSS Level 1 (Service Provider -- most stringent level), SOC 1 Type II, SOC 2 Type II, SOC 3 -- via [Security at Stripe](https://docs.stripe.com/security)
- EMVCo Level 1 & 2 (Stripe Terminal), PCI PA-DSS (Terminal)
- [Payments Security and Compliance Guide](https://stripe.com/guides/payments-security-and-compliance)

**Security Incidents:**
- (2024) Evolve Bank & Trust (a Stripe banking partner) was breached by LockBit ransomware. Customer data from Stripe and other fintechs may have been exposed, including names, SSNs, and bank account numbers. This was not a direct Stripe platform breach.
- (2024-2025) Web skimming campaign exploited legacy Stripe API endpoints to validate stolen credit card data across approximately 49 merchant sites. Stripe infrastructure was not compromised.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-09-24 | 0.3.0 | ai-drafted · ai-validated | Live validation pass (validate-hth-guide, Phases 4–6) and the addition of **ai-validated** to this guide's status set, which now reads **ai-drafted** + **ai-validated**: an AI agent exercised this guidance against a live Stripe console and the guidance survived that contact once corrected. No human practitioner has reviewed or applied it, so the guide claims no **ni-** status. **What was exercised:** the ClickOps paths of 7 of 11 controls (1.2, 2.1, 2.2, 3.1, 3.3, 3.4, 4.1) were walked on an unactivated test-mode (sandbox) account through a signed-in browser, corrected, and re-read after correction; those 7 ClickOps headings carry a mark. Settings that could lock out the account were observed, not changed: the two-step toggle was not flipped, no member was added, and no access policy was saved or attached. **What was not:** 1.1 beyond its wizard's first step and all of 1.4, because configuring SSO or SCIM on an account whose only member is its Super Administrator risks lockout and SCIM needs a live-mode account; 1.3, whose session lifetime is enforced at the IdP once SSO is Required, which this account could not reach (its Stripe-side Sessions page was read and the missing timeout setting corrected, but an independent audit of this run found that too thin for a mark and removed it); 3.2's secret-rotation step, because no webhook destination existed; 3.4's allowed-origin and denied-origin test; and no Code surface. The api packs ran only with a deliberately invalid key and against a local stand-in server, since the 1Password authorization needed to inject a real key timed out, and the new Terraform pack was validated and planned but never applied, so no Code heading carries a mark. **Corrections:** the Developers menu is live and lists API keys and Webhooks, so the claims that Workbench replaced it are gone; SSO is a tab whose setup wizard opens with a role-assignment choice and shows no plan gate; two-step authentication is one account-wide toggle on its own tab, with factors enrolled per user; 1.3's session-timeout setting does not exist, so the control now enforces session lifetime at the IdP and signs out stale sessions per user; the console role is IAM Admin, and Transfer Analyst and Tax Analyst are account-dependent; the standard secret key offered no Expire key, so revoke it with Rotate key and Expiration set to Now; access policies attach from each key's Manage access policy menu and can be the default for new keys; restricted-key creation starts with a purpose choice that includes agent keys; security history now has a public-preview Activity Logs API, which retires the old claim that no API-exportable audit log exists. **Automation:** every pack-less control (1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 3.4, 4.1) now carries an evidenced Automation verdict checked against Stripe's published OpenAPI specs; new `terraform/` pack for 3.2 on the official `stripe/stripe` 0.3.0 provider; the api packs exit non-zero on failure and keep the key out of the process list; 3.3 now passes only on an explicit 403, exits 3 (needs review) instead of passing when the key can read a probed resource, and runs at L1 as the guide states; 3.2 builds its request body with `--data-urlencode`, declares `mode: mutating`, and no longer prints the webhook signing secret; the Sigma rule no longer claims to see key changes. **Doc drift:** replaced the dead Team Management link, dropped the webhook-signatures link that now serves the webhooks page, pointed the SDKs link at the SDKs page, corrected the managed-API-key row, and added the Terraform provider, SCIM, approvals and Activity Logs references. | Claude Code (Opus 5.5) |
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass: add 1.4 SCIM provisioning, 3.4 API key access policies, and section 4 Logging & Monitoring (security history); make restricted keys baseline posture and correct Developers-menu navs to Workbench/apikeys; document key rotation mechanics, org keys, and sandboxes; expand webhook control with IP allowlist, replay tolerance, v1-scheme handling, and secret rotation; correct 2FA factor preference and role catalogue; annotate 1.3 session timeout as undocumented; retire the fabricated 3.2 Sigma pack and annotate the 3.1 Sigma pack's premise and delivery pipeline. Tier 3/4 sources not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO and API security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
