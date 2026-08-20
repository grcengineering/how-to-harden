---
layout: guide
title: "Clari Hardening Guide"
vendor: "Clari"
slug: "clari"
tier: "2"
category: "Productivity"
description: "Revenue platform hardening for Clari including SAML SSO, user permissions, and forecast data security"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Clari is a revenue operations platform providing forecasting and pipeline management. As a platform handling sensitive sales data and revenue forecasts, Clari security configurations directly impact financial data protection and operational security.

### Intended Audience
- Security engineers managing revenue platforms
- IT administrators configuring Clari
- Revenue operations managers
- GRC professionals assessing sales platform security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Clari security including SAML SSO, user permissions, forecast visibility controls, API token lifecycle, and audit logging.

**Source availability caveat:** Clari publishes no public administrator or hardening documentation. The Clari knowledge base requires a customer login and `support.clari.com` does not resolve, so the console paths and plan-tier statements in this guide reflect the last verifiable state rather than a currently fetchable vendor page. The one public first-party reference is the [Clari External API specification](https://developer.clari.com/documentation/external_spec); every API path, header, and parameter cited below is transcribed from it. Verify ClickOps steps against your own tenant before relying on them.

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
Configure SAML SSO for Clari access. Clari integrates with SSO/MFA solutions via SAML 2.0.

#### Rationale
**Why This Matters:**
- Centralizes Clari authentication in the corporate IdP so every login inherits MFA, conditional access, and session policy
- Eliminates standalone Clari passwords that bypass IdP controls and are prime targets for credential stuffing and phishing
- Lets the IdP revoke access in one place when a sales rep or RevOps user leaves, closing standing access to revenue data
- Clari holds pipeline, forecast, and CRM-derived data that exposes deal strategy and financial performance, so a single rogue login can leak it

**Attack Prevented:** Credential theft, phishing, password reuse, unauthorized access to revenue data

#### Prerequisites
- Clari admin access
- Enterprise tier subscription
- Contact Clari support to enable SAML (no self-service)
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Contact Clari Support**
1. SAML configuration requires Clari support assistance
2. Request SAML SSO enablement
3. Provide IdP details

**Step 2: Configure IdP**
1. Create SAML application in IdP
2. Configure with Clari-provided settings:
   - ACS URL
   - Entity ID
   - Attribute mappings
3. Download certificate

**Step 3: Complete Configuration**
1. Work with Clari support to finalize
2. Test SSO authentication
3. Enable for users

**Note:** Directory sync works reliably with Okta. Other IdPs provide SAML SSO but no automated provisioning.

**Time to Complete:** ~2-4 hours (requires support engagement)

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Clari users via IdP integration.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks attackers who already hold a valid username and password
- Password-only access to revenue forecasts and pipeline data is trivially defeated by phishing, reuse, and brute force
- Phishing-resistant factors such as FIDO2 or WebAuthn for admins stop real-time relay and prompt-bombing attacks
- Because Clari delegates MFA to the IdP, enforcing it there guarantees coverage across every SSO login

**Attack Prevented:** Credential stuffing, phishing, password spraying, account takeover

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for admins

**Note:** Clari relies on IdP for MFA enforcement - no native MFA configuration.

---

## 2. Access Controls

### 2.1 Configure User Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege for Clari access using custom roles.

#### Rationale
**Why This Matters:**
- Least-privilege roles ensure each user can reach only the forecast and CRM data their job actually requires
- Over-broad permissions let a single compromised or curious account read the entire revenue pipeline
- Role-scoped access limits the blast radius when credentials are stolen or an insider acts maliciously
- Regular access reviews catch permission creep before it becomes an audit finding or a data-exposure path

**Attack Prevented:** Privilege escalation, insider data harvesting, lateral exposure of sensitive deals

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to Clari admin settings
2. Review available roles
3. Custom roles available at Enterprise tier

**Step 2: Apply Least Privilege**
1. Assign minimum necessary permissions
2. Control forecast visibility by role
3. Limit CRM data access based on role
4. Regular access reviews

---

### 2.2 Configure Forecast Visibility

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control who can view forecast data.

#### Rationale
**Why This Matters:**
- Forecast data reveals deal values, close probabilities, and revenue strategy that competitors and insiders would exploit
- Hierarchy-aligned visibility prevents reps on one team from viewing another team's sensitive pipeline
- Tying visibility to existing CRM access keeps Clari from becoming a backdoor around Salesforce or other CRM controls
- Scoped visibility contains exposure if a single account is compromised, rather than revealing the entire forecast

**Attack Prevented:** Unauthorized data disclosure, insider snooping, cross-team data leakage

#### ClickOps Implementation

**Step 1: Configure Visibility Rules**
1. Set forecast visibility by hierarchy
2. Limit cross-team visibility
3. Control sensitive deal access

**Step 2: Apply Data Boundaries**
1. Restrict based on CRM access
2. Align with organizational hierarchy
3. Audit visibility settings

---

### 2.3 Manage User Lifecycle

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Manage user provisioning and deprovisioning.

#### Rationale
**Why This Matters:**
- Prompt deprovisioning removes a departed employee's access before it can be used to exfiltrate revenue data
- Because Clari lacks native SCIM outside Okta directory sync, orphaned accounts persist unless lifecycle is managed deliberately
- Deactivating a user automatically revokes that user's API tokens, so deactivation — not merely stripping a role — is the step that closes programmatic access
- Documented onboarding and offboarding ensures consistent, auditable access grants and revocations
- Periodic access reviews surface dormant and orphaned accounts that attackers and insiders target

**Attack Prevented:** Orphaned-account access, post-offboarding insider data theft, standing-access abuse via a departed user's API token

#### ClickOps Implementation

**Step 1: Note SCIM Limitations**
1. Clari does not provide native SCIM
2. User management is manual (except Okta directory sync)
3. Consider third-party provisioning tools

**Step 2: Implement Manual Controls**
1. Document onboarding/offboarding process
2. Regular access reviews
3. Promptly remove departed users

**Step 3: Deactivate, Do Not Just Downgrade**
1. Make user deactivation the required offboarding action — per the [Clari API specification](https://developer.clari.com/documentation/external_spec), deactivating a user automatically revokes their API tokens
2. Removing a role or reducing permissions does **not** revoke tokens the user already generated; only deactivation does
3. Because there is no native SCIM to drive this from the IdP, add "deactivate in Clari" as an explicit item on the offboarding checklist rather than assuming IdP removal is sufficient
4. Confirm the tokens are gone by verifying that integrations authenticating as that user begin failing, or by re-running the audit export with the departed user's `actorId`

---

### 2.4 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect admin accounts.

#### Rationale
**Why This Matters:**
- Admin accounts can change permissions, alter forecasts, and reach all org data, making them the highest-value target
- Fewer admins means a smaller attack surface and fewer credentials that grant full control if compromised
- Requiring MFA and monitoring admin activity detects and slows takeover attempts on privileged accounts
- Inventorying admins prevents forgotten or excess privileged accounts from becoming silent backdoors

**Attack Prevented:** Privileged account takeover, unauthorized configuration change, undetected admin abuse

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review admin accounts
2. Document admin access

**Step 2: Apply Restrictions**
1. Limit admins to required personnel
2. Require MFA via IdP
3. Monitor admin activity via audit logs (Enterprise tier)

---

### 2.5 Govern API Token Lifecycle

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.2 |
| NIST 800-53 | AC-3, IA-5, AC-2(3) |

#### Description
Treat Clari API tokens as delegated access. Tokens are generated per user from the account menu, authenticate via the `apikey` request header, and — per the [Clari External API specification](https://developer.clari.com/documentation/external_spec) — carry no documented scopes, so a token grants whatever the issuing user can reach. Inventory who holds tokens, tie each token to a named owner and integration, and revoke on change.

#### Rationale
**Why This Matters:**
- Clari documents no token scopes, so a token is effectively a durable copy of the issuing user's full access to forecast, pipeline, and audit data — issuing one is an access-delegation decision, not a convenience
- Because a token authenticates with a single `apikey` header and no second factor, it bypasses the IdP MFA and conditional access that protect interactive logins
- The token value cannot be retrieved again after generation, so a leaked or misplaced token can only be handled by revocation and reissue — there is no way to audit the secret itself after the fact
- Revoking a token immediately breaks any integration still using it, so an undocumented token inventory turns routine credential hygiene into an unplanned outage and discourages rotation
- Tokens issued by a high-privilege user and embedded in a shared script quietly grant that privilege to everyone who can read the script

**Attack Prevented:** Standing-credential abuse, MFA bypass via long-lived API tokens, privilege inheritance through over-privileged token issuance, undetected programmatic data exfiltration

#### Prerequisites
- Clari user account permitted to generate API tokens
- A secret manager for storing issued tokens
- A named owner for every integration that consumes a Clari token

#### ClickOps Implementation

**Step 1: Locate Token Generation**
1. Select your avatar in the Clari web app
2. Navigate to: **Settings** → **API Token** tab
3. Select **Generate New API Token** and supply a token name

**Step 2: Capture the Secret Once**
1. Copy the token value at generation time — Clari states the value cannot be accessed again afterward
2. Store it in the organization's secret manager, never in a repository, ticket, or chat message
3. Record the token name, the human owner, the consuming integration, and the issue date in your credential inventory

**Step 3: Issue From Least-Privileged Accounts**
1. Because tokens inherit the issuing user's access and no scopes are documented, generate integration tokens from a purpose-built low-privilege account rather than an admin account
2. Match the issuing account's role to the narrowest forecast and CRM visibility the integration actually needs (see [2.1](#21-configure-user-permissions) and [2.2](#22-configure-forecast-visibility))
3. Never share one token across multiple integrations — shared tokens make revocation an all-or-nothing outage

**Step 4: Revoke and Rotate Deliberately**
1. Revoke tokens on owner departure, role change, suspected exposure, and on a scheduled rotation interval
2. Plan revocation as a change: revoking a token immediately breaks active integrations using it
3. For departing users, deactivate the account — deactivation automatically revokes that user's tokens (see [2.3](#23-manage-user-lifecycle))

#### Validation & Testing
1. Reconcile your credential inventory against the integrations actually calling the Clari API — any authenticated caller you cannot map to an inventoried token is an unknown credential
2. Confirm that a token issued by a deactivated user no longer authenticates (requests with that `apikey` header should be rejected)
3. Spot-check that no token value appears in source control, CI configuration, or documentation
4. Review the audit events for the token owner's `actorId` to confirm programmatic activity matches the integration's expected behavior (see [3.1](#31-configure-audit-logging))

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 5.4 | Restrict administrator privileges to dedicated accounts |
| CIS Controls v8 | 6.2 | Establish an access revoking process |
| NIST 800-53 Rev 5 | AC-2(3) | Disable accounts (and, here, the tokens they own) |
| NIST 800-53 Rev 5 | AC-3 | Access enforcement |
| NIST 800-53 Rev 5 | IA-5 | Authenticator management |
| SOC 2 | CC6.1 | Logical access credentials are managed |

---

## 3. Data Security

### 3.1 Configure Audit Logging

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs (Enterprise tier), and pull them programmatically. Clari's audit trail is not console-only: the [External API specification](https://developer.clari.com/documentation/external_spec) documents a paginated `GET /audit/events` endpoint and a queued bulk-export flow (`POST /export/audit/events` → `GET /export/jobs/{jobId}` → `GET /export/jobs/{jobId}/results`), which is what makes continuous forwarding to a SIEM possible.

#### Rationale
**Why This Matters:**
- Audit logs provide the evidence trail needed to detect, investigate, and prove the scope of a security incident
- Without logging of authentication, permission changes, and forecast edits, malicious activity goes unnoticed
- Monitoring key events enables early detection of account takeover and unauthorized data manipulation
- A documented audit API means the log can be pulled on a schedule into a SIEM instead of being reviewed ad hoc in the console, where it is only looked at after an incident is already suspected
- Export quota and concurrency figures from `GET /admin/limits` give a second signal: an unexplained spike in consumed export quota indicates someone is pulling revenue data in bulk
- Exported logs support compliance attestations such as SOC 2 and ISO 27001 and forensic reconstruction after an event

**Attack Prevented:** Undetected intrusion, repudiation, delayed breach discovery, tampering with revenue data, unnoticed bulk export of forecast and pipeline data

#### Prerequisites
- Enterprise tier (audit logs)
- A Clari API token for the collector account (see [2.5](#25-govern-api-token-lifecycle))

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Audit logs available at Enterprise tier
2. Review user activity
3. Export for analysis

**Step 2: Monitor Key Events**
1. User authentication
2. Permission changes
3. Forecast modifications

**Step 3: Schedule Programmatic Collection**
1. Issue a dedicated, least-privilege API token for the log collector rather than reusing an admin's token
2. Run the collection on a fixed interval and forward the results to the SIEM — the API is the only mechanism that makes the audit trail continuously monitorable
3. Track `availableMonthlyQuota` from `GET /admin/limits` over time and alert on unexpected consumption

#### Code Implementation

{% include pack-code.html vendor="clari" section="3.1" %}

**Endpoints used** (all authenticate with the `apikey` request header):

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/audit/events` | Paginated event retrieval (`limit` 1–1000, `dateFrom`, `dateTo`, `actorId`, `impersonatingActorId`, `sessionId`, `sessionType`, `event`; response carries `items`, `actors`, `nextLink`) |
| POST | `/export/audit/events` | Queue a bulk export; returns `jobId` |
| GET | `/export/jobs/{jobId}` | Job status (`SCHEDULED`, `STARTED`, `DONE`, `FAILED`, `CANCELLED`, `ABORTED`) |
| GET | `/export/jobs/{jobId}/results` | Download the completed export |
| PATCH | `/export/jobs/{jobId}` | Cancel an in-progress job (`{"type":"CANCEL"}`) |
| GET | `/admin/limits` | Org export concurrency and monthly quota |

#### Validation & Testing
1. Confirm `GET /audit/events` returns events for a known recent action (for example, a deliberate permission change you just made)
2. Confirm the queued export completes: the job reaches status `DONE` and `GET /export/jobs/{jobId}/results` returns content
3. Confirm the collector's events are landing in the SIEM with the expected cadence and no gaps between `dateFrom`/`dateTo` windows
4. Confirm `GET /admin/limits` returns a quota baseline you can alert against

---

## 4. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Clari Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.1 | API token lifecycle | [2.5](#25-govern-api-token-lifecycle) |
| CC6.2 | User permissions | [2.1](#21-configure-user-permissions) |
| CC7.2 | Audit logging | [3.1](#31-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Clari Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-5 | API token lifecycle | [2.5](#25-govern-api-token-lifecycle) |
| AC-2 | User lifecycle | [2.3](#23-manage-user-lifecycle) |
| AC-3 | Forecast visibility | [2.2](#22-configure-forecast-visibility) |
| AC-6 | User permissions | [2.1](#21-configure-user-permissions) |
| AU-2 | Audit logging | [3.1](#31-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Standard | Enterprise |
|---------|----------|------------|
| SAML SSO | Contact sales | ✅ |
| Custom Roles | Limited | ✅ |
| Audit Logs | ❌ | ✅ |
| SCIM | ❌ | ❌ (Okta only) |

---

## Appendix B: References

**Official Clari Documentation:**
- [Clari Community](https://community.clari.com/)
- [Vulnerability Disclosure Policy](https://www.clari.com/vulnerability-disclosure-policy/)

**Note on hardening documentation:** Clari publishes no public administrator or hardening documentation. The knowledge base is login-gated and `support.clari.com` does not resolve. `clari.com/security` is a compliance-attestation page, not configuration guidance, so it is listed under Compliance Frameworks below rather than as a hardening source. No substitute hardening link exists; none is invented here.

**API Documentation:**
- [Clari Developer Portal](https://developer.clari.com/)
- [Clari External API Specification](https://developer.clari.com/documentation/external_spec) — the only public first-party reference for API token handling, audit event retrieval, and export jobs

**Compliance Frameworks:**
- SOC 2 Type II (zero exemptions, audited by A-LIGN), ISO 27001 (certified by BSI Group with zero adverse findings) — attested on Clari's [security page](https://www.clari.com/security/), a compliance-attestation page rather than a hardening document

**Security Incidents:**
- No major public data breaches identified. Clari has experienced operational incidents (delayed data processing, module loading issues) but none involving customer data compromise.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against the Clari External API specification (the only public first-party source — KB is login-gated, `support.clari.com` does not resolve): added 2.5 API token lifecycle, documented that user deactivation auto-revokes tokens in 2.3, expanded 3.1 with the audit/export API endpoints and a new `api` Code Pack, added a source-availability caveat to Scope, and moved `clari.com/security` out of Official Documentation to Compliance Frameworks. Tier 2 (CIS/DISA/CISA SCuBA) publishes no Clari baseline; Tier 3/4 research not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
