---
layout: guide
title: "BambooHR Hardening Guide"
vendor: "BambooHR"
slug: "bamboohr"
tier: "5"
category: "HR/Finance"
description: "HR platform security for OAuth integrations, API keys, access levels, webhooks, and sensitive field protection"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

BambooHR is a cloud-based HR platform managing employee records, benefits, and performance data. REST API, webhook integrations, and third-party app marketplace access sensitive employee PII. Compromised access exposes SSN, compensation data, and performance reviews.

### Intended Audience
- Security engineers managing HR systems
- BambooHR administrators
- GRC professionals assessing HR compliance
- Third-party risk managers evaluating HRIS integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers BambooHR security configurations including authentication, access controls, API and webhook integration security, and sensitive-field protection.

> **Console path note:** BambooHR's help center (`help.bamboohr.com`) is a Salesforce single-page application that returns an identical page shell for every path — including article IDs that do not exist — so the existence of a given help article cannot be confirmed by HTTP status or response size. The **Settings →** console paths in Sections 1–4 and the edition names in Appendix A reflect the last verification against the product and are not re-verifiable against the help center as of 2026-08. Confirm the exact menu labels in your own tenant. Statements sourced from `documentation.bamboohr.com` (BambooHR's developer documentation) are directly fetch-verified and are cited inline.

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
Require SAML single sign-on with multi-factor authentication for all BambooHR access, routing every login through your corporate identity provider.

#### Rationale
**Why This Matters:**
- Centralizes BambooHR authentication in your corporate IdP, enforcing MFA, conditional access, and session policy on every login
- Standalone BambooHR passwords bypass IdP controls and are prime targets for credential stuffing, phishing, and password reuse
- SSO lets you deprovision a departing employee once in the IdP rather than chasing every SaaS account, closing orphaned-access gaps
- BambooHR stores SSNs, compensation, bank details, and performance reviews, so a single compromised login can expose the entire HR record set

**Attack Prevented:** Credential theft, phishing, MFA bypass, password reuse, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Settings → Security → Single Sign-On**
2. Configure SAML IdP
3. Enable SSO requirement

**Step 2: Enable 2FA**
1. Navigate to: **Settings → Security**
2. Enable: **Require 2FA**
3. Configure backup methods

---

### 1.2 Access Level Configuration

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define granular access levels and field-level permissions so each role (Admin, HR Manager, Manager, Employee) can see and edit only the employee data its job requires.

#### Rationale
**Why This Matters:**
- Enforces least privilege so a manager or employee account cannot read compensation, SSN, or records outside its scope
- Field-level permissions prevent broad over-sharing of sensitive PII to roles that have no business need for it
- Limits the blast radius of a single compromised or insider account to the data that role legitimately accesses
- Default or overly permissive access levels are a common cause of accidental PII exposure across HR platforms

**Attack Prevented:** Privilege escalation, insider data harvesting, unauthorized PII access, excessive-permission exposure

#### ClickOps Implementation

**Step 1: Define Access Levels**

| Level | Permissions |
|-------|-------------|
| Admin | Full access |
| HR Manager | HR functions |
| Manager | Team access |
| Employee | Self-service |

**Step 2: Configure Field Permissions**
1. Navigate to: **Settings → Access Levels**
2. Create custom access levels
3. Configure field-level visibility

---

## 2. API Security

### 2.1 Use OAuth 2.0 for Integrations; Treat API Keys as Legacy

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Build and re-platform BambooHR integrations on OAuth 2.0 with explicitly requested scopes, and treat user-generated API keys as a legacy, single-tenant fallback that must be issued only from a dedicated least-privilege service user.

#### Rationale
**Attack Scenario:** A compromised API key enables a full employee database export — SSN, compensation, and personal data — because the key inherits every permission its owning user holds and carries no scope of its own.

**Why This Matters:**
- BambooHR documents OAuth 2.0 as the primary authentication method for its API, with per-integration scopes; API keys have **no key-level scoping** and act as the Basic-auth username of a 160-bit hexadecimal credential that inherits the **full access of the user who created it** ([Getting Started](https://documentation.bamboohr.com/docs/getting-started.md))
- A key created by an administrator is therefore an administrator-equivalent credential with no interactive MFA prompt — issuing keys only from a purpose-built service user with the narrowest access level is what bounds the blast radius
- Separate credentials per integration let you revoke one integration without breaking the others, and routine rotation shrinks the window a leaked or stale credential can be abused
- Documented credential ownership makes anomalous API usage easier to detect and attribute during an incident

**Attack Prevented:** API key compromise, bulk employee-data exfiltration, credential sprawl, stale-key abuse, over-privileged integration access

> **Deprecated mechanisms — do not build on these.** Per BambooHR's [Past Changes to the API](https://documentation.bamboohr.com/docs/past-changes-to-the-api.md): OAuth 2.0 became the primary API authentication method in **March 2025**; the `POST /api/v1/login` endpoint was **deprecated in May 2025**; and as of **April 2025** new applications must not use `oidcLogin` (the `legacy.login` scope remains available only to existing integrations). An integration still authenticating through these paths is running on a mechanism the vendor has retired and should be migrated to OAuth 2.0.

> **Access-scope change (March 2025).** BambooHR restricted the `/v1/meta/users/` endpoint to administrator accounts, closing a user/email enumeration path that was previously reachable by any authenticated caller ([Past Changes to the API](https://documentation.bamboohr.com/docs/past-changes-to-the-api.md)). This is a concrete reason to keep integration identities **non-administrative**: an integration that "needs" admin only to enumerate users is asking for the exact privilege the vendor removed from ordinary callers.

#### ClickOps Implementation

**Step 1: Register an OAuth Application**
1. Register the integration with BambooHR as an OAuth 2.0 application
2. Request only the scopes the integration actually needs — scopes are granted per application, not per key
3. Register an **exact** redirect URI; BambooHR requires an exact match on the authorization request
4. Request the `offline_access` scope **only** where the integration genuinely needs unattended operation — refresh tokens are issued only when that scope is granted. Access tokens expire after **3600 seconds** ([Getting Started](https://documentation.bamboohr.com/docs/getting-started.md))

**Step 2: Audit Legacy API Keys**
1. Navigate to: **Settings → API Keys**
2. Review all active keys and identify the **owning user** for each — the key's effective permissions are that user's permissions
3. Remove unused keys and any key owned by a human administrator account

**Step 3: Key Hygiene Where Keys Remain**
1. Issue each remaining key from a dedicated service user with the minimum access level required
2. Create separate keys per integration and document key purpose and owner
3. Rotate keys on a fixed schedule and immediately on staff departure or suspected exposure

#### Validation & Testing
- For each active key, confirm the owning user's access level in **Settings → Access Levels** and verify it excludes fields the integration does not need (SSN, compensation, bank details)
- Confirm no integration authenticates via `POST /api/v1/login` or `oidcLogin`
- Confirm every OAuth application's granted scopes match its documented purpose, and that `offline_access` is present only where unattended refresh is required

---

### 2.2 Third-Party App Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review, approve, and periodically audit third-party apps and marketplace integrations connected to BambooHR, scrutinizing the OAuth scopes each one is granted.

#### Rationale
**Why This Matters:**
- Connected apps inherit OAuth access to employee data and become an extension of your attack surface
- Over-scoped or abandoned integrations provide a persistent, often unmonitored path to sensitive HR records
- Requiring admin approval prevents employees from silently authorizing risky apps that exfiltrate data
- A compromised or malicious marketplace vendor can abuse standing access without ever touching a user password

**Attack Prevented:** Supply-chain compromise, OAuth scope abuse, shadow-IT integrations, third-party data exfiltration

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Apps → Installed Apps**
2. Review all connected apps
3. Remove unused integrations

**Step 2: App Approval**
1. Require admin approval for new apps
2. Review OAuth scopes
3. Audit app access quarterly

---

### 2.3 Verify Webhook Signatures

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-8, SI-7

#### Description
Terminate BambooHR webhooks on an HTTPS endpoint and validate every delivery's SHA-256 HMAC signature against the webhook's private key before the payload is trusted or processed.

#### Rationale
**Why This Matters:**
- BambooHR webhook payloads carry employee record changes; an unauthenticated receiver will process anything that reaches its URL, so a leaked or guessed endpoint becomes a data-injection path into downstream HR, payroll, and provisioning systems
- BambooHR signs each delivery with an `X-BambooHR-Signature` header — a SHA-256 HMAC computed over the raw request body, the `X-BambooHR-Timestamp` value, and the webhook's private key — and documents that the comparison must be **timing-safe**; a naive string comparison leaks signature bytes to an attacker probing the endpoint
- The private key is displayed **only once at creation** and **cannot be rotated on an existing webhook** — key rotation means creating a new webhook and retiring the old one, which must be planned before the key is lost or exposed
- Validating the timestamp alongside the signature is what prevents replay of a previously captured legitimate delivery

**Attack Prevented:** Webhook spoofing, payload injection into downstream systems, replay attacks, timing-based signature forgery

#### ClickOps Implementation

**Step 1: Require HTTPS**
1. Configure the webhook to deliver only to an HTTPS URL — BambooHR documents HTTPS-only delivery ([Webhooks](https://documentation.bamboohr.com/docs/webhooks.md))
2. Do not expose the receiver on a plaintext or internal-only-by-obscurity endpoint

**Step 2: Capture and Store the Private Key**
1. At webhook creation, copy the private key immediately — it is shown once and cannot be retrieved afterward
2. Store it in your secrets manager alongside the webhook's name and owning team

**Step 3: Validate Every Delivery**
1. Read `X-BambooHR-Timestamp` and `X-BambooHR-Signature` from the request headers
2. Recompute the SHA-256 HMAC over the **raw** request body plus the timestamp using the stored private key
3. Compare using a constant-time comparison function; reject on mismatch and on stale timestamps
4. Reject and alert on any delivery that fails validation rather than silently dropping it

**Step 4: Plan Rotation**
1. Treat key rotation as "create a new webhook, cut traffic over, delete the old one" — there is no in-place rotation
2. Record the rotation procedure in the integration's runbook before the key is needed

#### Validation & Testing
- Replay a captured delivery with a modified body and confirm the receiver rejects it
- Replay an unmodified delivery with an old timestamp and confirm it is rejected
- Confirm the comparison path uses a timing-safe primitive, not `==`

---

### 2.4 Govern Permissioned Webhook Ownership

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2, CM-3

#### Description
Create Permissioned Webhooks under a monitored, non-personal service account and treat any change to that account's permissions — or its deactivation — as a change that silently alters or stops the data feed.

#### Rationale
**Why This Matters:**
- BambooHR Permissioned Webhooks deliver only the fields the **creating user** is permitted to see, so the integration's data scope is bound to a human account's permission set rather than to the integration itself ([Permissioned Webhooks](https://documentation.bamboohr.com/docs/permissioned-webhooks.md))
- If the creating user is **deactivated**, the webhook stops working — an offboarding action taken for sound security reasons can break a payroll or provisioning feed with no obvious cause
- If the creating user's permissions change, fields are **silently stripped** from subsequent payloads; downstream systems see missing values rather than an error, which can quietly corrupt records or halt automation without alerting anyone
- Binding the webhook to a documented service account with change control makes both failure modes visible and planned rather than discovered during an incident

**Attack Prevented:** Silent integration data loss, unmonitored scope drift, offboarding-induced feed failure, downstream record corruption from stripped fields

#### ClickOps Implementation

**Step 1: Use a Service Account**
1. Create the Permissioned Webhook under a dedicated, non-personal BambooHR user with a documented owner
2. Grant that user only the field access the integration requires

**Step 2: Change-Control the Account**
1. Add the service account to your access-review scope so permission changes are reviewed, not incidental
2. Flag the account as break-glass in your offboarding and deactivation runbooks — deactivating it stops the webhook

**Step 3: Monitor the Feed**
1. Alert on delivery gaps and on unexpected null/missing fields in received payloads
2. Re-verify the payload field set after any access-level change

#### Validation & Testing
- Compare a current payload's field set against the documented expected schema after every access-level change to the owning account
- Confirm the owning account appears in offboarding runbooks with an explicit "do not deactivate without cutover" note

---

## 3. Data Security

### 3.1 Protect Sensitive Fields

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Identify the most sensitive employee fields (SSN, compensation, and bank account details) and restrict their visibility and apply masking by access level.

#### Rationale
**Why This Matters:**
- SSNs, salary, and bank account numbers are the highest-value PII in the HR record and the primary target of attackers and insiders
- Restricting field visibility by role enforces need-to-know so most accounts never see this data at all
- Masking limits exposure even for authorized users and reduces what a screenshot, export, or shoulder-surf can reveal
- Concentrating protection on these fields aligns with privacy regulations and breach-notification thresholds for SSN and financial data
- Field permissions govern the API and webhook surface too: an API key inherits its owning user's field access, and a Permissioned Webhook delivers only the creating user's visible fields — so tightening field permissions on integration service accounts directly narrows what a compromised integration can read (see [2.1](#21-use-oauth-20-for-integrations-treat-api-keys-as-legacy) and [2.4](#24-govern-permissioned-webhook-ownership))

**Attack Prevented:** PII and SSN theft, payroll-redirect fraud, insider data harvesting, over-broad data exposure

#### ClickOps Implementation

**Step 1: Configure Field Security**
1. Navigate to: **Settings → Employee Fields**
2. Identify sensitive fields (SSN, salary, bank info)
3. Restrict visibility by access level

**Step 2: Mask Sensitive Data**
1. Configure SSN masking
2. Limit bank account visibility
3. Audit sensitive data access

---

### 3.2 Report Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-21

#### Description
Restrict which users can build and share reports so bulk extracts of employee data cannot be created or distributed without authorization.

#### Rationale
**Why This Matters:**
- Reports can aggregate sensitive fields across the entire workforce into a single high-value export
- Uncontrolled report sharing can leak compensation or PII internally or externally beyond the intended audience
- Limiting report authors keeps bulk-data access tied to a small, accountable set of users
- Reporting tools are a common exfiltration path that bypasses the field-level controls applied to individual record views

**Attack Prevented:** Bulk data exfiltration, unauthorized report sharing, aggregation-based PII exposure

#### ClickOps Implementation

**Step 1: Restrict Report Access**
1. Navigate to: **Reports**
2. Limit who can create reports
3. Restrict report sharing

---

## 4. Monitoring & Detection

### 4.1 Activity Monitoring

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Review BambooHR login history and security logs to monitor failed logins and investigate suspicious or anomalous access to employee records.

#### Rationale
**Why This Matters:**
- Login and activity logs are the primary signal for detecting credential stuffing, account takeover, and insider misuse
- Monitoring failed logins surfaces brute-force and password-spray attempts before they succeed
- Timely review shortens attacker dwell time and supports forensic reconstruction after an incident
- Without active monitoring, unauthorized access to SSNs and compensation data can go undetected until it is reported externally

**Attack Prevented:** Undetected account takeover, brute-force and password-spray attacks, insider misuse, delayed breach detection

#### ClickOps Implementation

**Step 1: Review Login History**
1. Navigate to: **Settings → Security → Login History**
2. Monitor failed logins
3. Investigate suspicious access

**Step 2: Extend Monitoring to Integrations**
1. Alert on webhook deliveries that fail signature validation at your receiver ([2.3](#23-verify-webhook-signatures))
2. Alert on webhook delivery gaps and unexpected missing fields, which indicate a Permissioned Webhook owner change or deactivation ([2.4](#24-govern-permissioned-webhook-ownership))
3. Review API key inventory and owning users on the same cadence as login-history review

---

## Appendix A: Edition Compatibility

Edition names and availability below reflect the last verification against the product; see the Console path note in Scope — they are not currently re-verifiable against the help center. Confirm against your contract and tenant.

| Control | Essentials | Advantage |
|---------|------------|-----------|
| SAML SSO | Add-on | ✅ |
| 2FA | ✅ | ✅ |
| Custom Access Levels | ✅ | ✅ |
| API Access | ✅ | ✅ |

---

## Appendix B: References

**Official BambooHR Developer Documentation (fetch-verified):**
- [API Getting Started](https://documentation.bamboohr.com/docs/getting-started.md) — OAuth 2.0 flow, scopes, token lifetimes, API key semantics
- [Past Changes to the API](https://documentation.bamboohr.com/docs/past-changes-to-the-api.md) — deprecations, endpoint access changes, base-URL restructure
- [Webhooks](https://documentation.bamboohr.com/docs/webhooks.md) — signature headers, HMAC construction, private-key handling
- [Permissioned Webhooks](https://documentation.bamboohr.com/docs/permissioned-webhooks.md) — creator-bound field scope and failure modes
- [API Documentation Index](https://documentation.bamboohr.com/)
- [Official SDKs Overview](https://documentation.bamboohr.com/docs/sdks)
- [Official PHP SDK](https://github.com/BambooHR/bhr-api-php) (MIT license)
- [GitHub Organization](https://github.com/BambooHR)

**Identity Provider Integration Guides:**
- [BambooHR SAML SSO with Okta](https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-BambooHR.html)
- [BambooHR SSO with Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/saas-apps/bamboo-hr-tutorial)

**Contractual / Legal:**
- [Data Processing Agreement](https://www.bamboohr.com/legal/data-processing-agreement)

**Compliance Frameworks:**
- BambooHR publishes its certification and audit posture (SOC reports, ISO alignment, penetration testing) through its trust and legal pages. Those pages describe the vendor's own attestations rather than administrator-configurable controls, so this guide does not cite them as hardening sources. Request the current SOC 1 / SOC 2 Type II reports and any ISO certificates from BambooHR directly under NDA and validate the scope and period against your own control requirements — the assurance you can rely on is what the report's scope statement actually covers.

**Security Incidents:**
- **February 2019 — TRAXPayroll Breach:** An unauthorized third party accessed TRAXPayroll (a BambooHR-related payroll service) between February 5-13, 2019, exposing employee names, SSNs, states of residence, wage types, and tax codes. The attacker attempted to redirect payroll deposits. The BambooHR core platform was not breached. ([DataBreaches.net Report](https://databreaches.net/bamboohr-discloses-breach-involving-traxpayroll/))
- No major public security incidents identified for the BambooHR core platform in the 2023-2025 timeframe.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against documentation.bamboohr.com: rewrote 2.1 to lead with OAuth 2.0 (primary since Mar 2025) and demote API keys to a legacy, owner-scoped fallback, with callouts for the `POST /api/v1/login` (May 2025) and `oidcLogin` (Apr 2025) deprecations and the Mar 2025 admin-only restriction on `/v1/meta/users/`; added 2.3 (webhook signature verification) and 2.4 (Permissioned Webhook ownership); added console-path verifiability note (help.bamboohr.com is an identical-shell SPA); replaced Trust Center and marketing security-page references with fetch-verified developer documentation and an honest compliance note; filled the empty Detection Focus heading in 4.1. Also noted for operators: the API base URL was restructured to `{companyDomain}.bamboohr.com/api/` in Jul 2025, which matters for egress allowlisting. Tier 2 bodies (CIS, DISA STIG, CISA SCuBA) confirmed to publish no BambooHR baseline; Tier 3/4 research not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial BambooHR hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
