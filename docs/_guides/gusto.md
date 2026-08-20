---
layout: guide
title: "Gusto Hardening Guide"
vendor: "Gusto"
slug: "gusto"
tier: "5"
category: "HR/Finance"
description: "Payroll security for admin controls, partner integrations, and bank account protection"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Gusto is a payroll and benefits platform for small-medium businesses. REST API and partner integrations access employee SSN, bank accounts, compensation, and tax information. Compromised access enables payroll fraud and exposes highly sensitive PII.

### Intended Audience
- Security engineers managing payroll systems
- Gusto administrators
- GRC professionals assessing payroll compliance
- Third-party risk managers evaluating HR integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Gusto security configurations including authentication, access controls, API/integration security, and data protection.

> **Documentation access note (verified 2026-08-08):** Gusto's developer documentation (`docs.gusto.com`) is public and was fetch-verified for this revision. Gusto's admin help center (`support.gusto.com`) blocks automated verification (HTTP 403 to fetchers), so links to it below are cited from prior verification and should be confirmed in a browser.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [API Security](#2-api-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require 2-step verification (MFA) for all Gusto administrators, and enable login notifications, trusted-device controls, and active-session review.

#### Rationale
**Why This Matters:**
- Gusto admin accounts control employee SSNs, bank account details, compensation data, and tax filings, so a password-only login is the weakest link in the platform
- Payroll systems are prime targets for phishing and credential stuffing because access converts directly into redirected payments
- 2-step verification stops attackers who have already harvested or guessed a valid password
- Login notifications and session review surface unauthorized access attempts before fraud is committed

**Attack Prevented:** Credential theft, phishing, credential stuffing, account takeover

#### ClickOps Implementation

**Step 1: Enable 2-Step Verification**
1. Navigate to: **Settings → Security**
2. Enable: **Require 2-step verification**
3. Configure for all admins

**Step 2: Configure Login Security**
1. Enable login notifications
2. Configure trusted devices
3. Review active sessions

---

### 1.2 Admin Access Controls

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define least-privilege Gusto admin roles (Primary Admin, Full Admin, Limited Admin, No Access) and minimize the number of full administrators.

#### Rationale
**Why This Matters:**
- Every full admin can view and modify payroll, bank accounts, and employee PII, so each extra full-admin account multiplies the blast radius of a single compromise
- Limited admin roles scope each person to only the tasks they need, enforcing least privilege
- Fewer full admins means fewer high-value credentials for attackers to target and fewer accounts to monitor
- Role separation creates accountability and makes anomalous privilege use easier to spot

**Attack Prevented:** Privilege escalation, insider abuse, lateral movement, excessive-permission exploitation

#### ClickOps Implementation

**Step 1: Define Admin Roles**

| Role | Permissions |
|------|-------------|
| Primary Admin | Full access |
| Full Admin | Most admin functions |
| Limited Admin | Specific access |
| No Access | Employee only |

**Step 2: Configure Admin Permissions**
1. Navigate to: **Team → Admins**
2. Limit full admin count
3. Use limited admin for specific tasks

---

## 2. API Security

### 2.1 Partner Integration Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Manage Gusto partner integrations securely.

#### Rationale
**Attack Scenario:** Compromised API partner access enables bank account modification; payroll fraud redirects employee payments.

**Why This Matters:**
- Connected partner apps hold delegated access to payroll and banking data, so a compromised or over-permissioned integration is an indirect path to fraud
- Unused or forgotten connections retain standing access long after they are needed, expanding the attack surface
- Reviewing and scoping integration permissions enforces least privilege on third-party access
- Quarterly auditing catches credential leakage or abuse from a partner before it is used to alter payments

**Attack Prevented:** Supply chain compromise, OAuth token abuse, unauthorized data access, bank account modification

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Settings → Connected Apps**
2. Review all partner integrations
3. Remove unused connections

**Step 2: Integration Best Practices**
1. Limit integration permissions
2. Audit data access
3. Review quarterly

**Step 3: Apply Least Privilege via Scopes**

Gusto's API uses a `resource:action` scope model (for example, `employees:read`), and Gusto's own guidance is to request only the scopes an integration actually needs. Scopes are granted at the OAuth consent step, so an over-scoped grant is permanent until the connection is revoked and re-authorized.

1. For each connected app, compare the scopes granted against the data the integration demonstrably uses
2. Reject or re-authorize any integration requesting write scopes it does not need — payroll and bank-account writes are the highest-risk grants on the platform
3. Re-check scopes whenever a partner ships a new version of their integration

Source: [Gusto API scopes](https://docs.gusto.com/app-integrations/docs/scopes)

**Step 4: Manage Token Lifetime and Revocation**

- **Access tokens expire in 7,200 seconds (2 hours).** Gusto advises subtracting 60 seconds when scheduling a refresh so the refresh happens before expiry rather than racing it.
- **System Access Tokens** (available from API version `2024-04-01`) replaced the deprecated partner API token. They authorize system-level endpoints only, and Gusto endorses issuing them just-in-time rather than storing them in a database — a stored long-lived token is a standing credential to payroll data.
- **Revoke on offboarding or suspected exposure** via `POST /oauth/revoke`, supplying `client_id`, `client_secret`, and the token. A revoked token can neither be used nor refreshed, so revocation is the definitive kill switch for a compromised integration.

Sources: [Authentication](https://docs.gusto.com/app-integrations/docs/authentication) · [System access tokens](https://docs.gusto.com/app-integrations/docs/system-access-tokens) · [Revoke an access token](https://docs.gusto.com/app-integrations/reference/revoke-access-token)

See also [2.2](#22-track-api-version-lifecycle), [2.3](#23-scope-integrations-to-a-single-company-with-strict-access), and [2.4](#24-verify-and-deduplicate-webhook-deliveries).

---

### 2.2 Track API Version Lifecycle

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-3, SI-2

#### Description
Track which Gusto API version each integration pins, and migrate off versions approaching the end of their 12-month support window before they retire and start returning errors.

#### Rationale
**Why This Matters:**
- Gusto uses date-based API versioning with a 12-month support window per version — six months of full support followed by six months of limited support during which only critical fixes are applied
- An integration pinned to a limited-support version stops receiving non-critical security patches, so known defects in that version's behavior stay unpatched in your payroll pipeline
- Retired versions return HTTP 406, which converts a missed migration into a hard integration outage — for payroll, that means failed runs at exactly the moment money must move
- Gusto signals the deadline in `Deprecation`, `Sunset`, and `Link` response headers, so a team that never logs response headers has no early warning at all

**Attack Prevented:** Exploitation of unpatched API-version defects, silent security-fix drift, unplanned integration failure during payroll

#### ClickOps Implementation

**Step 1: Inventory Pinned Versions**
1. For every integration calling the Gusto API, record the API version it sends
2. Map each version to its release date and derive its full-support and limited-support end dates

**Step 2: Monitor Deprecation Signals**
1. Log the `Deprecation`, `Sunset`, and `Link` response headers from Gusto API responses
2. Alert when a `Sunset` date appears for any version currently in production
3. Treat any version in its limited-support half as an active migration item, not a future one

**Step 3: Migrate Before Retirement**
1. Schedule the version upgrade inside the full-support window
2. Confirm no production integration returns HTTP 406 after cutover

#### Validation & Testing
1. Confirm every production integration's pinned version is inside its full-support window
2. Confirm your monitoring surfaces a `Sunset` header, not just non-2xx status codes

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST 800-53 Rev 5 | CM-3, SI-2 |
| SOC 2 | CC7.1, CC8.1 |

Source: [API versioning](https://docs.gusto.com/app-integrations/docs/api-versioning)

---

### 2.3 Scope Integrations to a Single Company with Strict Access

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-3, AC-6, SC-32

#### Description
Use Gusto's Strict Access mode so each OAuth grant produces a token reserved for access to a single company, and migrate any legacy multi-company tokens to strict-access tokens.

#### Rationale
**Why This Matters:**
- Without Strict Access, one OAuth token can reach every company an integration has been authorized against, so a single leaked token exposes an entire book of payroll clients rather than one
- Strict Access binds a token to exactly one company per grant, which makes token compromise a bounded, per-tenant incident instead of a platform-wide one
- This is the blast-radius control for Gusto integrations: no scope restriction limits damage as effectively as removing cross-company reach from the credential itself
- Legacy multi-company tokens keep their broad reach indefinitely until deliberately exchanged, so accounts that predate Strict Access carry the old blast radius until someone migrates them

**Attack Prevented:** Cross-tenant data access, multi-company blast radius from a single leaked token, over-broad partner access

#### Prerequisites
- Strict Access is enabled by Gusto on request — contact `developer@gusto.com`

#### ClickOps Implementation

**Step 1: Request Strict Access**
1. Contact Gusto developer support to have Strict Access enabled for your application
2. Confirm the setting is active before relying on it

**Step 2: Migrate Legacy Tokens**
1. Identify existing multi-company tokens
2. Exchange each one through the `/oauth/token` endpoint using the strict-access grant type
3. Confirm the resulting token resolves to exactly one company

**Step 3: Enforce One Grant per Company**
1. Treat each company as its own authorization, with its own token and its own storage entry
2. Revoke per-company tokens individually when a company offboards, rather than revoking a shared credential

#### Validation & Testing
1. Attempt to read a second company's data with a strict-access token and confirm the request is refused
2. Confirm no legacy multi-company token remains in your credential store

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST 800-53 Rev 5 | AC-3, AC-6, SC-32 |
| SOC 2 | CC6.1, CC6.3 |

Source: [Strict access](https://docs.gusto.com/app-integrations/docs/strict-access)

---

### 2.4 Verify and Deduplicate Webhook Deliveries

**Profile Level:** L2 (Walk)
**NIST 800-53:** SI-10, AU-3

#### Description
Complete Gusto's webhook subscription verification handshake, and make webhook handlers idempotent by storing processed event UUIDs, since Gusto documents that duplicate deliveries occur.

#### Rationale
**Why This Matters:**
- A webhook subscription starts in a `pending` state and only becomes active after you return the `verification_token` to the verify endpoint, which proves you control the receiving URL and prevents deliveries being pointed at an endpoint you do not own
- Gusto documents that duplicate deliveries happen, so a non-idempotent handler can process the same payroll or employment event twice — double-applying a state change is a data-integrity failure, not just noise
- Gusto's webhook documentation describes no per-payload HMAC signature header, so your endpoint cannot cryptographically authenticate an individual delivery — treat webhook payloads as untrusted notifications and re-fetch authoritative state from the API before acting on anything sensitive
- Webhook-driven automation that acts on an unverified payload is a straightforward injection path into payroll workflows

**Attack Prevented:** Forged or replayed webhook payloads, duplicate event processing, unauthorized subscription redirection

#### ClickOps Implementation

**Step 1: Complete the Verification Handshake**
1. Create the webhook subscription — it is created in `pending` state
2. Receive the `verification_token` Gusto sends to the subscription URL
3. Return it via `PUT webhook_subscriptions/{uuid}/verify` to activate the subscription

**Step 2: Make Handlers Idempotent**
1. Store the event UUID of every processed webhook
2. Discard any delivery whose UUID has already been processed
3. Do not treat "received twice" as an anomaly — Gusto documents it as expected behavior

**Step 3: Re-fetch Before Acting**
1. Because no per-payload signature header is documented, do not treat the payload body as authoritative
2. On any security- or money-relevant event, call the Gusto API to read current state before taking action
3. Subscribe to and handle newer lifecycle events such as `company.suspended_effective` (added July 2026) so account-state changes are not missed

#### Validation & Testing
1. Confirm no subscription remains in `pending` state
2. Replay a previously delivered event and confirm your handler takes no second action

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST 800-53 Rev 5 | SI-10, AU-3 |
| SOC 2 | CC6.1, CC7.2 |

Sources: [Webhooks](https://docs.gusto.com/app-integrations/docs/webhooks) · [Best practices](https://docs.gusto.com/app-integrations/docs/best-practices) · [July 2026 changelog](https://docs.gusto.com/app-integrations/changelog/july-2026)

---

## 3. Data Security

### 3.1 Protect Payroll Data

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Restrict who can view and modify payroll, SSN, and bank account data, and require approval and verification workflows for payroll and bank account changes.

#### Rationale
**Why This Matters:**
- Payroll records hold the most sensitive employee PII (SSNs, salaries, and bank routing details), which carries legal and financial liability if exposed
- Limiting data visibility enforces need-to-know and shrinks the set of accounts that can leak or alter sensitive fields
- Approval workflows for bank account and payroll changes prevent a single compromised account from silently redirecting payments
- Payment notifications give employees and admins a chance to catch fraudulent changes before funds move

**Attack Prevented:** Payroll diversion fraud, bank account hijacking, PII exposure, unauthorized data modification

#### ClickOps Implementation

**Step 1: Limit Data Access**
1. Restrict who can view payroll
2. Limit SSN visibility
3. Protect bank account data

**Step 2: Approval Workflows**
1. Require approval for payroll changes
2. Enable bank account change verification
3. Configure payment notifications

---

### 3.2 Document Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Limit access to tax documents such as W-2 and 1099 forms, and control who can view and download them.

#### Rationale
**Why This Matters:**
- Tax documents bundle name, SSN, address, and earnings — exactly the data needed for identity theft and fraudulent tax filing
- Broad download permissions let a single admin exfiltrate the entire workforce's PII in one export
- Restricting document access enforces least privilege and reduces accidental or malicious disclosure
- Controlling downloads limits how far sensitive records can travel outside Gusto's protected environment

**Attack Prevented:** Identity theft, tax-refund fraud, bulk PII exfiltration, unauthorized document disclosure

#### ClickOps Implementation

**Step 1: Document Access**
1. Limit who can view tax documents
2. Restrict W-2/1099 access
3. Configure download permissions

---

## 4. Monitoring & Detection

### 4.1 Activity Monitoring

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Monitor administrative logins, payroll changes, and bank account updates, and alert on sensitive activity.

#### Rationale
**Why This Matters:**
- Without activity logging, account takeover and payroll fraud can proceed undetected until employees report missing pay
- Monitoring admin logins surfaces unusual access patterns such as new locations or off-hours sign-ins
- Alerting on bank account updates targets the single highest-risk action an attacker can take on a payroll system
- An audit trail of payroll changes supports investigation, attribution, and compliance reporting after an incident

**Attack Prevented:** Undetected account takeover, payroll fraud, unauthorized bank account changes, insider abuse

#### ClickOps Implementation

**Step 1: Review Activity**
1. Monitor admin logins
2. Track payroll changes
3. Alert on bank account updates

#### Detection Focus

Gusto does not expose a customer-facing audit-log export or SIEM connector, so detection is built from the surfaces the platform does provide — admin-visible activity, login notifications, and the webhook event stream:

- **Bank account changes** — the single highest-value action on a payroll platform. Alert on every change, and correlate it against a recent admin login from a new device or location.
- **Admin role changes** — any promotion to Full Admin or Primary Admin, or any new admin invitation, per [1.2](#12-admin-access-controls).
- **New or re-authorized app connections** — a new OAuth grant is a new standing credential to payroll data; review against the inventory in [2.1](#21-partner-integration-security).
- **Company lifecycle events** — subscribe to webhook events such as `company.suspended_effective` so account-state changes reach your monitoring rather than only your inbox ([2.4](#24-verify-and-deduplicate-webhook-deliveries)).
- **Off-hours payroll edits** — payroll modifications outside your normal payroll calendar warrant a human check.

Because webhook payloads carry no documented per-payload signature ([2.4](#24-verify-and-deduplicate-webhook-deliveries)), treat webhook-derived alerts as leads to investigate in the Gusto UI, not as authenticated evidence on their own.

---

## Appendix A: Edition Compatibility

| Control | Simple | Plus | Premium |
|---------|--------|------|---------|
| 2-Step Verification | ✅ | ✅ | ✅ |
| Admin Roles | ✅ | ✅ | ✅ |
| API Access | Limited | ✅ | ✅ |
| Priority Support | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Gusto Documentation:**
- [Help Center](https://support.gusto.com/) (support.gusto.com blocks automated verification as of 2026-08; verify via browser)
- [Prevent Fraud on Your Gusto Account](https://support.gusto.com/article/106621992100000/Prevent-fraud-on-your-Gusto-account) (support.gusto.com blocks automated verification as of 2026-08; verify via browser)

**API & Developer Tools:**
- [Gusto API Documentation](https://docs.gusto.com/)
- [Security Review for App Integrations](https://docs.gusto.com/app-integrations/docs/security-review)
- [Authentication](https://docs.gusto.com/app-integrations/docs/authentication)
- [System Access Tokens](https://docs.gusto.com/app-integrations/docs/system-access-tokens)
- [Revoke an Access Token](https://docs.gusto.com/app-integrations/reference/revoke-access-token)
- [Scopes](https://docs.gusto.com/app-integrations/docs/scopes)
- [API Versioning](https://docs.gusto.com/app-integrations/docs/api-versioning)
- [Strict Access](https://docs.gusto.com/app-integrations/docs/strict-access)
- [Webhooks](https://docs.gusto.com/app-integrations/docs/webhooks)
- [Integration Best Practices](https://docs.gusto.com/app-integrations/docs/best-practices)
- [Changelog — July 2026](https://docs.gusto.com/app-integrations/changelog/july-2026)

**Compliance Frameworks:**
- Gusto's SOC 1, SOC 2, and HIPAA attestations are distributed under NDA rather than published as configuration documentation. Request the current reports and bridge letters through Gusto support; no vendor trust-center or security-marketing page is cited here, per this repo's [source standard](https://github.com/grcengineering/how-to-harden/blob/main/SOURCES.md).
- [Request Access to SOC Reports and Bridge Letters](https://support.gusto.com/article/105983845100000/Request-access-to-SOC-reports-and-bridge-letters) (support.gusto.com blocks automated verification as of 2026-08; verify via browser)

**Security Incidents:**
- No major public security incident affecting Gusto was identified in the sources surveyed for this guide (last reviewed 2026-08-08). Absence of a finding here is not a guarantee that none occurred.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against `docs.gusto.com`: added 2.2 (API version lifecycle — 12-month window, HTTP 406 on retired versions, Deprecation/Sunset/Link headers), 2.3 (Strict Access — single-company token binding, legacy multi-company token migration), and 2.4 (webhook verification handshake, event-UUID idempotency, and the honest statement that no per-payload HMAC signature header is documented). Expanded 2.1 with the `resource:action` scope model, 7,200-second access-token lifetime, System Access Tokens, and `POST /oauth/revoke`. Populated the previously empty Detection Focus in 4.1. Removed Trust Center and security-marketing citations and re-sourced compliance honestly; annotated all `support.gusto.com` references as browser-verify-only (403 to fetchers); replaced the stale "as of February 2026" incident date with a last-reviewed note. Tier 2 status: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline surfaced for Gusto — not an exhaustive sweep. Tier 3/4 product-specific research not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Gusto hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
