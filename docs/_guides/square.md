---
layout: guide
title: "Square Hardening Guide"
vendor: "Square (Block)"
slug: "square"
tier: "2"
category: "Productivity"
description: "Commerce platform hardening for Square including SSO configuration, team permissions, and API security"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Square is a comprehensive commerce platform serving **millions of businesses** for payments, point-of-sale, and business management. As a platform handling payment and customer data, Square security configurations directly impact PCI compliance and business operations.

### Intended Audience
- Security engineers managing commerce platforms
- IT administrators configuring Square
- Business owners managing Square access
- GRC professionals assessing retail security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Square Dashboard security including SSO, team permissions, device security, and API management.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Device Security](#3-device-security)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SSO for Square Dashboard access (Square for Enterprise).

> **Verification note (2026-08):** Square's SSO documentation is not externally verifiable — the Square help center is a single-page application that returns HTTP 200 with the support homepage for pages that do not exist, so the "Square for Enterprise" plan requirement and the **Security** → **Single Sign-On** path below could not be corroborated against a fetchable first-party page. Confirm availability, plan eligibility, and the exact console path with Square support or in the live Dashboard before relying on this control.

#### Rationale
**Why This Matters:**
- Centralizes Square Dashboard authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local Square password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- IdP-driven deprovisioning removes access the moment an employee leaves, eliminating orphaned accounts that retain standing access to payment and customer data
- A single compromised Square login can expose transaction history, customer PII, and payout banking details

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Prerequisites
- Square for Enterprise plan
- Account owner access
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Square Dashboard** → **Account & Settings** → **Security**
2. Find Single Sign-On section

**Step 2: Configure SSO**
1. Enable SSO
2. Configure IdP settings
3. Test authentication

**Step 3: Enforce SSO**
1. Enable SSO enforcement
2. Configure exceptions
3. Document fallback procedures

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Square accounts.

#### Rationale
**Why This Matters:**
- Two-factor authentication blocks account takeover even when a password is phished, leaked, or reused from another breach
- Square accounts control payments, refunds, and payout bank accounts, so a password alone is insufficient protection for financial operations
- Requiring 2FA across the whole team closes the weakest-link gap where one unprotected member becomes the entry point
- PCI DSS requires multi-factor authentication for access to the cardholder data environment

**Attack Prevented:** Credential stuffing, phishing, password reuse, account takeover

#### ClickOps Implementation

**Step 1: Enable 2FA**
1. Navigate to: **Account & Settings** → **Security**
2. Enable two-step verification
3. Configure verification method

**Step 2: Require for Team**
1. Require 2FA for all team members
2. Verify compliance
3. Monitor enrollment

---

## 2. Access Controls

### 2.1 Configure Team Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Square permissions.

#### Rationale
**Why This Matters:**
- Least-privilege permission sets ensure each team member can only reach the data and actions their role requires
- Over-broad access lets a single compromised staff account expose customer records, sales reports, and settings far beyond its job function
- Separating sales, reporting, customer-data, and settings access contains the blast radius of any one account compromise
- Granular permissions create accountability and make insider misuse easier to detect during access reviews

**Attack Prevented:** Privilege escalation, insider data theft, lateral movement, excessive-access abuse

#### ClickOps Implementation

**Step 1: Review Permission Sets**
1. Navigate to: **Team** → **Permissions**
2. Review available permissions
3. Create custom permission sets

**Step 2: Assign Minimum Access**
1. Assign minimum necessary permissions
2. Separate by function:
   - Sales access
   - Reports access
   - Customer data access
   - Settings access
3. Regular access reviews

---

### 2.2 Configure Location Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control team access to specific locations.

#### Rationale
**Why This Matters:**
- Scoping team members to only their assigned locations limits exposure of sales, customer, and payout data across the business
- A compromised or rogue account confined to one location cannot pull reports or process refunds for the entire organization
- Location-level segmentation enforces separation between production sites and test or pilot locations
- Cross-location access reviews surface accounts that have accumulated unnecessary reach over time

**Attack Prevented:** Lateral movement, cross-location data exposure, excessive-access abuse

#### ClickOps Implementation

**Step 1: Configure Access**
1. Limit team members to required locations
2. Separate production locations
3. Audit cross-location access

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
- Account owners hold the highest privilege in Square (billing, banking, team management, and full data access), so their number must be tightly limited
- Every additional owner account expands the attack surface and the chance of a single compromised credential controlling the whole account
- Requiring 2FA and monitoring activity on owner accounts detects misuse before it escalates
- Tight owner control reduces the risk of standing access lingering after a privileged employee departs

**Attack Prevented:** Privilege escalation, account takeover, insider abuse, orphaned-admin access

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review account owners
2. Document admin access

**Step 2: Apply Restrictions**
1. Limit owners to 2-3 users
2. Require 2FA
3. Monitor activity

---

## 3. Device Security

### 3.1 Configure Device Management

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 1.1 |
| NIST 800-53 | CM-8 |

#### Description
Manage Square devices and terminals.

#### Rationale
**Why This Matters:**
- Square terminals and POS devices sit in physically exposed retail environments where theft and tampering are real threats
- Device passcodes and automatic logout prevent an unattended or stolen terminal from processing fraudulent transactions or exposing customer data
- An accurate device inventory makes rogue or unrecognized hardware immediately visible
- Monitoring device activity surfaces anomalous use such as logins from unexpected devices or off-hours transactions

**Attack Prevented:** Physical device theft, unauthorized POS access, terminal tampering, fraudulent transactions

#### ClickOps Implementation

**Step 1: Inventory Devices**
1. Navigate to: **Devices**
2. Review all registered devices
3. Document device purposes

**Step 2: Configure Security**
1. Enable device passcodes
2. Configure automatic logout
3. Monitor device activity

---

### 3.2 Configure API Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Square API access — personal access tokens, OAuth access and refresh tokens, and the connected applications that hold them.

#### Rationale
**Why This Matters:**
- Square API access tokens can read and write payments, customers, and inventory programmatically, so a leaked token is equivalent to a compromised account
- A **personal access token is unrestricted**: Square documents that it grants full API access to the account that issued it, with no permission scoping, so it must never be hardcoded, committed, or shared ([Access tokens](https://developer.squareup.com/docs/build-basics/access-tokens))
- OAuth access tokens are short-lived by design (30 days) while refresh tokens can persist indefinitely, so refresh-token custody — not access-token custody — is the real long-term risk
- Removing unused connected applications eliminates dormant integrations that retain access no one is monitoring
- Using the sandbox for testing keeps real payment data and live credentials out of development workflows

**Attack Prevented:** API token theft, third-party integration abuse, credential leakage, unauthorized data access, persistent access via unrevoked refresh tokens

#### ClickOps Implementation

**Step 1: Review Applications**
1. Navigate to: **Developer Dashboard**
2. Review connected applications
3. Remove unnecessary apps

**Step 2: Secure Credentials**
1. Store personal access tokens in a secrets manager — treat one as equivalent to full account credentials, because Square grants it unrestricted API access to the issuing account
2. Never hardcode a token in application source, configuration committed to version control, or client-side code, and never share one between environments or people
3. Use sandbox credentials for all testing so production tokens never enter development workflows
4. Rotate credentials regularly and revoke any token whose custody is uncertain

**Step 3: Manage OAuth Token Lifetimes**

Square documents these lifetimes for OAuth credentials ([OAuth API overview](https://developer.squareup.com/docs/oauth-api/overview)) — build rotation around them rather than assuming tokens expire on their own:

| Credential | Lifetime |
|------------|----------|
| OAuth access token | Expires 30 days after issue |
| Refresh token (authorization code flow) | Does not expire until explicitly revoked |
| Refresh token (PKCE flow) | Single use, expires after 90 days |

1. Refresh access tokens on a schedule shorter than 30 days rather than waiting for API failures
2. Treat authorization-code refresh tokens as long-lived secrets — they remain valid indefinitely until revoked, so revocation (not expiry) is the only way to end access
3. For PKCE integrations, persist the newly returned refresh token on every exchange; the previous one is consumed
4. Subscribe to the `oauth.authorization.revoked` webhook so your integration learns immediately when a merchant or Square revokes an authorization, instead of discovering it through failed API calls

---

### 3.3 Verify Webhook Signatures

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-8, SI-7 |

#### Description
Validate the `x-square-hmacsha256-signature` header on every Square webhook notification before acting on its payload, using a constant-time comparison against an HMAC-SHA-256 computed from your webhook signature key, the exact notification URL, and the raw request body.

#### Rationale
**Why This Matters:**
- A webhook endpoint is a publicly reachable URL: anyone who discovers it can POST a forged payment, refund, or order event unless the signature is checked, so signature verification is the only thing separating a Square event from an attacker's
- Square computes the signature over the concatenation of the notification URL and the raw request body, so verifying against a re-serialized or parsed body silently fails and tempts developers to disable the check entirely
- Square's documentation explicitly warns that a naive string comparison leaks information through timing analysis; a constant-time comparison closes that side channel
- The signature key is per-subscription — leaking or reusing it across environments lets a lower-trust environment forge production events

**Attack Prevented:** Webhook forgery, fraudulent event injection, replay of attacker-crafted payment notifications, timing-analysis recovery of the signature

#### Prerequisites
- A webhook subscription created in the Square Developer Dashboard
- The subscription's webhook signature key, stored in a secrets manager

#### ClickOps Implementation

**Step 1: Retrieve the Signature Key**
1. Navigate to: **Developer Dashboard** → your application → **Webhooks** → **Subscriptions**
2. Open the subscription and copy its **Signature Key**
3. Store the key in your secrets manager — never in source control

**Step 2: Record the Exact Notification URL**
1. Note the notification URL exactly as registered, including scheme, host, path, and any trailing characters
2. Any mismatch between the registered URL and the URL used in the HMAC input produces a failed verification, so the value your code uses must be configuration, not a reconstruction from request headers

**Step 3: Verify Every Notification**
1. Read the `x-square-hmacsha256-signature` header from the incoming request
2. Concatenate the notification URL with the **raw, unparsed** request body
3. Compute HMAC-SHA-256 over that string using the signature key, then Base64-encode the result
4. Compare the computed value to the header using a **constant-time** comparison function (Square warns that a byte-by-byte early-exit comparison exposes the key to timing analysis)
5. Reject the request with an error status when the comparison fails — never fall through to processing

**Step 4: Rotate and Contain**
1. Use a distinct signature key per environment so a sandbox leak cannot forge production events
2. Rotate the key if it is ever exposed, and re-verify that the endpoint rejects unsigned traffic afterward

Source: [Validate a webhook event notification](https://developer.squareup.com/docs/webhooks/step3validate)

#### Validation & Testing
1. Send a request to the endpoint with no signature header — it must be rejected
2. Send a valid payload with a tampered body byte — it must be rejected
3. Confirm from application logs that a rejected notification is not processed downstream (no order, payment, or customer record is written)

#### Compliance Mappings

| Framework | Control | How This Maps |
|-----------|---------|---------------|
| CIS Controls v8 | 3.10 Encrypt Sensitive Data in Transit | Authenticated, TLS-delivered event payloads |
| NIST 800-53 Rev 5 | SI-7 Software, Firmware, and Information Integrity | Cryptographic verification of received data |
| NIST 800-53 Rev 5 | SC-8 Transmission Confidentiality and Integrity | Integrity check on inbound vendor traffic |
| PCI DSS v4.0 | 6.2.4 | Protects payment-event handling code from injected input |

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Square Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-single-sign-on) |
| CC6.2 | Team permissions | [2.1](#21-configure-team-permissions) |
| CC6.7 | API security | [3.2](#32-configure-api-security) |
| CC6.6 | Webhook signature verification | [3.3](#33-verify-webhook-signatures) |

### PCI DSS v4.0 Mapping

| Requirement | Square Control | Guide Section |
|-------------|----------------|---------------|
| 7 | Team permissions | [2.1](#21-configure-team-permissions) |
| 8 | Authentication | [1.2](#12-enforce-two-factor-authentication) |

---

## Appendix A: References

**Official Square Documentation:**
- [Help Center](https://squareup.com/help/us/en)
- [Privacy and Security Measures](https://squareup.com/help/us/en/article/3796-privacy-and-security) -- describes Square's account security measures

> **Help-center caveat (2026-08):** `squareup.com/help` is a single-page application that returns HTTP 200 with the support homepage for article slugs that no longer exist, so a link there can appear live while pointing at nothing. Confirm the rendered article title matches the citation before trusting a help-center link.

**API & Developer Tools:**
- [Square API Reference](https://developer.squareup.com/reference/square)
- [Square Developer Portal](https://developer.squareup.com/)
- [OAuth API overview](https://developer.squareup.com/docs/oauth-api/overview) -- token and refresh-token lifetimes
- [Access tokens](https://developer.squareup.com/docs/build-basics/access-tokens) -- personal access token scope
- [Validate a webhook event notification](https://developer.squareup.com/docs/webhooks/step3validate) -- signature verification
- SDKs available for multiple languages -- via [Developer Portal](https://developer.squareup.com/)

**Compliance Frameworks:**
- Square publicly claims PCI DSS Level 1 (Service Provider) and ISO 27001 status. The pages that carried those claims are vendor marketing rather than configuration documentation and were removed from this appendix under the repo source standard; the certification status itself is **unverified in this pass** -- request current attestation documents from Square directly.

**Security Incidents:**
- (2021-12) A former Block (Square) employee accessed Cash App Investing reports after employment ended, exposing full names, brokerage account numbers, and portfolio data for approximately 8.2 million current and former customers. Disclosed April 2022.
- (2023-09) Multi-hour system outage affected merchants; forensic analysis ruled out cyberattack -- no data breach confirmed.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass: add 3.3 webhook signature verification; document OAuth/PAT token lifetimes and unrestricted-PAT scope in 3.2; annotate 1.1 SSO as externally unverifiable; prune marketing and rotted help-center references from Appendix A. Tier 3/4 sources not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO and permissions | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
