---
layout: guide
title: "Heap Hardening Guide"
vendor: "Heap (Contentsquare)"
slug: "heap"
tier: "3"
category: "Data"
description: "Digital insights platform hardening for Heap including SAML SSO, environment access, and data governance"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Heap is a digital insights platform providing autocapture analytics for product teams. As a platform collecting user interaction data automatically, Heap security configurations directly impact data privacy and analytics integrity.

### Intended Audience
- Security engineers managing analytics platforms
- IT administrators configuring Heap
- Product teams managing analytics
- GRC professionals assessing data security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Heap security including SAML SSO, environment access, API security, and data governance.

### A Note on Console Paths and Vendor Documentation

Heap's help center has migrated behind Contentsquare authentication: `help.heap.io` now redirects to `login.contentsquare.com`, and `support.contentsquare.com` refuses anonymous requests. Heap's administrative documentation is therefore no longer publicly readable, and the only publicly resolvable first-party source is the developer documentation at [developers.heap.io](https://developers.heap.io/).

**Every ClickOps console path in this guide reflects pre-migration documentation.** Verify each path in your own tenant before relying on it, and consult Heap's authenticated documentation portal — or your Contentsquare account team — for the current administrative surface. The client-side and mobile data-collection controls in Section 3 are sourced from the still-public developer documentation and are current.

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
Configure SAML SSO to centralize authentication for Heap users.

#### Rationale
**Why This Matters:**
- Centralizes Heap login in your corporate IdP, enforcing MFA and conditional access on every authentication
- Local username/password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO with SCIM provisioning deprovisions departed users automatically, eliminating orphaned accounts that retain standing access to analytics data
- Heap autocaptures user interaction data that can include sensitive product behavior, so a single compromised login can expose broad datasets

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

#### Prerequisites
- Heap admin access
- Business or Enterprise plan
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Account** → **Manage** → **SSO**
2. Enable SAML SSO

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Download Heap metadata for IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Heap users.

#### Rationale
**Why This Matters:**
- Adds a second factor so a stolen, guessed, or reused password alone cannot grant access to Heap
- Defends against credential stuffing fueled by password reuse from unrelated third-party breaches
- Admin and Architect accounts can alter data collection, export datasets, and manage users, so protecting those sessions is critical
- Phishing-resistant factors for admins block real-time credential relay and proxy phishing attacks

**Attack Prevented:** Credential stuffing, password reuse, phishing, account takeover

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

---

## 2. Access Controls

### 2.1 Configure User Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Heap roles.

#### Rationale
**Why This Matters:**
- Granting the minimum necessary role limits what a compromised or insider account can view and change
- Assigning Read-only to most users prevents accidental or malicious modification of event definitions, dashboards, and reports
- Restricting Architect and Admin roles reduces the number of accounts that can alter data capture or export raw datasets
- Regular access reviews catch privilege creep and stale grants before they become an attack path

**Attack Prevented:** Privilege escalation, insider misuse, lateral movement, unauthorized data modification

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Account** → **Manage** → **Users**
2. As of Heap's pre-migration documentation, the available roles were **Owner**, **Admin**, **Architect**, **Analyst**, and **Read-only**. Because Heap's administrative documentation is no longer publicly resolvable (see the Overview note), confirm the current role names and their exact capabilities on your own Users page rather than relying on this list
3. Assign minimum necessary role

**Step 2: Apply Least Privilege**
1. Use Read-only for most users
2. Limit Architect/Admin access
3. Regular access reviews

---

### 2.2 Configure Environment Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to different environments.

#### Rationale
**Why This Matters:**
- Separating production from development limits exposure of real user data to lower-trust test workflows
- Restricting production environment access shrinks the population of accounts that can reach live analytics data
- Environment-scoped permissions prevent a development-only user from reading or altering production datasets
- Isolating sensitive-data environments contains the blast radius of any single compromised account

**Attack Prevented:** Cross-environment data exposure, unauthorized production access, blast-radius expansion

#### ClickOps Implementation

**Step 1: Configure Environment Permissions**
1. Separate production and development environments
2. Limit production environment access to the users who need it
3. Restrict environments holding sensitive data
4. The granularity of Heap's environment-scoped permissions described here reflects pre-migration documentation and is no longer publicly verifiable (see the Overview note) — confirm what your tenant actually enforces before treating environment separation as an access-control boundary rather than an organizational convention

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Owner and admin accounts control SSO configuration, user management, data collection, and exports, making each a high-value target
- Fewer privileged accounts means fewer credentials an attacker can phish or steal to gain full control of the workspace
- Requiring SSO for admins routes privileged logins through enforced MFA and conditional access
- Monitoring admin activity surfaces suspicious configuration changes or bulk data exports early

**Attack Prevented:** Account takeover, privilege abuse, unauthorized configuration change, insider misuse

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review owner/admin accounts
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit owners to 2-3 users
2. Require SSO for admins
3. Monitor admin activity

---

## 3. Data Security

### 3.1 Configure Data Governance

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Implement data governance controls.

#### Rationale
**Why This Matters:**
- Heap autocaptures interactions by default, which can sweep in PII or sensitive fields unless redaction and blocking are configured
- Data masking and PII protection reduce the sensitivity of stored analytics, limiting harm if the data store is exposed
- Blocking sensitive-data capture keeps regulated values such as payment, health, or credential fields out of the analytics store entirely
- Supporting deletion requests sustains compliance with privacy regulations like GDPR and CCPA and honors user data rights

**Attack Prevented:** PII leakage, sensitive-data overcollection, regulatory non-compliance, privacy violations

#### ClickOps Implementation

**Step 1: Turn Off Target Text Autocapture Account-Wide**
1. Navigate to: **Account** → **Manage** → **Privacy & Security**
2. Locate the **Target Text Autocapture** toggle. This global setting controls whether Heap captures the text content of the elements users interact with
3. Disable it unless you have a concrete analytics need for interaction text. This is the single highest-leverage privacy control in Heap, because autocapture collects that text by default across your entire application — element-by-element redaction is a long tail you will never fully cover if the global default is left on
4. Confirm the change with your analytics owners first: turning it off changes what downstream event definitions and reports can see

**Step 2: Apply Client-Side Redaction Where Text Capture Must Stay On**
1. Heap provides HTML attribute-based primitives applied in your own application markup:
   - **`data-heap-redact-text`** — the element's text is replaced with `****` **before it leaves the browser**, so the original value never reaches Heap
   - **`data-heap-redact-attributes`** — redacts named element attributes. Note that **the `id` attribute cannot be redacted**, so never place sensitive values in `id`
   - **`heap-ignore`** — excludes the element from capture entirely, the strongest of the three
2. Heap also exposes a global **`disableTextCapture`** initialization flag. Be aware of its gap: **it does not cover page titles**, so a page title containing a customer name, order number, or record ID is still captured with the flag set. Audit your page titles separately
3. These are code-level changes in your own application, not console settings — route them through your normal change process and treat them as security-relevant markup

**Step 3: Verify and Support Deletion Requests**
1. Verify redaction empirically: exercise the sensitive flows and inspect the captured events to confirm the values are absent, rather than assuming an attribute took effect
2. Heap documents a user-deletion API in its developer documentation — use it as the mechanism for GDPR/CCPA erasure requests, and confirm the current endpoint, authentication, and scope against that documentation before building the workflow

---

### 3.2 Restrict Autocapture in Mobile and Native SDKs

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.3 |
| NIST 800-53 | AC-3, SC-28 |

#### Description
Disable interaction-text, accessibility-label, and pageview-title capture in Heap's mobile and native SDKs, and apply per-view redaction to sensitive screens.

#### Rationale
**Why This Matters:**
- Heap's native autocapture collects **both the target element's text and the text of ancestor elements** by default, so a redaction that covers only the tapped control can still leak the surrounding screen content
- Accessibility labels are a frequently overlooked leak path: they often carry the most descriptive human-readable version of a value precisely because they exist to be read aloud
- Mobile screens routinely render account numbers, balances, and health or identity fields in ordinary labels, which autocapture treats no differently from a button caption

**Attack Prevented:** PII leakage through mobile autocapture, sensitive-data exposure via accessibility labels and screen titles, over-collection from ancestor-element text

#### Prerequisites
- Access to your mobile application source and release process
- Heap mobile or native SDK integrated

#### ClickOps Implementation

**Step 1: Set the Initialization Flags**
1. In the SDK initialization options, configure:
   - **`disableInteractionTextCapture`** — stops capture of interaction text
   - **`disableInteractionAccessibilityLabelCapture`** — stops capture of accessibility labels
   - **`disablePageviewTitleCapture`** — stops capture of pageview titles (**iOS only**)
2. Set these as your default posture and re-enable capture narrowly where analytics genuinely requires it

**Step 2: Apply Per-View Redaction on Sensitive Screens**
1. Heap documents per-view redaction primitives across its supported native frameworks — **UIKit**, **SwiftUI**, **Android Views**, **Jetpack Compose**, **React Native**, and **Flutter**
2. Apply them to any view rendering account identifiers, financial values, health data, or credentials
3. Because autocapture also reads **ancestor** element text, redact at the container level for sensitive screens rather than only on the individual field

**Step 3: Verify Per Release**
1. Treat redaction coverage as a release checklist item — a new screen ships with autocapture on by default
2. Inspect captured events from a test build after each significant UI change

#### Validation & Testing
- Exercise each sensitive screen in a test build and confirm the captured events contain no interaction text, accessibility labels, or titles carrying sensitive values
- Confirm ancestor-element text is also absent, not just the tapped control's text
- Confirm the iOS-only pageview-title flag is set on iOS and that Android title exposure is handled another way

---

### 3.3 Route Heap Ingest Through a First-Party Proxy

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 13.1 |
| NIST 800-53 | AU-2, SC-7 |

#### Description
Configure HeapJS to send data through a reverse proxy on your own domain using the `ingestServer` property, so analytics traffic is delivered first-party and passes through infrastructure you can log and inspect.

#### Rationale
**Why This Matters:**
- Routing ingest through your own reverse proxy puts the analytics payload on infrastructure you operate, so you can log what is actually being sent rather than trusting that redaction rules worked
- Payload inspection at the proxy is the empirical check on every privacy control in this section — it is where you discover that a field you thought was redacted is still leaving the browser
- Inline logging of ingest traffic gives you a retrospective record for incident investigation that a direct browser-to-vendor call does not provide

**Attack Prevented:** Undetected leakage of sensitive fields in analytics payloads, blind spots in outbound data flow, absence of forensic record for analytics traffic

#### Prerequisites
- HeapJS version 5
- A reverse proxy you control on a first-party domain
- Application deployment access to change SDK initialization

#### ClickOps Implementation

**Step 1: Stand Up the Reverse Proxy**
1. Deploy a reverse proxy on a first-party hostname that forwards to Heap's ingest endpoint
2. Apply your standard hardening, TLS, and availability requirements — this proxy is now in the path of your analytics collection, so its failure mode is lost data

**Step 2: Point HeapJS at the Proxy**
1. Set the **`ingestServer`** property in the HeapJS 5 initialization to your proxy hostname
2. Deploy and confirm events are arriving in Heap as expected before removing the direct path

**Step 3: Turn On Inspection**
1. Enable inline logging at the proxy so ingest payloads are recorded
2. Sample the payloads against your redaction rules from 3.1 and 3.2 and fix any field that appears where it should not
3. Set retention on these proxy logs deliberately — they contain exactly the analytics payloads you are trying to govern, so an over-long retention here reintroduces the exposure you removed elsewhere

#### Validation & Testing
- Confirm ingest requests resolve to your first-party hostname in browser network traces
- Sample proxy-logged payloads for known-sensitive fields and confirm they are absent or redacted
- Confirm event volume in Heap is unchanged after the cutover

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Heap Control | Guide Section |
|-----------|--------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | User roles | [2.1](#21-configure-user-roles) |
| CC6.7 | Data governance | [3.1](#31-configure-data-governance) |

### NIST 800-53 Rev 5 Mapping

| Control | Heap Control | Guide Section |
|---------|--------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-6 | User roles | [2.1](#21-configure-user-roles) |
| AC-3 | Web autocapture redaction | [3.1](#31-configure-data-governance) |
| SC-28 | Mobile/native autocapture restriction | [3.2](#32-restrict-autocapture-in-mobile-and-native-sdks) |
| AU-2 | First-party ingest proxy logging | [3.3](#33-route-heap-ingest-through-a-first-party-proxy) |

---

## Appendix A: References

**Official Heap Documentation:**
- [Heap Developer Documentation](https://developers.heap.io/) — the only publicly resolvable first-party Heap documentation as of this revision; it publishes an `llms.txt` index of its pages, which is a useful map of what remains public
- [Ignoring Sensitive Data and PII](https://developers.heap.io/docs/ignoring-sensitive-data-and-pii)
- [Hide Sensitive Data (mobile and native SDKs)](https://developers.heap.io/docs/hide-sensitive-data)
- [Set Up a Proxy for Heap](https://developers.heap.io/docs/setup-proxy-for-heap)

**Documentation Availability Note:**
- Heap's help center is no longer publicly accessible: `help.heap.io` redirects to `login.contentsquare.com`, and `support.contentsquare.com` refuses anonymous requests. The former help-center references for SSO and account administration are omitted here because they can no longer be read without a customer login. Administrative guidance must be obtained through Heap's authenticated portal or your Contentsquare account team.

**Security Incidents:**
- No major public security incidents identified as of February 2026.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | ai-drafted | Heap's help center migrated behind Contentsquare authentication (help.heap.io redirects to login.contentsquare.com; support.contentsquare.com refuses anonymous requests), so every ClickOps path sourced from it is no longer publicly verifiable — added an Overview callout stating this, removed the two dead help-center references, and softened 2.1's role list and 2.2's environment-permission claims as pre-migration state. developers.heap.io is now the sole public Tier 1 anchor. Rewrote 3.1 around the real admin surface (Account > Manage > Privacy & Security and the Target Text Autocapture global toggle) plus the client-side redaction primitives data-heap-redact-text, data-heap-redact-attributes (the `id` attribute cannot be redacted), heap-ignore, and the disableTextCapture flag (which does not cover page titles); added 3.2 mobile/native autocapture restriction (disableInteractionTextCapture, disableInteractionAccessibilityLabelCapture, disablePageviewTitleCapture (iOS only), per-view redaction across UIKit/SwiftUI/Android Views/Compose/React Native/Flutter, and the ancestor-element text default) and 3.3 first-party ingest proxy via the HeapJS 5 `ingestServer` property. Removed heap.io/trust-center (now redirects to Contentsquare) and the /platform/security marketing page. Tier 2 survey found no CIS Benchmark, DISA STIG, or CISA SCuBA baseline for Heap; Tier 3/4 not surveyed this pass. | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
