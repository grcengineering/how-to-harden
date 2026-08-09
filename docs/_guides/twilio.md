---
layout: guide
title: "Twilio Hardening Guide"
vendor: "Twilio"
slug: "twilio"
tier: "2"
category: "Marketing"
description: "Cloud communications platform hardening for Twilio including SSO configuration, account security, and API key management"
version: "0.2.1"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Twilio is a leading cloud communications platform serving **millions of developers** for voice, messaging, and video communications. As a platform handling communication data and API access, Twilio security configurations directly impact data protection and communication integrity.

### Intended Audience
- Security engineers managing communications platforms
- IT administrators configuring Twilio
- Developers managing API access
- GRC professionals assessing communications security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Twilio Console and platform security including SSO and SCIM, the organization and account permission model, API key and OAuth app scoping, webhook and stored-media authentication, voice toll-fraud controls, and audit retention.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [API Security](#3-api-security)
4. [Fraud & Abuse Controls](#4-fraud--abuse-controls)
5. [Monitoring & Audit](#5-monitoring--audit)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO for Twilio Console access and enforce it across your verified email domain, so Console logins are authenticated by your IdP rather than by Twilio-local passwords.

#### Rationale
**Why This Matters:**
- Centralizes Twilio Console authentication in your corporate IdP, enforcing MFA, conditional access, and device posture on every login
- Local Console passwords bypass IdP controls and are a prime target for the credential phishing that has repeatedly compromised Twilio employee access
- Pairing SSO with SCIM provisioning and deprovisioning removes departed employees automatically, eliminating orphaned accounts that retain access to messaging and voice infrastructure — SSO alone does not, because Twilio does not support just-in-time provisioning
- A compromised Console login can send messages, place calls, drain account balance, and read communication logs across every subaccount

**Attack Prevented:** Credential phishing, password reuse, MFA bypass, orphaned-account access

#### Prerequisites
- Administrative access to the Twilio Console
- A SAML 2.0 compatible IdP
- An email domain you can verify with Twilio (enforcement is keyed to the domain, not to individual accounts)

**No edition gate.** Single sign-on is available to customers on **all Twilio Editions** — it is not reserved for Enterprise. Do not defer this control on the assumption that it requires an upgrade.

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. In the Twilio Console, navigate to: **Admin Center** → **Users**
2. Begin the single sign-on configuration

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Download Twilio metadata for IdP

**Step 3: Verify Your Email Domain and Enforce**
1. Enforcement is applied **by verified email domain**: once SSO is enforced for a domain, all managed users on that domain authenticate through your IdP
2. Complete Twilio's domain verification before enforcing — an unverified domain cannot be enforced
3. Per-user control is available as a toggle, so an individual managed user can be exempted where a genuine operational need exists. Treat every exemption as a standing password-login exception and review the list periodically
4. Test SSO authentication with a real user before flipping enforcement on for the domain

**Step 4: Provision and Deprovision via SCIM**
1. **Just-in-time (JIT) provisioning is not supported.** A user who authenticates successfully at your IdP is not created in Twilio as a side effect of logging in — do not design your onboarding around it
2. Use the SCIM API to provision and deprovision users, so IdP account creation and removal drive Twilio access
3. Without SCIM, deprovisioning is a manual step, and a departed employee's Twilio user record can outlive their IdP account

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Twilio Console users.

#### Rationale
**Why This Matters:**
- A second factor blocks attackers who have already obtained a valid Console password through phishing, credential reuse, or a third-party breach
- Twilio accounts control outbound messaging, voice, and spend, making single-factor logins a high-value target for account takeover
- Hardware security keys for administrators resist the real-time phishing proxies that intercept SMS and push-based codes
- Without enforced 2FA, a single leaked credential grants full control of communication channels and customer contact data

**Attack Prevented:** Credential stuffing, phishing, account takeover, password reuse

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Account** → **Security**
2. Require two-factor authentication
3. All users must configure 2FA

**Step 2: Configure Methods**
1. Support authenticator apps
2. Support Authy
3. Use hardware keys for admins

---

## 2. Access Controls

### 2.1 Configure User Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Twilio's role-based access control, assigning each user the narrowest role that lets them do their job.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure each user can perform only the actions their job requires, shrinking the blast radius of any compromised account
- Over-provisioned Administrator and Owner roles let a single phished user change security settings, rotate credentials, or exfiltrate data
- Scoped roles such as Developer, Billing, and Support separate duties so no single identity holds both operational and financial control
- Regular access reviews catch privilege creep and stale grants before they become an attack path

**Attack Prevented:** Privilege escalation, lateral movement, insider misuse, excessive-permission abuse

#### ClickOps Implementation

**Step 1: Review User Access**
1. Navigate to: **Account settings** → **User management** → **User access**
2. **The legacy per-account role list has been replaced.** If you are working from older guidance that describes a fixed Owner / Administrator / Developer / Billing / Support list applied per account, that model no longer reflects the Console — review the current role assignments in User access instead
3. Review who holds which role today, and note that role assignments are made at the **organization level**

**Step 2: Understand How Role Scope Cascades**
1. A role assignment applies down a hierarchy: **organization → product → subaccount**
2. This means a broadly scoped organization-level grant reaches every product and every subaccount beneath it — scoping a role at the organization level is not equivalent to scoping it at one account
3. Assign roles at the narrowest level in that hierarchy that satisfies the user's job, rather than granting at the organization level for convenience

**Step 3: Apply Least Privilege**
1. Assign the minimum necessary role for each user
2. Limit the number of users holding administrative roles
3. Review access on a regular cadence and remove grants that are no longer justified

---

### 2.2 Configure Subaccounts

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Use subaccounts for isolation.

#### Rationale
**Why This Matters:**
- Subaccounts isolate production, development, and per-application workloads so a breach in one cannot reach the credentials or data of another
- Separate subaccount credentials contain a leaked key to a single environment instead of the whole organization's messaging and voice capacity
- Isolation bounds financial damage, since fraud or abuse is limited to one subaccount's resources and spend
- Per-subaccount activity monitoring makes anomalous usage easier to detect and attribute

**Attack Prevented:** Blast-radius expansion, cross-environment compromise, credential reuse, toll fraud

#### ClickOps Implementation

**Step 1: Create Subaccounts**
1. Separate production and development
2. Create per-application subaccounts
3. Limit cross-account access

**Step 2: Configure Access**
1. Grant minimum permissions
2. Use separate credentials
3. Monitor subaccount activity

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
- Owner and Administrator accounts can alter security settings, manage users, and reach every subaccount, making them the highest-value targets in the account
- Keeping the owner population to a small, known set reduces the number of credentials an attacker can phish to gain full control
- Requiring strong MFA on every admin closes the most direct path to a total account takeover
- Monitoring admin activity surfaces unauthorized configuration changes and credential abuse early

**Attack Prevented:** Account takeover, privilege abuse, unauthorized configuration change, insider threat

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review owner/admin accounts
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit owners to 2-3 users
2. Require 2FA for admins
3. Monitor admin activity

---

### 2.4 Govern the Twilio Organization Layer

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.4 |
| NIST 800-53 | AC-2, AC-6 |

#### Description
Treat the Twilio Organization — the container that sits above your Twilio accounts — as its own privileged administrative tier, and manage the small set of organization roles deliberately rather than inheriting whoever happened to create the account.

#### Rationale
**Why This Matters:**
- The Organization is a container above individual Twilio accounts, so an organization-level grant is the broadest privilege in the tenancy and reaches further than any single account's administrator
- Organization roles carry distinct powers that are easy to over-assign — the ability to create new accounts, for instance, expands the estate an attacker or a careless user can reach, and it is a role in its own right
- Billing authority is separated into its own roles at this layer, which lets you give finance the visibility it needs without handing over operational control of messaging and voice
- Because organization roles cascade downward, an unreviewed organization membership list quietly undermines every carefully scoped account-level and subaccount-level permission below it

**Attack Prevented:** Privilege escalation through an unmonitored administrative tier, unauthorized account creation, excessive blast radius, insider misuse of billing authority

#### ClickOps Implementation

**Step 1: Inventory Organization Membership**
1. Open the managed-users console for your organization
2. List every user who holds an organization-level role — this is a different and broader population than your per-account administrators

**Step 2: Assign the Narrowest Organization Role**
1. Twilio documents these organization roles:
   - **Owner**
   - **Administrator**
   - **Standard User (Account Creation)** — grants the ability to create accounts
   - **Organization Billing Administrator**
   - **Organization Billing Viewer**
2. Give finance and audit staff **Organization Billing Viewer** rather than an administrative role when read-only billing visibility is all they need
3. Grant **Standard User (Account Creation)** only to people who genuinely need to create accounts, since new accounts widen the estate that must be secured and monitored
4. Keep **Owner** and **Administrator** to the smallest workable set

**Step 3: Review on a Cadence**
1. Re-review organization membership on the same schedule as your account-level access reviews, and remove grants that are no longer justified
2. Confirm that anyone removed from your IdP has also lost their organization role, since organization membership is not automatically cleaned up by an IdP change

---

## 3. API Security

### 3.1 Configure API Key Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Authenticate integrations with scoped Twilio API Keys rather than the Account SID and Auth Token, choosing the narrowest key type the integration can work with.

#### Rationale
**Why This Matters:**
- API Keys can be revoked individually, unlike the Account SID and Auth Token whose exposure compromises the entire account
- Hardcoded or client-side credentials are routinely scraped from repositories, mobile apps, and logs, then abused to send messages and place calls at the victim's expense
- Regular rotation limits how long a leaked key remains useful to an attacker
- Storing keys in a secret vault and injecting them through environment variables keeps them out of source control and build artifacts

**Attack Prevented:** Credential leakage, toll fraud, unauthorized API use, account-wide compromise

#### ClickOps Implementation

**Step 1: Review API Keys**
1. Navigate to: **Settings** → **Account settings** → **API keys & auth tokens**
2. Select the region first — the API keys page is region-scoped, and keys created in one region are not the keys you see in another
3. Review all API keys and document each key's purpose

**Step 2: Choose the Narrowest Key Type**
1. Twilio offers three key types, and they are not equivalent:
   - **Restricted** — permissions are scoped per resource. **This is the least-privilege option and the one to reach for.** Note the current constraint: Restricted API Keys are available in the US region only
   - **Standard** — access to all resources on the account **except** Accounts and Keys. Broader than most integrations need; it is a limit on account and key management, not a least-privilege grant
   - **Main** — full access, functionally equivalent to holding the Account SID and Auth Token. Treat a Main key as the account's master credential
2. Do not treat Standard as "the secure one." If your workload runs in the US region, a Restricted key scoped to the specific resources the integration touches is the correct choice
3. Where a Restricted key is not available for your region, a Standard key is the fallback — but compensate with tighter rotation, dedicated subaccounts, and monitoring, and record the exception

**Step 3: Rotate and Retire**
1. Create keys with the minimum permissions the integration needs
2. Rotate keys on a schedule, creating the replacement before deleting the old key
3. Delete keys whose owning integration is gone

**Step 4: Secure Credentials**
1. Never expose in client-side code
2. Store in secure vault
3. Use environment variables

#### Code Implementation

{% include pack-code.html vendor="twilio" section="3.1" %}

---

### 3.2 Configure Webhook Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-8 |

#### Description
Secure webhook callbacks.

#### Rationale
**Why This Matters:**
- Validating the X-Twilio-Signature header proves a callback genuinely originated from Twilio and was not forged by an attacker
- Unverified webhook endpoints let attackers inject fake events to trigger application logic, manipulate state, or exhaust resources
- HTTPS-only endpoints prevent interception and tampering of message and call metadata in transit
- IP allowlisting and anomaly monitoring add defense in depth against spoofed and replayed requests

**Attack Prevented:** Webhook forgery, request spoofing, man-in-the-middle interception, replay attacks

#### ClickOps Implementation

**Step 1: Validate Requests**
1. Always validate webhook signatures
2. Verify the `X-Twilio-Signature` header on every inbound request
3. Reject unverified requests
4. **If your webhook receives JSON rather than form-encoded parameters**, signature validation alone is not sufficient — the request body is not covered the same way. Validate the `bodySHA256` value as part of signature verification, using your primary Auth Token as the key. Skipping this leaves a JSON webhook accepting bodies that were never signed

**Step 2: Secure Endpoints**
1. Use HTTPS only, and enable **SSL Certificate Validation** for your webhooks so Twilio verifies your endpoint's certificate before delivering. Your endpoint must present a certificate from a recognized authority — **self-signed certificates are not accepted** once validation is on
2. **Never pin Twilio's certificates.** Twilio rotates its certificates without prior notice, so a pinned client breaks without warning at rotation time. Validate against the trust store instead
3. Implement IP allowlisting where you can enumerate the sources. Be aware that Twilio's outbound webhook addresses are not a small static set you can safely guess at — the supported way to get a stable, allowlistable egress address is the **Static Proxy for Webhooks**, which is gated to the **Security and Enterprise Editions**. On other editions, treat signature validation, not IP allowlisting, as your primary authenticity control
4. Monitor for anomalies in webhook delivery and failures

#### Code Implementation

{% include pack-code.html vendor="twilio" section="3.2" %}

---

### 3.3 Enable Public Key Client Validation

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11, 6.5 |
| NIST 800-53 | IA-5, SC-12, SC-23 |

#### Description
For accounts on the editions that offer it, enable Public Key Client Validation so API requests are authenticated with an RSA key pair and a signed JWT rather than a shared secret alone.

#### Rationale
**Why This Matters:**
- Shared-secret authentication means anyone who obtains the secret can replay it from anywhere; a request signed with a private key that never leaves your infrastructure cannot be forged from a leaked value in a log or repository
- Signing each request with a JWT ties the request itself to the credential, which raises the bar well above possession of a static token
- The validation requirement is enforced in the Twilio Console rather than only in your client code, so it is a control the account owner can assert centrally instead of trusting every integration to opt in
- This is a defense-in-depth layer on top of scoped API Keys, not a replacement for them — it hardens how requests are proven authentic, while key scoping limits what an authenticated request may do

**Attack Prevented:** Credential replay from leaked secrets, request forgery, unauthorized API use with harvested tokens

#### Prerequisites
- **Edition gate:** Public Key Client Validation is available on the **Enterprise and Security Editions**. Accounts on other editions cannot enable it — treat scoped Restricted API Keys plus rotation as the control in that case
- **SDK constraint:** among Twilio's helper libraries, support is documented for the **Java SDK only**. If your integration is written in another language, you will be implementing the signing yourself against the documented scheme rather than getting it from a helper library. Confirm this before committing to the control
- Ability to generate and protect an RSA key pair

#### ClickOps Implementation

**Step 1: Confirm You Are Eligible**
1. Verify your account is on the Enterprise or Security Edition
2. Confirm the integrations you intend to protect are Java-based, or accept that you will implement request signing directly

**Step 2: Generate and Register a Key Pair**
1. Generate an RSA key pair, keeping the private key in a secret manager or HSM and never in source control
2. Register the public key with Twilio, so Twilio can verify requests signed by the corresponding private key

**Step 3: Enforce in the Console**
1. Turn on the validation requirement in the Console for the account, so requests are checked centrally
2. Roll this out to one integration first and confirm signed requests succeed before enforcing account-wide, since an unmigrated integration will begin failing

---

### 3.4 Use OAuth Apps for Third-Party API Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-6, IA-2, IA-5 |

#### Description
Where a third party or an internal service needs API access, use a Twilio OAuth App and restrict what its tokens can reach, rather than handing out a long-lived Auth Token or a broadly scoped API Key.

#### Rationale
**Why This Matters:**
- An OAuth App issues tokens whose API access is restricted, so a third-party integration holds a credential bounded to what it was granted rather than a general-purpose account credential
- OAuth Apps exist at both the account and the organization level, which lets you decide whether an integration's reach stops at one account or spans the organization — a decision worth making deliberately rather than by default
- Handing a partner an Auth Token gives them the account's master credential with no way to scope it; an OAuth App is the documented alternative for that scenario
- Restricting access at the token level means a compromised integration exposes only the surface that token was permitted, limiting blast radius in the same way a Restricted API Key does for your own services

**Attack Prevented:** Over-scoped third-party access, master-credential sharing, excessive blast radius from a compromised integration

#### ClickOps Implementation

**Step 1: Decide the Level**
1. Determine whether the integration needs access to a single account or across the organization — OAuth Apps are available at **both the account level and the organization level**
2. Choose the account level unless the integration genuinely requires organization-wide reach

**Step 2: Create the App and Restrict Its Token Access**
1. Create the OAuth App at the chosen level
2. Restrict the API access available to the app's tokens to the narrowest set the integration needs

**Step 3: Track What Exists**
1. Keep an inventory of which OAuth Apps exist, at which level, who owns each one, and what it is permitted to reach
2. **Scope note:** Twilio's OAuth Apps overview documents the existence of account-level and organization-level apps and the ability to restrict token API access. It does **not** document an end-user authorization flow, a token revocation procedure, or a redirect-URI allowlist. Do not assume those controls are available or configured — verify against current Twilio documentation for your account before designing an offboarding or incident-response procedure that depends on them

---

### 3.5 Require Authentication on Stored Media

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, SC-8 |

#### Description
Enable HTTP Basic Authentication on media stored with Twilio, so recorded calls, MMS attachments, and WhatsApp media cannot be retrieved by anyone who simply holds or guesses the URL.

#### Rationale
**Why This Matters:**
- Media that Twilio stores on your behalf — MMS attachments, WhatsApp media, and voice recordings — is otherwise publicly addressable, meaning the URL alone is enough to retrieve the content
- Media URLs leak the way all URLs leak: through logs, analytics, browser history, support tickets, screenshots, and referrer headers. Every one of those becomes a data-exposure path when the URL is the only thing protecting the content
- Call recordings and message attachments are among the most sensitive data a communications platform holds, frequently containing personal information, account details, or material captured under a recording consent notice
- Twilio identifies enabling HTTP Basic Authentication on stored media as an industry best practice, so leaving it off is a documented deviation, not a neutral default

**Attack Prevented:** Unauthorized retrieval of recordings and attachments, URL-leak data exposure, enumeration of stored media

#### ClickOps Implementation

**Step 1: Inventory What You Store**
1. Identify whether your account stores MMS attachments, WhatsApp media, or voice recordings
2. Treat all three as in scope — the exposure is the same regardless of which product produced the media

**Step 2: Enable HTTP Basic Authentication on Media**
1. Turn on HTTP Basic Authentication for stored media on the account, so retrieval requires credentials rather than only the URL
2. Do this before, not after, you begin recording at volume — media created while the setting was off remains as exposed as it was when created

**Step 3: Update Retrieval Paths**
1. Update every downstream system that fetches media so it supplies credentials on retrieval
2. Confirm that an unauthenticated request for a known media URL is now rejected — this is the test that proves the control is live
3. Review whether you need to retain the media at all: media you have deleted cannot be retrieved by anyone

---

## 4. Fraud & Abuse Controls

### 4.1 Restrict Voice Dialing Geographic Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8, 13.4 |
| NIST 800-53 | AC-3, AC-4, SC-7 |

#### Description
Restrict which countries and number ranges your Twilio account is permitted to dial, so a compromised credential or an abused application cannot place calls to the high-cost destinations that toll fraud depends on.

#### Rationale
**Why This Matters:**
- Voice dialing geographic permissions are enforced per country, so an account can be limited to the destinations it actually does business with instead of the entire world's dial plan
- International Revenue Share Fraud works by driving calls to expensive destinations and number ranges that pay the fraudster a share of the termination charge — the attacker's payoff comes from the call itself, which is why a stolen Twilio credential is monetized as call volume rather than as data
- Twilio maintains separate categories for **High-Risk Special Numbers** and **High-Risk Tollfraud Numbers**, letting you block the specific ranges associated with fraud even within countries you legitimately need to call
- Twilio states these high-risk number sets are **updated frequently**, so this is not a set-and-forget control — the value comes from leaving the restrictions enabled so you inherit the updates, rather than carving permanent exceptions
- Financial loss from toll fraud accrues in hours, and unlike a data breach it is bounded only by your account's spend and the attacker's dialing rate

**Attack Prevented:** International Revenue Share Fraud (IRSF), toll fraud, unauthorized international dialing, spend exhaustion via a compromised credential

#### Implementation

**Step 1: Determine Which Countries You Actually Need**
1. Establish the list of countries your application legitimately places voice calls to
2. Everything outside that list is a candidate for denial — the goal is an allowlist shaped by your business, not a blocklist chasing known-bad destinations

**Step 2: Set Permissions per Country and Block High-Risk Ranges**
1. Voice dialing geographic permissions are configured per country
2. Within a permitted country, keep the **High-Risk Special Numbers** and **High-Risk Tollfraud Numbers** categories blocked unless you have a specific, documented reason to allow them. These categories exist precisely because a country can be legitimate while particular ranges inside it are not
3. Because Twilio updates these high-risk sets frequently, leaving the categories blocked is what keeps you current — an exception granted once persists until someone removes it

**Step 3: Decide Subaccount Inheritance Deliberately**
1. Twilio exposes a `dialing_permissions_inheritance` setting that governs whether subaccounts inherit the parent account's dialing permissions
2. Decide this explicitly. Inheritance on means a subaccount cannot quietly widen its own dial plan; inheritance off means each subaccount's permissions must be configured and reviewed independently
3. If you use subaccounts for isolation (see [2.2](#22-configure-subaccounts)), confirm that isolation extends to dialing permissions rather than assuming it does

**Automation note:** Twilio documents this control through the Voice `DialingPermissions` Country and Settings API resources. This guide does not assert a Console path for it — configure and audit it through the documented API, and verify the current Console surface against Twilio's documentation before writing a runbook that depends on one.

#### Code Implementation

{% include pack-code.html vendor="twilio" section="4.1" %}

---

## 5. Monitoring & Audit

### 5.1 Extend Audit Log Retention with Advanced Audit Insights

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.1, 8.10 |
| NIST 800-53 | AU-4, AU-6, AU-11 |

#### Description
Where your Twilio Edition provides it, enable Advanced Audit Insights to extend audit event retention well beyond the standard window, so investigations are not limited by logs that have already aged out.

#### Rationale
**Why This Matters:**
- The standard audit retention window is **30 days**, which is shorter than the time it typically takes to discover a compromise — by the time an incident surfaces, the events that would explain it may already be gone
- Advanced Audit Insights extends retention to **400 days**, which covers a full year plus the lag between an event and its discovery, and aligns with the annual look-back that most audit and compliance programs assume
- Audit events are what let you answer who changed a security setting, who created or deleted an API key, and who altered user access — the exact questions an incident response asks first
- Retention is the one property of a log you cannot fix retroactively: a 30-day window means a 90-day-old question is permanently unanswerable, regardless of how good your tooling becomes later

**Attack Prevented:** Undetected configuration tampering, unattributable privilege changes, loss of incident-response evidence, audit gaps

#### Prerequisites
- **Edition gate:** Advanced Audit Insights is gated by Twilio Edition. Confirm your account's edition against Twilio's Editions documentation before planning around it — if your edition does not include it, your effective retention is the standard 30 days and you must export events to your own store to keep them longer

#### Implementation

**Step 1: Confirm Your Edition and Current Retention**
1. Check which Twilio Edition your account is on and whether Advanced Audit Insights is included
2. Establish what your retention is today — assume the 30-day standard window unless you have confirmed otherwise

**Step 2: Enable Extended Retention or Compensate**
1. Where the feature is available on your edition, enable it to move retention from 30 days to 400 days
2. Where it is not, treat the 30-day window as a hard constraint and pull audit events into your own SIEM or log store on a schedule short enough that nothing ages out before it is captured

**Step 3: Match Retention to Your Obligations**
1. Compare the retention you now have against your regulatory and contractual log-retention requirements
2. Document the gap, if any, and the compensating export that closes it

---

### 5.2 Automate Bulk Export of Communication Records

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.9 |
| NIST 800-53 | AU-4, AU-6, AU-7 |

#### Description
Where your Twilio Edition provides it, use Bulk Export Automation to move message and call records out of Twilio on a schedule, into a store you control and can analyze.

#### Rationale
**Why This Matters:**
- Records that live only in Twilio are subject to Twilio's retention and Twilio's query surface; records exported into your own store can be retained on your terms and correlated with the rest of your telemetry
- Automated scheduled export removes the failure mode that kills manual exports, which is that nobody runs them during the weeks that later turn out to matter
- Correlating communication records with identity and infrastructure logs in a SIEM is what surfaces the patterns a single-platform view misses, such as a spike in outbound calls that coincides with an unfamiliar login
- If an account is compromised or an integration is disabled, an independent copy of the records is what lets an investigation proceed without depending on continued access to the compromised platform

**Attack Prevented:** Monitoring blind spots, evidence loss on account compromise, undetected anomalous send and call volume

#### Prerequisites
- **Edition gate:** Bulk Export Automation is gated by Twilio Edition. Confirm availability for your account against Twilio's Editions documentation before designing a pipeline around it

#### Implementation

**Step 1: Confirm Availability**
1. Check whether Bulk Export Automation is included in your account's Twilio Edition
2. If it is not, plan a scheduled pull through the API into your own store instead, and size the schedule to your retention window

**Step 2: Configure Scheduled Export**
1. Configure the export to run on a recurring schedule rather than on request
2. Send the output to a store you control, with access controls and retention that meet your own requirements — not to a location that is itself only reachable with the credentials you are trying to protect

**Step 3: Use the Data**
1. Ingest the exported records into your SIEM or analytics platform
2. Build alerting on the anomalies that matter for a communications platform: unusual outbound volume, unexpected destination countries, and spend spikes
3. Confirm the export is still running on its schedule as part of periodic review — a silently failed export is indistinguishable from a quiet month until you need the data

---

## 6. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Twilio Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User roles | [2.1](#21-configure-user-roles) |
| CC6.3 | Organization role governance | [2.4](#24-govern-the-twilio-organization-layer) |
| CC6.6 | Webhook and media authentication | [3.2](#32-configure-webhook-security), [3.5](#35-require-authentication-on-stored-media) |
| CC6.7 | API key security | [3.1](#31-configure-api-key-security) |
| CC7.2 | Audit retention and record export | [5.1](#51-extend-audit-log-retention-with-advanced-audit-insights), [5.2](#52-automate-bulk-export-of-communication-records) |

### NIST 800-53 Rev 5 Mapping

| Control | Twilio Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-2 | Organization membership | [2.4](#24-govern-the-twilio-organization-layer) |
| AC-6 | User roles | [2.1](#21-configure-user-roles) |
| AC-4 | Voice dialing geographic permissions | [4.1](#41-restrict-voice-dialing-geographic-permissions) |
| SC-12 | API key security | [3.1](#31-configure-api-key-security) |
| SC-23 | Public Key Client Validation | [3.3](#33-enable-public-key-client-validation) |
| AU-11 | Audit log retention | [5.1](#51-extend-audit-log-retention-with-advanced-audit-insights) |

---

## Appendix A: References

**Official Twilio Documentation:**
- [Twilio Docs](https://www.twilio.com/docs)
- [Security Best Practices](https://www.twilio.com/docs/usage/security)
- [Single Sign-On](https://www.twilio.com/docs/iam/single-sign-on)
- [Access Control Overview](https://www.twilio.com/docs/iam/access-control/overview)
- [Twilio Organizations](https://www.twilio.com/docs/iam/organizations)
- [API Keys](https://www.twilio.com/docs/iam/api-keys)
- [API Keys in the Console](https://www.twilio.com/docs/iam/api-keys/keys-in-console)
- [OAuth Apps Overview](https://www.twilio.com/docs/iam/oauth-apps/overview)
- [Public Key Client Validation Quickstart](https://www.twilio.com/docs/iam/pkcv/quickstart)
- [Twilio Editions](https://www.twilio.com/docs/iam/twilio-editions)
- [Voice Dialing Permissions: Country Resource](https://www.twilio.com/docs/voice/api/dialingpermissions-country-resource)
- [Voice Dialing Permissions: Settings Resource](https://www.twilio.com/docs/voice/api/dialingpermissions-settings-resource)

**API & Developer Tools:**
- [API Reference](https://www.twilio.com/docs/usage/api)
- [Twilio CLI](https://www.twilio.com/docs/twilio-cli)
- [Helper Libraries / SDKs](https://www.twilio.com/docs/libraries) (Node.js, Python, Java, C#, PHP, Ruby, Go)

**Compliance Frameworks:**
- [ISO/IEC Certification Details](https://www.twilio.com/docs/usage/security/iso-iec-certification)

**Security Incidents:**
- (2022-06) Voice phishing attack on a Twilio employee led to unauthorized access to customer contact information. Part of the broader "0ktapus" campaign.
- (2022-08) SMS phishing ("smishing") campaign targeted Twilio employees, compromising credentials and accessing data for 209 customers and 93 Authy end users. Also part of the "0ktapus" campaign affecting 130+ organizations.
- (2024-07) Unauthenticated Authy API endpoint exploited to enumerate 33 million phone numbers linked to Authy accounts. Disclosed after threat actor ShinyHunters posted the data on a dark web forum.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Add first Code Packs: 3.1 API key lifecycle via first-party Twilio CLI (`twilio api:iam:v1:keys` list/create restricted with policy/update/remove, verified against the Keys v1 resource reference), 3.2 webhook signature validation via the Node.js helper library (`validateRequest` + `validateRequestWithBody` with bodySHA256, verified against the webhook security docs), 4.1 voice geographic permissions audit and subaccount inheritance enforcement via the Voice v1 REST API (DialingPermissions Countries high-risk filters + Settings `DialingPermissionsInheritance`, verified against both resource references). All commands/endpoints fetch-verified this session; pack yml keys pending central sync | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | draft | Currency and scope pass against Twilio IAM/Voice/Usage docs. The guide was materially under-scoped for a CPaaS — it covered Console identity and API keys but not the organization tier, toll fraud, or audit retention, which are the surfaces that actually carry loss for a communications platform. Corrections: SSO is available on all Twilio Editions (not Enterprise-only), configured at Admin Center > Users, enforced by verified email domain, with no JIT provisioning and SCIM for lifecycle (1.1); least privilege means Restricted API keys, not Standard, at Settings > Account settings > API keys & auth tokens (3.1); the legacy fixed role list is replaced by RBAC at Account settings > User management > User access with org-to-subaccount scope cascade (2.1). Added: Twilio Organizations governance (2.4), Public Key Client Validation (3.3), OAuth Apps (3.4), stored-media authentication (3.5), Fraud & Abuse Controls section with voice dialing geographic permissions and IRSF high-risk ranges (4.1), Monitoring & Audit section with Advanced Audit Insights 30-to-400-day retention and Bulk Export Automation (5.1, 5.2). Expanded 3.2 with certificate non-pinning, SSL certificate validation, JSON bodySHA256 signature validation, and the Static Proxy edition gate. Replaced the dead /docs/iam/sso link, removed five trust-center and marketing references, and renumbered Compliance Quick Reference to section 6 to make room; no control was renumbered. Tier 2 (CIS/DISA/CISA SCuBA) confirmed zero applicable baselines for Twilio; Tier 3/4 sourcing blocked, so the three Appendix A incident entries carry over unverified | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and API security | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
