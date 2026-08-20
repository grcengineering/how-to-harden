---
layout: guide
title: "Klaviyo Hardening Guide"
vendor: "Klaviyo"
slug: "klaviyo"
tier: "4"
category: "Marketing"
description: "E-commerce marketing security for API keys, profile protection, and export controls"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Klaviyo is an e-commerce marketing platform managing customer data, email/SMS campaigns, and behavioral analytics. REST API with private/public API keys, webhooks, and e-commerce platform integrations access customer PII and purchase history. Compromised access enables customer database exfiltration or phishing through trusted sender domains.

### Intended Audience
- Security engineers managing marketing platforms
- Klaviyo administrators
- GRC professionals assessing e-commerce marketing compliance
- Third-party risk managers evaluating marketing integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Klaviyo security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require single sign-on with multi-factor authentication for all Klaviyo user access, centralizing login through your corporate identity provider — then close the two documented bypass paths around it: the SSO exemption list and trusted devices.

#### Rationale
**Why This Matters:**
- Centralizes Klaviyo authentication in your corporate IdP so MFA and conditional access apply to every login
- Local password logins bypass IdP controls and are prime targets for credential stuffing and phishing — the same class of vector behind Klaviyo's 2022 support-tool compromise
- SSO with central provisioning lets you deprovision departed staff in one place, eliminating orphaned accounts with standing access to customer data
- Klaviyo accounts hold customer PII, purchase history, and trusted sending domains; a single compromised login can expose the entire subscriber database
- Klaviyo's SSO enforcement ships with an **exemption list** that lets named users keep signing in with a password while "Require SSO" is on — an enforced-on-paper configuration can still carry password logins, so the exemption list is the audit-critical artifact, not the toggle

**Attack Prevented:** Credential theft, phishing, MFA bypass, account takeover, orphaned-account access

#### ClickOps Implementation

> **Changed default — MFA is already mandatory on paid accounts.** Klaviyo requires multi-factor authentication on paid accounts: it cannot be fully disabled unless SSO is enabled for the account. MFA remains optional on free accounts. Treat Step 1 as a verification-and-tightening step on a paid account rather than an enablement step. Supported methods are an **authenticator app** or **SMS** — Klaviyo does not document passkeys or hardware security keys for this surface. Source: [How to set up multi-factor authentication (MFA)](https://help.klaviyo.com/hc/en-us/articles/360026617692-How-to-set-up-multi-factor-authentication-MFA).

**Step 1: Enable and enforce MFA**
1. Navigate to: **Settings → Security → MFA Methods**
2. Click **Add method** and register an authenticator app (preferred) or SMS; prefer the authenticator app — SMS is subject to SIM-swap and interception
3. As the account **Owner**, enable **Require for all users in your organization** so enforcement covers every user rather than only the accounts that opted in
4. Confirm every active user has completed enrolment before assuming coverage

**Step 2: Configure SSO (paid plans)**
1. Navigate to: **Settings → Security → Set up SSO**
2. Configure your SAML identity provider. Klaviyo SSO is **IdP-initiated only** — users start the login from the identity provider, not from a Klaviyo login page
3. Select **Require SSO for all users** to block password-based sign-in
4. **Audit the exemption list.** Users placed on it continue to authenticate with a password while enforcement is on. Keep it empty, or restricted to a documented break-glass account whose credentials are vaulted and monitored
5. Source: [How to set up single sign-on (SSO)](https://help.klaviyo.com/hc/en-us/articles/9353860331035-How-to-set-up-single-sign-on-SSO)

**Step 3: Audit trusted devices**
1. Trusted devices suppress the MFA prompt on subsequent logins from that device — a persistence surface an attacker who reaches an authenticated session can plant deliberately
2. Review registered trusted devices for each user during access reviews and after any suspected compromise, and remove devices you cannot attribute
3. Source: [How to add trusted devices](https://help.klaviyo.com/hc/en-us/articles/360027783611-How-to-add-trusted-devices)

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign each Klaviyo user the least-privileged role required for their job, restricting account settings, campaign creation, and customer data access by function.

#### Rationale
**Why This Matters:**
- Limits the blast radius of a compromised account — an analyst credential cannot export the subscriber list or alter sending domains
- Reserves Owner and Admin rights for the few who genuinely need them, reducing the number of high-value targets an attacker can chase
- Quarterly access reviews catch privilege creep and stale accounts before they become an exploitable attack surface
- View-only and limited support roles keep customer PII away from users who only need campaign metrics

**Attack Prevented:** Privilege escalation, insider misuse, excessive data access, lateral movement after account takeover

#### ClickOps Implementation

**Step 1: Map users to Klaviyo's static roles**

Klaviyo ships **eight** static user roles. Assign the narrowest one that still lets the user do their job.

| Role | Typical use |
|------|-------------|
| Owner | Account owner — billing, security settings, SSO/MFA enforcement |
| Admin | Full account administration |
| Manager | Campaign and flow management |
| Analyst | Reporting and analytics |
| Campaign Coordinator | Campaign scheduling and execution |
| Content Creator | Template and content authoring |
| Support | Limited customer-facing access |
| Social Media Manager | Social/advertising surfaces |

Source: [User management and privileges reference for static user roles](https://help.klaviyo.com/hc/en-us/articles/115005231648-User-management-and-privileges-reference-for-Static-User-Roles)

**Step 2: Configure role assignments**
1. Navigate to: **Settings → Users**
2. Assign the least-privileged static role that covers the user's job
3. Review access quarterly, and immediately on role change or departure

**Step 3: Use custom roles where a static role over-grants**
1. Custom user roles are available on **all Klaviyo plans** — they are not an Enterprise-only capability, so there is no plan-tier excuse for leaving a user over-privileged
2. Build a custom role when the closest static role grants a capability the user does not need (for example, data export or account settings)
3. Source: [How to create a custom user role](https://help.klaviyo.com/hc/en-us/articles/40493034144795-How-to-create-a-custom-user-role)

---

### 1.3 Govern Organization-Level Roles

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2, AC-6

#### Description
Inventory and restrict the organization-tier roles that sit above individual Klaviyo accounts, so no more people than strictly necessary hold access that spans every linked account in the organization.

#### Rationale
**Why This Matters:**
- Organization roles are a privilege tier above the per-account roles most reviews look at: an **Org Super Admin** reaches every account linked to the organization, so a single compromised credential exposes every brand, region, or business unit at once
- Access reviews scoped to one account's user list miss organization-level grants entirely — the over-privileged user does not appear where auditors look
- **Org Analyst** and permission-set-based custom organization roles let you give portfolio-wide reporting visibility without portfolio-wide write access
- Organizations are usually created for convenience (shared reporting, consolidated billing) by people not thinking about blast radius, which is exactly when standing cross-account admin gets handed out

**Attack Prevented:** Cross-account lateral movement, portfolio-wide account takeover, unreviewed standing privilege, insider access to unrelated business units

#### ClickOps Implementation

**Step 1: Inventory organization-level access**
1. List every user holding an **Org Super Admin** role and confirm each one genuinely needs write access to *every* linked account
2. Record the organization role inventory separately from per-account user lists so it is not skipped during access review

**Step 2: Downgrade to the narrowest organization role**
1. Move portfolio-reporting users to **Org Analyst** rather than Org Super Admin
2. Where neither built-in role fits, build a custom organization role from permission sets granting only the capabilities required
3. Source: [Understanding user roles for organizations](https://help.klaviyo.com/hc/en-us/articles/53645875708955-Understanding-user-roles-for-organizations)

**Step 3: Review on the same cadence as account roles**
1. Re-review organization roles quarterly and on every departure or transfer
2. Treat any Org Super Admin who has not used the access in the review period as a candidate for removal

---

## 2. API Security

### 2.1 Secure API Keys

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Scope every Klaviyo private API key to the least access its integration needs, prefer OAuth for partner integrations, and audit for private keys leaking into client-side code.

#### Rationale
**Attack Scenario:** Private API key exposure enables full profile database export; customer PII and purchase history exfiltrated for fraud or targeted phishing.

**Why This Matters:**
- Private API keys grant full read/write access to every profile, list, and campaign — they are effectively root credentials for your customer data
- Keys hardcoded in client-side code, mobile apps, or committed to source control are trivially harvested by attackers and bots scanning public repositories
- Rotating keys and scoping them to specific integrations limits how long a leaked key stays useful and which systems it can reach
- Public keys are safe for client-side events, but confusing them with private keys is a common, high-impact misconfiguration

**Attack Prevented:** API key leakage, customer database exfiltration, unauthorized data export, credential harvesting from source control

#### Implementation

**API Key Types:**

| Key Type | Access Level | Exposure Risk |
|----------|--------------|---------------|
| Private API Key | Scoped read/write (see below) | High (never expose) |
| Public API Key | Limited (client events) | Low |

**Private key scopes:**

| Scope | Access granted |
|-------|----------------|
| Read-only | Read access across resources |
| Full Access | Read and write across every resource — **the default** |
| Custom | Per-resource read / write / no-access selection |

> **Changed default — new private keys are Full Access.** Klaviyo's key creation flow defaults to **Full Access**, so a key created without deliberate scoping is effectively root over your customer data. Choose **Read-only** or **Custom** explicitly. A key's scope is **immutable after creation**: narrowing an over-scoped key means creating a replacement and deleting the original, not editing it in place. Sources: [Klaviyo API overview](https://developers.klaviyo.com/en/reference/api-overview) · [How to create or clone a private API key](https://help.klaviyo.com/hc/en-us/articles/7423954176283-How-to-create-or-clone-a-private-API-key).

**Step 1: Scope keys at creation**
1. Navigate to: **Settings → API Keys**
2. Create one key per integration and set its scope to **Read-only** or **Custom** — never accept Full Access for an integration that only reads
3. Record the intended scope alongside the key's owner and purpose; since scope cannot be changed later, this record is what makes drift detectable

**Step 2: Rotate and replace**
1. Generate the replacement key with the correct scope
2. Update the integration to the new key
3. Delete the old key — deletion, not disablement, is the revocation path
4. Because scope is immutable, treat "this key is over-scoped" as a rotation trigger in its own right

**Step 3: Prefer OAuth for partner integrations**
1. For third-party and partner integrations, use Klaviyo's **OAuth** flow rather than issuing a private API key. OAuth is Klaviyo's recommended authentication method for integrations, and avoids handing a long-lived static credential to an external party
2. Reserve private keys for your own first-party automation
3. Source: [Klaviyo API overview](https://developers.klaviyo.com/en/reference/api-overview)

**Step 4: Audit for client-side leakage**
1. Private API keys are formatted as `pk_` followed by 34 alphanumeric characters — a distinctive, greppable pattern
2. Search your site's rendered page source, front-end bundles, and mobile app packages for `pk_`; any hit is an exposed private key requiring immediate deletion and replacement
3. Add the same pattern to your source-control secret scanning

---

### 2.2 Webhook Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-8

#### Description
Secure Klaviyo webhook endpoints with HTTPS, signature validation, and IP allowlisting so only authentic, untampered Klaviyo events are accepted and processed.

#### Rationale
**Why This Matters:**
- Webhooks carry customer event data and trigger downstream automation; an unauthenticated endpoint lets anyone forge events into your systems
- Validating webhook signatures proves each payload genuinely originated from Klaviyo and was not altered in transit
- HTTPS prevents interception or modification of event payloads that may contain customer identifiers
- IP allowlisting narrows the attack surface to Klaviyo's known source ranges, blocking spoofed or replayed requests

**Attack Prevented:** Webhook spoofing, payload tampering, replay attacks, man-in-the-middle interception, forged-event injection

#### Implementation

**Step 1: Secure Webhook Endpoints**
1. Use HTTPS only
2. Validate webhook signatures
3. Implement IP allowlisting

---

### 2.3 Harden MCP and AI-Agent Access

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3, AC-6, SI-10

#### Description
Constrain the Klaviyo MCP server so AI assistants connected to your account operate read-only, expose the smallest useful toolset, and cannot be steered by attacker-authored content sitting inside your own Klaviyo data.

#### Rationale
**Why This Matters:**
- Klaviyo publishes a remote MCP server at `mcp.klaviyo.com/mcp` that lets an AI client act against your account with the permissions of the authorizing user — an Owner, Admin, or Manager — which means an assistant can read and write real customer data, campaigns, and flows
- **Klaviyo does not restrict which AI clients may connect.** Any MCP-capable client that completes the OAuth flow, including dynamic client registration, is accepted; the control over what connects is yours to impose, not Klaviyo's
- Klaviyo data contains user-generated content — profile fields, form submissions, review text — that an attacker can author. When an assistant reads that content, it becomes indirect prompt injection: attacker text arriving as instructions inside a trusted tool result. Disabling tools that surface user-generated content is the direct mitigation
- An over-broad toolset multiplies what a compromised or manipulated assistant can reach; read-only mode removes write actions from the blast radius entirely

**Attack Prevented:** Indirect prompt injection via user-generated content, unauthorized AI-driven data export, unapproved AI client access, over-broad agent write actions

#### ClickOps Implementation

**Step 1: Decide whether MCP access is authorized at all**
1. Treat an AI assistant connected to Klaviyo as a non-human identity with a named human owner and a documented business purpose
2. Authorization is granted through the OAuth consent of an Owner, Admin, or Manager — so restrict who holds those roles (see [1.2](#12-role-based-access)) before worrying about client configuration

**Step 2: Configure the remote MCP server restrictively**
1. Set `read-only=true` so the assistant cannot write to campaigns, flows, profiles, or account settings
2. Set `core-tools-only=true` to expose the minimum tool surface rather than the full catalogue
3. Set `disable-tools-with-user-generated-content=true` — this is the indirect-prompt-injection control, and it is the setting to justify in writing if you choose to leave it off
4. Scope the available **toolsets** to only the product areas the assistant actually needs
5. Source: [Klaviyo MCP server](https://developers.klaviyo.com/en/docs/klaviyo_mcp_server)

**Step 3: Apply the equivalent limits to local MCP deployments**
1. For a locally run MCP server, set the environment variables `READ_ONLY` and `ALLOW_USER_GENERATED_CONTENT` to the restrictive values
2. Keep the private API key the local server uses scoped to read-only per [2.1](#21-secure-api-keys)

**Step 4: Audit agent activity**
1. Review **API Analytics / Logs** for the calls the assistant makes — MCP traffic is API traffic and appears there
2. Investigate volume spikes and read patterns consistent with bulk profile extraction
3. Source: [Klaviyo App for Claude FAQ](https://help.klaviyo.com/hc/en-us/articles/51798102561435-Frequently-Asked-Questions-About-Klaviyo-App-For-Claude)

---

## 3. Data Security

### 3.1 Profile Data Protection

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Minimize collected profile data, track consent, and restrict bulk exports so customer PII is limited in scope and tightly controlled both at rest and on export.

#### Rationale
**Why This Matters:**
- Collecting only the profile fields you actually use shrinks the volume of PII exposed if the account is breached
- Consent tracking and suppression-list management keep you compliant with privacy law and prevent messaging people who have opted out
- Restricting and auditing bulk exports stops a single compromised admin from quietly walking off with the entire subscriber database
- Data retention limits ensure stale customer records are purged rather than accumulating as long-term liability

**Attack Prevented:** Mass data exfiltration, unauthorized bulk export, privacy and consent violations, excessive PII retention

#### ClickOps Implementation

**Step 1: Configure Data Handling**
1. Limit profile data collection
2. Configure consent tracking
3. Enable suppression list management

**Step 2: Export Controls**
1. Restrict export permissions
2. Audit bulk exports
3. Configure data retention

---

### 3.2 Email Authentication

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SI-3

#### Description
Configure a dedicated sending domain with DKIM and SPF, then deploy DMARC and move toward an enforcement policy to authenticate all mail sent through Klaviyo.

#### Rationale
**Why This Matters:**
- DKIM and SPF let receiving servers verify that mail claiming to come from your domain was actually authorized, blocking spoofed senders
- DMARC enforcement tells inbox providers to reject or quarantine messages that fail authentication, protecting your customers from impersonation
- A trusted, authenticated sending domain is a high-value phishing target — without DMARC, attackers can spoof it to defraud your subscribers
- Monitoring authentication reports surfaces unauthorized senders abusing your domain before they damage deliverability and reputation

**Attack Prevented:** Email spoofing, domain impersonation, customer phishing, brand abuse, deliverability degradation

#### ClickOps Implementation

**Step 1: Configure Domain Authentication**
1. Navigate to: **Settings → Domains**
2. Configure dedicated sending domain
3. Set up DKIM/SPF records

**Step 2: Enable DMARC**
1. Configure DMARC policy
2. Monitor authentication reports
3. Move toward enforcement

---

## 4. Monitoring & Detection

### 4.1 Activity Monitoring

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Regularly review Klaviyo's Activity Logger to monitor edit actions taken inside the account, and plan around its documented limits — it is a beta feature that records edits, not logins.

#### Rationale
**Why This Matters:**
- Login and configuration logs are the primary signal for detecting account takeover, anomalous access, or insider misuse
- Reviewing changes to API keys, sending domains, and user roles catches malicious or accidental modifications before they cause harm
- An audit trail is required evidence for incident response, forensics, and compliance frameworks like SOC 2 and ISO 27001
- Without active monitoring, a compromised account — as in Klaviyo's 2022 incident — can exfiltrate data for an extended period undetected

**Attack Prevented:** Undetected account takeover, insider misuse, unauthorized configuration changes, delayed breach detection

#### ClickOps Implementation

> **Correction — the log lives elsewhere and records less than you may expect.** Klaviyo's log is the **Activity Logger**, reached at **Settings → Account → Activity Logger**, not *Settings → Activity log*. It is a **beta** feature, it records **edit actions only** — it is not a login or authentication log — and it is visible only to **Owners, Admins, and users whose role grants the Account Settings permission**. Source: [Understanding the activity logger (beta)](https://help.klaviyo.com/hc/en-us/articles/44579125790747-Understanding-the-activity-logger-beta).

**Step 1: Review edit activity**
1. Navigate to: **Settings → Account → Activity Logger**
2. Review edits to high-impact objects — API keys, sending domains, user roles, flows, and account settings
3. Confirm each change maps to a known, authorized request; investigate anything that does not

**Step 2: Confirm who can see the log**
1. Verify that the users responsible for security review actually hold Owner, Admin, or a role carrying the Account Settings permission — otherwise the log is invisible to the people meant to read it
2. Because the feature is in beta, re-check its behaviour and availability periodically rather than assuming it is stable

#### Detection Focus

- **Edits, not logins.** The Activity Logger captures edit actions; it does not provide login or failed-authentication history. Do not build an account-takeover detection that assumes Klaviyo supplies login events — the login-side signal has to come from your identity provider once SSO is enforced per [1.1](#11-enforce-sso-with-mfa)
- **High-value edit targets to review every pass:** private API key creation or deletion, sending-domain changes, user role grants (including organization roles per [1.3](#13-govern-organization-level-roles)), and SSO or MFA enforcement settings
- **Correlate with API Analytics / Logs** for programmatic activity — key-based and MCP-driven access shows up there rather than in the Activity Logger
- **Beta caveat:** treat coverage gaps as expected, and keep an independent record (IdP logs, downstream system logs) for anything you must be able to reconstruct during an incident

---

## Appendix A: Edition Compatibility

| Control | Free | Paid plans |
|---------|------|------------|
| SSO (SAML) | ❌ | ✅ |
| MFA | Optional | Required (unless SSO enabled) |
| Custom user roles | ✅ | ✅ |
| Activity Logger (beta) | ✅ | ✅ |

**Note:** SSO requires a **paid** Klaviyo plan — it is not restricted to an Enterprise tier. Custom user roles are available on **all** plans. Sources: [How to set up single sign-on (SSO)](https://help.klaviyo.com/hc/en-us/articles/9353860331035-How-to-set-up-single-sign-on-SSO) · [How to create a custom user role](https://help.klaviyo.com/hc/en-us/articles/40493034144795-How-to-create-a-custom-user-role) · [How to set up multi-factor authentication (MFA)](https://help.klaviyo.com/hc/en-us/articles/360026617692-How-to-set-up-multi-factor-authentication-MFA)

---

## Appendix B: References

**Official Klaviyo Documentation:**
- [How to keep your account secure](https://help.klaviyo.com/hc/en-us/articles/360052448451-How-to-keep-your-account-secure)
- [How to set up multi-factor authentication (MFA)](https://help.klaviyo.com/hc/en-us/articles/360026617692-How-to-set-up-multi-factor-authentication-MFA)
- [How to set up single sign-on (SSO)](https://help.klaviyo.com/hc/en-us/articles/9353860331035-How-to-set-up-single-sign-on-SSO)
- [How to add trusted devices](https://help.klaviyo.com/hc/en-us/articles/360027783611-How-to-add-trusted-devices)
- [User management and privileges reference for static user roles](https://help.klaviyo.com/hc/en-us/articles/115005231648-User-management-and-privileges-reference-for-Static-User-Roles)
- [How to create a custom user role](https://help.klaviyo.com/hc/en-us/articles/40493034144795-How-to-create-a-custom-user-role)
- [Understanding user roles for organizations](https://help.klaviyo.com/hc/en-us/articles/53645875708955-Understanding-user-roles-for-organizations)
- [Understanding the activity logger (beta)](https://help.klaviyo.com/hc/en-us/articles/44579125790747-Understanding-the-activity-logger-beta)
- [Klaviyo Help Center](https://help.klaviyo.com/hc/en-us)

**API & Developer Resources:**
- [Klaviyo API overview (authentication, key scopes, OAuth)](https://developers.klaviyo.com/en/reference/api-overview)
- [How to create or clone a private API key](https://help.klaviyo.com/hc/en-us/articles/7423954176283-How-to-create-or-clone-a-private-API-key)
- [Klaviyo MCP server](https://developers.klaviyo.com/en/docs/klaviyo_mcp_server)
- [Frequently asked questions about Klaviyo App for Claude](https://help.klaviyo.com/hc/en-us/articles/51798102561435-Frequently-Asked-Questions-About-Klaviyo-App-For-Claude)
- [Klaviyo Developer Portal](https://developers.klaviyo.com/en)
- [Klaviyo SDKs](https://developers.klaviyo.com/en/docs/sdk-overview)

**Compliance Frameworks:**
- Klaviyo publishes attestation and certification reports on request through Klaviyo support. Compliance-marketing pages are deliberately not cited here; request the reports directly and assess them yourself.

**Security Incidents:**
- **August 2022:** Klaviyo disclosed a phishing attack that compromised an employee's credentials, granting access to internal support tools. Attackers downloaded marketing lists for 38 cryptocurrency-related customer accounts. No passwords, payment data, or credit card numbers were exposed.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against help.klaviyo.com and developers.klaviyo.com. Added 2.3 MCP and AI-agent access hardening (remote server at mcp.klaviyo.com/mcp, Klaviyo does not restrict which AI clients connect, read-only / core-tools-only / disable-tools-with-user-generated-content as the indirect-prompt-injection control) and 1.3 organization-level roles (Org Super Admin reaches every linked account). Corrected 1.1 (MFA path is Settings → Security → MFA Methods with a "Require for all users in your organization" enforcement toggle; authenticator app or SMS only; SSO is IdP-initiated and requires a paid plan, not Enterprise; documented the SSO exemption list and trusted devices as bypass surfaces), 1.2 (eight static roles, custom roles on all plans), 2.1 (Read-only / Full Access / Custom key scopes with Full Access as the default and scope immutable after creation; OAuth preferred for partner integrations; pk_ leakage audit), and 4.1 (Activity Logger at Settings → Account → Activity Logger, beta, edit actions only, Owner/Admin/Account-Settings visibility) plus a populated Detection Focus. Rebuilt Appendix A around verified plan gates and removed Trust Center links from Appendix B. Tier 2: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline covers Klaviyo. Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Klaviyo hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
