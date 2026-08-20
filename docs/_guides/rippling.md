---
layout: guide
title: "Rippling Hardening Guide"
vendor: "Rippling"
slug: "rippling"
tier: "5"
category: "HR/Finance"
description: "Workforce platform security for app provisioning, device management, and SCIM controls"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Rippling is a unified workforce platform managing HR, IT, payroll, and spend. REST API, SSO configurations, and deep SaaS integrations through device management access employee PII, financial data, and IT systems. Compromised access has cascading effects across multiple business functions.

### Intended Audience
- Security engineers managing workforce platforms
- Rippling administrators
- GRC professionals assessing unified platform security
- Third-party risk managers evaluating HR/IT integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Rippling security configurations including authentication, access controls, API token governance, and integration security.

### Documentation Availability — Read This First

Rippling's administrator help center (`help.rippling.com`) sits behind a **full customer login wall**: it serves a sign-in page rather than article content, so admin console paths cannot be verified from a public source. The publicly reachable first-party surface is the [Rippling developer documentation](https://developer.rippling.com/documentation/rest-api), which covers the REST API, API tokens, and permission scopes.

Consequently this guide distinguishes two kinds of content:

- **Verified controls** — §2.3 and §2.4 are sourced to fetchable developer documentation.
- **Capability notes** — controls whose only public source is Rippling's own product blog are labelled inline and written as *documented capability, verify in your tenant*, not as step-by-step console instructions. Existing console paths elsewhere in this guide reflect last verification and are not externally re-verifiable.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Integration Security](#2-integration-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Configure SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with MFA for all Rippling access, routing every login through your corporate identity provider and enforcing phishing-resistant second factors.

#### Rationale
**Why This Matters:**
- Centralizes Rippling authentication in your corporate IdP, enforcing MFA and conditional access on every login
- Local password logins bypass IdP controls and are a prime target for credential stuffing and phishing
- Rippling holds HR, payroll, IT, and spend data, so a single compromised admin login can cascade across every connected business function
- Phishing-resistant MFA (FIDO2/WebAuthn) defeats real-time proxy and push-fatigue attacks that bypass weaker factors

**Attack Prevented:** Credential theft, phishing, MFA bypass, account takeover

#### ClickOps Implementation

**Step 1: Configure SSO**
1. Navigate to: **Settings → Security → Single Sign-On**
2. Configure SAML IdP
3. Enable SSO enforcement

**Step 2: Enable MFA**
1. Navigate to: **Settings → Security → Multi-Factor Authentication**
2. Require MFA for all users
3. Configure phishing-resistant methods

**Capability note — Authentication Policies (verify in your tenant).** Rippling's published security guidance describes **Authentication Policies**: scoped policies that let an administrator apply different MFA requirements, session-timeout values, and password rules to different groups of users rather than applying one setting tenant-wide. Rippling's guidance specifically recommends requiring a hardware security key for accounts holding SuperAdmin privileges, and using the scoping to hold administrators to stricter session and factor requirements than the general workforce.

The only public source for this capability is Rippling's product blog under a named author ([Seven powerful, simple steps to secure your Rippling tenant](https://www.rippling.com/blog/seven-powerful-simple-steps-to-secure-your-rippling-tenant)); the corresponding administrator documentation is customer-gated, so no console path is asserted here. Confirm the exact policy surface and option names in your own tenant before writing a change plan around it.

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define least-privilege permission sets and custom roles so each administrator and employee can access only the HR, IT, finance, or self-service functions their job requires.

#### Rationale
**Why This Matters:**
- Rippling spans HR, payroll, device management, and spend, so broad admin grants give any single compromised account control over multiple business domains
- Least-privilege roles contain the blast radius of a stolen or misused credential to one functional area
- Separating HR, IT, and finance duties enforces segregation of duties and limits insider abuse
- Custom permission sets prevent privilege creep as employees change teams and accumulate access

**Attack Prevented:** Privilege escalation, lateral movement, insider abuse, excessive standing access

#### ClickOps Implementation

**Step 1: Define Permission Sets**

| Role | Permissions |
|------|-------------|
| Super Admin | Full access |
| HR Admin | HR/payroll functions |
| IT Admin | Device/app management |
| Finance Admin | Spend management |
| Manager | Team access |
| Employee | Self-service |

**Step 2: Configure Custom Roles**
1. Navigate to: **Settings → Permissions**
2. Create custom permission sets
3. Apply least privilege

---

## 2. Integration Security

### 2.1 App Management Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Secure Rippling app integrations.

#### Rationale
**Attack Scenario:** Compromised Rippling admin provisions access to connected apps; single compromise cascades across all integrated SaaS.

**Why This Matters:**
- Rippling acts as an identity and provisioning hub, so a compromised admin can grant or modify access across every connected SaaS application
- Unused or orphaned app integrations widen the attack surface and often retain standing OAuth grants long after they are needed
- Over-scoped SCIM auto-provisioning can silently push access or accounts into downstream apps without review
- Regular review of connected apps and deprovisioning flows ensures departed users lose access everywhere, not just in Rippling

**Attack Prevented:** Supply chain compromise, OAuth token abuse, orphaned-account access, over-provisioning

#### ClickOps Implementation

**Step 1: Review Connected Apps**
1. Navigate to: **Apps → Installed Apps**
2. Audit all connected applications
3. Remove unused integrations

**Step 2: SCIM Security**
1. Review SCIM provisioning
2. Limit auto-provisioning scope
3. Audit deprovisioning

---

### 2.2 Device Management Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Configure device management policies in Rippling IT to require enrollment and enforce baseline security controls on every endpoint that accesses workforce data.

#### Rationale
**Why This Matters:**
- Devices enrolled through Rippling access corporate apps and employee PII, so unmanaged endpoints are a direct path into sensitive data
- Enforced enrollment and security policies such as encryption, screen lock, and OS patching reduce data loss from lost or stolen devices
- Device posture checks let you block compromised or non-compliant endpoints before they reach connected SaaS
- Centralized device control supports rapid remote wipe and access revocation during offboarding or incidents

**Attack Prevented:** Endpoint compromise, data exfiltration from lost/stolen devices, non-compliant device access

#### ClickOps Implementation

**Step 1: Device Policies**
1. Navigate to: **IT → Device Management**
2. Configure security policies
3. Require device enrollment

---

### 2.3 Govern Rippling API Tokens

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-2, AC-6, IA-5, AU-2

#### Description
Inventory and govern the API tokens issued under **Tools → Developer → API Tokens**, treating each token as a derivative of its owner's account: restrict who may create and manage tokens, keep every token owned by an account whose permissions are already least-privilege, and use the `Last accessed` field to retire tokens nobody is using.

#### Rationale
**Why This Matters:**
- A Rippling API token's effective access is the **intersection of the token owner's own permissions and the scopes selected on the token** — so an over-privileged owner is an over-privileged token, and the owner's account permissions, not the token, are the real control surface
- Because that access is derived live, **changes to the owner's permissions propagate to their tokens**: promoting an employee silently widens every token they own, and demoting them can break integrations without any token being edited
- Rippling exposes two levels of app permission — one that can view all tokens in the tenant, edit their metadata, and revoke any of them, and one that limits a user to their own tokens; the broader level is what an attacker needs to inventory or kill your integrations, and Rippling's guidance is to grant it only to IT or security staff
- Rippling automatically revokes a token when its owner is terminated **or when the token has gone more than 30 days without use** — good hygiene, but it also means an integration built on a rarely-run job can die silently, and it means offboarding is doing security work your inventory should be doing deliberately
- Tokens authenticate as bearer credentials against `rest.ripplingapis.com`, so a leaked token is directly replayable from anywhere with no interactive login and no MFA prompt in the path

**Attack Prevented:** Over-privileged machine credentials, privilege inheritance through owner promotion, bearer-token replay, orphaned integration access, unmonitored token sprawl

#### Prerequisites
- Access to **Tools → Developer → API Tokens**
- Agreement on which team owns integration credentials (IT or security, per Rippling's own recommendation)

#### ClickOps Implementation

**Step 1: Inventory Existing Tokens**
1. Navigate to: **Tools → Developer → API Tokens**
2. Record, for every token: its owner, its selected scopes, and its `Last accessed` timestamp
3. Flag any token whose owner is a person rather than a purpose-built integration identity, and any token approaching the 30-day inactivity revocation window

**Step 2: Constrain Token Management Permissions**
1. Review which users hold the broader app permission level — the one that can view all tokens, edit token metadata, and revoke any token
2. Grant that level only to IT or security staff, per Rippling's guidance; everyone else should be limited to managing their own tokens
3. Re-check this grant whenever roles change, since token-management authority is itself a path to disrupting or enumerating every integration

**Step 3: Right-Size Token Owners**
1. For each token, confirm the owner account's permissions are already least-privilege — the token cannot be narrower than that intersection allows, and widening the owner widens the token
2. Move tokens off individual employee accounts onto dedicated integration identities so a promotion or role change does not silently expand API access
3. Re-verify token access after any permission change to an owner account

**Step 4: Retire and Rotate**
1. Revoke tokens with no recent `Last accessed` activity rather than waiting for the automatic 30-day revocation
2. Revoke and reissue immediately when a token may have been exposed, when an owner changes role, and as part of offboarding — do not rely solely on Rippling's automatic revocation on termination
3. Store bearer tokens in a secrets manager; keep them out of source control, logs, and email

#### Validation & Testing
- Confirm every live token maps to a named integration and a purpose-built owner identity
- Confirm the list of users holding all-token view/edit/revoke permission matches the IT/security roster exactly
- Confirm no token's `Last accessed` value is stale relative to the integration's expected schedule
- Confirm a revoked token's request to `rest.ripplingapis.com` is rejected

**Source:** [Rippling REST API — API tokens](https://developer.rippling.com/documentation/rest-api/essentials/api-tokens)

---

### 2.4 Grant Minimum API Scopes

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-6, CM-7

#### Description
Select the narrowest scope set on every Rippling API token, choosing the read-only scope for each resource unless the integration genuinely writes to it — Rippling publishes separate read and read-write scopes per resource precisely so integrations can be granted the minimum.

#### Rationale
**Why This Matters:**
- Rippling's permission model exposes **per-resource read and read-write scopes**, and Rippling's own documented guidance is to request only the minimum scopes an application needs — a read-only integration that holds write scopes is a mutation capability sitting idle waiting to be abused
- Scope selection is the only part of a token's access that you control independently of the owner account: since effective access is the intersection of owner permissions and selected scopes, scopes are the tighter of the two levers and the one that does not drift when someone gets promoted
- Write scopes on a workforce platform are not read-equivalent risk — they reach employment records, provisioning, and pay-adjacent data, so a compromised read-write token can change state across connected systems rather than merely disclosing it
- Over-scoping is invisible in normal operation: nothing fails when a token holds scopes it never exercises, so it survives every functional test and is only caught by explicit scope review

**Attack Prevented:** Excessive API authorization, unauthorized data modification through an over-scoped read integration, blast-radius expansion after token compromise

#### ClickOps Implementation

**Step 1: Derive the Required Scope Set**
1. List every Rippling resource the integration actually touches, and whether it reads or writes each one
2. Map each entry to the corresponding scope, choosing the read scope wherever the integration only reads
3. Reject any scope that cannot be tied to a specific documented call the integration makes

**Step 2: Apply and Review**
1. Create the token under **Tools → Developer → API Tokens** with exactly that scope set
2. Re-review scopes whenever the integration's functionality changes — expand deliberately, never pre-emptively
3. Reissue with a narrower scope set rather than editing behaviour around an over-broad token

#### Validation & Testing
- For each token, confirm every granted scope corresponds to a call the integration demonstrably makes
- Confirm read-only integrations hold no read-write scopes
- Confirm a write call from a read-scoped token is rejected

**Source:** [Rippling REST API — permissions and scopes](https://developer.rippling.com/documentation/rest-api/essentials/permissions)

---

## 3. Data Security

### 3.1 Protect Employee Data

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Restrict field-level visibility and reporting so sensitive employee data such as SSNs, bank accounts, and compensation is exposed only to roles with a legitimate need.

#### Rationale
**Why This Matters:**
- Rippling stores highly sensitive PII and financial data that carries legal, regulatory, and identity-theft consequences if exposed
- Field-level access controls enforce need-to-know and prevent managers or analysts from viewing data outside their scope
- Limiting bulk exports and report access stops large-scale data scraping by a single compromised or malicious account
- Auditing data access creates accountability and supports breach detection and compliance evidence

**Attack Prevented:** PII exposure, identity theft, mass data exfiltration, unauthorized data access

#### ClickOps Implementation

**Step 1: Configure Field Access**
1. Limit visibility of sensitive fields
2. Restrict SSN/bank account access
3. Configure manager visibility

**Step 2: Report Security**
1. Limit report access
2. Restrict bulk exports
3. Audit data access

---

### 3.2 Payroll Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** SC-28

#### Description
Limit payroll administrator access and require approvals for payroll changes so direct-deposit and compensation modifications cannot be made by a single unchecked account.

#### Rationale
**Why This Matters:**
- Payroll controls direct-deposit destinations and pay amounts, making it a high-value target for financial fraud
- Restricting payroll admin access reduces the number of accounts that can redirect funds or alter compensation
- Requiring approval for payroll changes enforces dual control and catches fraudulent or erroneous edits before money moves
- Tight payroll permissions limit the damage an attacker or malicious insider can do with a single compromised credential

**Attack Prevented:** Payroll diversion fraud, direct-deposit hijacking, unauthorized compensation changes, insider fraud

#### ClickOps Implementation

**Step 1: Payroll Access**
1. Navigate to: **Settings → Permissions**
2. Limit payroll admin access
3. Require approval for changes

---

## 4. Monitoring & Detection

### 4.1 Audit Logs

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable and regularly review Rippling audit logs to capture administrative activity and configuration changes across HR, IT, payroll, and access management.

#### Rationale
**Why This Matters:**
- Audit logs provide the forensic record needed to detect, investigate, and scope unauthorized activity across Rippling's many functions
- Monitoring admin actions and configuration changes surfaces privilege abuse, suspicious provisioning, and policy weakening early
- Without comprehensive logging, attacker and insider activity goes unnoticed and breaches are impossible to reconstruct
- Retained audit trails support compliance obligations such as SOC 2 and ISO 27001 and provide incident response evidence

**Attack Prevented:** Undetected intrusion, insider abuse, audit-trail gaps, delayed breach detection

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Settings → Audit Logs**
2. Review admin activities
3. Monitor configuration changes

#### Detection Focus

Prioritise these events when reviewing or alerting on Rippling audit activity:

- **API token lifecycle** — token creation, scope changes, and revocations, plus tokens whose `Last accessed` value jumps after a long dormancy (see [2.3](#23-govern-rippling-api-tokens))
- **Permission and role changes** — any grant of the all-token view/edit/revoke permission, any promotion of an account that owns API tokens, and any widening of a custom permission set
- **Payroll and banking changes** — direct-deposit and compensation edits, especially outside a pay-run window or from an account that does not normally make them
- **App and SCIM provisioning** — new app connections, changes to auto-provisioning scope, and bulk provisioning or deprovisioning events
- **Authentication anomalies** — repeated failed sign-ins, sign-ins from new devices or unusual locations, and MFA method changes on administrator accounts
- **Offboarding gaps** — terminated users whose sessions, tokens, or app grants persist after their termination date

---

### 4.2 Configure Behavioral Detection Rules

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2(12), SI-4

#### Description
Use Rippling's behavioral detection rules to evaluate each sign-in against contextual signals — location, device, IP address, and recent failed attempts — and to act automatically on suspicious sign-ins by blocking them, shortening the session lifetime, or requiring an additional MFA challenge.

#### Rationale
**Why This Matters:**
- Static authentication policy treats every successful credential presentation identically; behavioral evaluation adds the context that distinguishes a routine login from a session an attacker just bought or phished
- Signals such as an unfamiliar device, an unexpected geography, a new IP, or a run of recent failed attempts are precisely the residue that credential-stuffing and session-theft campaigns leave behind before the account is used
- Because the rules can act rather than merely alert — block the sign-in, cut the session lifetime, or force a step-up MFA challenge — they close the window between detection and human response, which is the window attackers actually operate in
- Impossible-travel logic is the clearest example: Rippling's published guidance describes flagging sign-ins that would require travel faster than roughly 650 mph between consecutive locations, which no legitimate user produces but a shared or stolen session routinely does
- Rippling brokers HR, IT, payroll, and spend, so an unchallenged suspicious session is not a single-app problem — it is a foothold in the platform that provisions access to everything else

**Attack Prevented:** Session hijacking, credential stuffing, account takeover from stolen sessions, sign-ins from attacker infrastructure or unmanaged devices

#### Implementation

**Sourcing note:** this capability is described in Rippling's published security guidance under a named author; the corresponding administrator documentation is customer-gated, so no console path is asserted below. Verify the exact rule surface, signal names, and available actions in your own tenant before building a change plan.

**Step 1: Confirm the Capability and Its Signals**
1. Locate the behavioral detection rule surface in your tenant's security settings
2. Confirm which sign-in signals are available for evaluation — location, device, IP address, and recent failed-attempt count are the documented ones
3. Confirm which actions your plan exposes: block the sign-in, shorten the session lifetime, or require an additional MFA challenge

**Step 2: Start with High-Confidence Rules**
1. Enable an impossible-travel rule first — it produces the fewest false positives of any behavioral signal
2. Add rules for sign-ins from unrecognised devices and for sign-ins following a burst of failed attempts
3. Apply the strictest action (block) to administrator accounts and a step-up MFA challenge to the general workforce, so a false positive costs a prompt rather than an outage

**Step 3: Tune and Monitor**
1. Run new rules in the least disruptive action for a short observation period and review what they would have caught
2. Escalate the action once the false-positive rate is understood
3. Feed rule hits into the audit-log review in [4.1](#41-audit-logs) so blocked and challenged sign-ins are investigated, not just prevented

#### Validation & Testing
- Confirm a test sign-in from an unrecognised device triggers the configured action
- Confirm administrator accounts are covered by the strictest rule set
- Confirm rule hits appear in audit logs and reach whoever reviews them

**Source:** [Seven powerful, simple steps to secure your Rippling tenant](https://www.rippling.com/blog/seven-powerful-simple-steps-to-secure-your-rippling-tenant) (Rippling product blog, named author — administrator documentation is customer-gated)

---

## Appendix A: Feature Availability

| Control | Availability |
|---------|--------------|
| SAML SSO | ✅ |
| MFA | ✅ |
| Custom Roles | ✅ |
| Audit Logs | ✅ |
| SCIM | ✅ |
| API Tokens (scoped, auto-revoking) | ✅ |
| Per-resource read / read-write scopes | ✅ |

---

## Appendix B: References

**API & Developer Resources (the reachable first-party surface):**
- [REST API Documentation](https://developer.rippling.com/documentation/rest-api)
- [API tokens](https://developer.rippling.com/documentation/rest-api/essentials/api-tokens) — token ownership model, permission levels, automatic revocation, `Last accessed`
- [Permissions and scopes](https://developer.rippling.com/documentation/rest-api/essentials/permissions) — per-resource read vs read-write scopes and the minimum-scope requirement

**Rippling Published Security Guidance (capability-level only):**
- [Seven powerful, simple steps to secure your Rippling tenant](https://www.rippling.com/blog/seven-powerful-simple-steps-to-secure-your-rippling-tenant) — product blog under a named author; the source for the Authentication Policies capability note in [1.1](#11-configure-sso-with-mfa) and for [4.2](#42-configure-behavioral-detection-rules). Capability-level only: it does not provide administrator console steps.

**Documentation Not Cited (and why):**
- `help.rippling.com` — Rippling's administrator help center is behind a full customer login wall and serves a sign-in page to any unauthenticated request, with no public API fallback. It is not usable as a verifiable source and is deliberately not linked.
- `rippling.com/security` — redirects to Rippling's trust/marketing page; not hardening documentation.
- `trust.rippling.com` — compliance-attestation surface, not configuration guidance.

**Compliance & Certifications:**
- Rippling's attestation status (SOC reports, ISO certificates, CSA STAR) is published through its Trust Center, which is an attestation surface rather than hardening documentation and is not cited here as a control source. Request current attestations directly from Rippling.
- No Tier 2 baseline covers Rippling: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for the platform.

**Security Incidents:**
- **Deel Corporate Espionage Incident (March 2025):** Rippling filed a lawsuit against competitor Deel alleging a planted insider (spy) who accessed proprietary sales data, customer information, and competitive intelligence via Slack over several months. This was not a platform breach -- it was an insider threat from a Deel-affiliated employee. Rippling detected the scheme using a honeypot trap.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass. Added 2.3 (API token governance — owner-permissions ∩ scopes model, permission-change propagation, the two app permission levels, automatic revocation on termination or 30 days unused, `Last accessed` auditing) and 2.4 (minimum-scope requirement — per-resource read vs read-write scopes), both sourced to `developer.rippling.com`. Added 4.2 (behavioral detection rules — sign-in evaluation on location/device/IP/failed attempts with block, session-lifetime, and step-up MFA actions, including the impossible-travel example) and an Authentication Policies capability note in 1.1; both are sourced only to Rippling's product blog under a named author, so they carry an inline sourcing caveat and are written as documented-capability-verify-in-tenant rather than console steps. Filled the previously empty Detection Focus under 4.1. Purged `rippling.com/security` (301s to the trust marketing page) and `trust.rippling.com` from Appendix B, and demoted `help.rippling.com` — it is a full login wall with no public API fallback, so it is documented as not-citable rather than linked. Tier 2 bodies surveyed with zero coverage confirmed: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for Rippling. Tier 3/4 product-specific research not surveyed this pass. **Structural gap for a future pass:** this guide still has no Compliance Quick Reference section; building one was deferred because no verified mapping content exists yet. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Rippling hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
