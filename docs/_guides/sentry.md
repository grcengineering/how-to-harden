---
layout: guide
title: "Sentry Hardening Guide"
vendor: "Sentry"
slug: "sentry"
tier: "2"
category: "DevOps"
description: "Application monitoring platform hardening for Sentry including SAML SSO, team access, data scrubbing, and integration security"
version: "0.2.1"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Sentry is a leading application monitoring and error tracking platform. As a platform receiving application errors, stack traces, and potentially sensitive data, Sentry security configurations directly impact data privacy and debugging security.

### Intended Audience
- Security engineers managing monitoring platforms
- IT administrators configuring Sentry
- DevOps teams managing application monitoring
- GRC professionals assessing observability security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Sentry security including SAML SSO, team access, data scrubbing, and DSN security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Data Security](#3-data-security)
4. [Monitoring & Compliance](#4-monitoring--compliance)
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
Configure SAML SSO to centralize authentication for Sentry users.

#### Rationale
**Why This Matters:**
- Centralizes Sentry login in your corporate IdP so MFA, conditional access, and session policies apply on every authentication
- Local Sentry passwords bypass IdP controls and are prime targets for credential stuffing and phishing
- IdP-driven provisioning and deprovisioning removes departed employees automatically, eliminating orphaned accounts with standing access to error data
- Sentry events expose stack traces, request payloads, and environment details that map your application's internals, so a single compromised login can reveal them all

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

**Cheaper plans have a real SSO option — do not skip SSO because SAML2 is out of reach.** Sentry offers Google Business App SSO and GitHub Organization SSO starting on the Trial and Team plans, while SAML2 and SCIM provisioning require Business or Enterprise. A Team-plan organization that federates through Google or GitHub is meaningfully better off than one running local Sentry passwords. ([Single Sign-On](https://docs.sentry.io/organization/authentication/sso/))

**Supported SAML2 providers** include Auth0, Azure Active Directory, Okta, OneLogin, Rippling, and JumpCloud, plus a generic SAML2 option for other IdPs.

**Two SSO defaults deserve attention at rollout:**
- New members provisioned through SSO default to the **Member** role **on all teams** — if your teams are meant to segment access to production error data ([2.1](#21-configure-team-access), [2.2](#22-configure-project-access)), that default undoes the segmentation for every new joiner. Decide the intended default before enabling SSO.
- Sessions default to a **two-week** lifetime. Shorten it if your risk tolerance requires more frequent reauthentication.

#### Prerequisites
- Sentry organization owner access
- Business or Enterprise tier for SAML2 and SCIM; Trial/Team plans can use Google Business App or GitHub Organization SSO
- SAML 2.0 compatible IdP (for SAML2)

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Auth**
2. Select **Configure** for SAML2 (or for Google/GitHub SSO on Trial/Team plans)

**Step 2: Configure SAML**
1. Configure IdP settings:
   - Entity ID
   - SSO URL
   - Certificate
2. Configure attribute mapping
3. Download Sentry metadata for IdP

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback
4. Set the default role and team assignment for SSO-provisioned members deliberately rather than accepting member-on-all-teams
5. Review the session lifetime against your reauthentication policy

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Guarantee a second factor on every Sentry login by picking the one mechanism your organization can actually use: enforce MFA at your identity provider if you run SSO, or enable Sentry's **Require 2FA** setting if you do not — Sentry does not support both at once.

#### Rationale
**Why This Matters:**
- A second factor blocks account takeover even when a password is phished, guessed, or reused from another breach
- Sentry accounts can read error reports containing sensitive data and can alter project, alerting, and DSN settings
- Phishing-resistant factors for owners and admins protect the accounts with the broadest blast radius
- Because Sentry's own enforcement and SSO are mutually exclusive, an organization that enables SSO and then assumes Require 2FA is also protecting it has a gap that only the IdP can close

**Attack Prevented:** Credential stuffing, password reuse, account takeover, phishing

**Correction — Require 2FA and SSO cannot both be used.** Sentry's documentation states that "Require 2FA is currently not available with single sign-on (SSO)." Earlier versions of this guide implied you should configure SSO ([1.1](#11-configure-saml-single-sign-on)) and then also enable Require 2FA — that sequence leads to an impossible state. Treat this control as an either/or decision:

| Your setup | How the second factor is enforced |
|------------|-----------------------------------|
| SSO enabled (SAML2, Google, or GitHub) | Enforce MFA in your identity provider. Sentry's Require 2FA setting is not available to you. |
| No SSO | Enable Sentry's **Require 2FA** organization setting. |

Source: [Two-Factor Authentication](https://docs.sentry.io/organization/authentication/two-factor-authentication/)

**Enabling Require 2FA removes members who have not enrolled.** When an Owner turns the setting on, organization members without 2FA configured are removed from the organization: they lose access and stop receiving notifications, they are sent an email explaining how to set up 2FA, and they can be reinstated within a **three-month** window. Sequence the rollout — announce it, verify enrollment, then enable — rather than flipping it and absorbing the outage.

#### Prerequisites
- **Owner** role in the Sentry organization
- No SSO configured (if SSO is configured, enforce MFA at the IdP instead)

#### ClickOps Implementation

**Path A — SSO organizations: enforce MFA at the IdP**
1. Enable MFA in your identity provider for the Sentry application
2. Require phishing-resistant methods (WebAuthn/security keys) for owners and admins
3. Verify enforcement by attempting a Sentry login and confirming the IdP challenges for a second factor

**Path B — non-SSO organizations: enable Require 2FA in Sentry**
1. Announce the change and give members a deadline to enroll, since non-enrolled members will be removed
2. As an Owner, navigate to: **Organization Settings** → **General Settings** → **Security & Privacy**
3. Enable **Require Two-Factor Authentication**
4. Track removed members and reinstate them as they enroll — the reinstatement window is three months

---

## 2. Access Controls

### 2.1 Configure Team Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Sentry teams.

#### Rationale
**Why This Matters:**
- Team-scoped access limits each member to only the projects and error data they need, shrinking the blast radius of any one compromised account
- Over-broad organization roles let a single user read every project's stack traces and modify settings across the org
- Function- or product-aligned teams make access reviews and offboarding straightforward and auditable
- Least privilege contains insider misuse and limits lateral movement after a credential compromise

**Attack Prevented:** Privilege escalation, lateral movement, insider data access, excessive exposure

#### ClickOps Implementation

**Step 1: Create Teams**
1. Navigate to: **Settings** → **Teams**
2. Create teams by function/product
3. Assign projects to teams

**Step 2: Configure Member Roles**
1. Review organization roles:
   - Owner
   - Manager
   - Admin
   - Member
2. Assign minimum necessary role
3. Regular access reviews

---

### 2.2 Configure Project Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control access to specific projects.

#### Rationale
**Why This Matters:**
- Restricting projects to specific teams keeps sensitive production error data away from members who have no business reason to see it
- Separating production from lower environments prevents broad, cross-project visibility into customer-facing systems
- Per-project permissions enforce data segmentation and support compliance and tenant boundaries
- Auditing project access surfaces stale or over-broad grants before they are abused

**Attack Prevented:** Unauthorized data access, lateral movement, data-segregation failures

#### ClickOps Implementation

**Step 1: Configure Project Teams**
1. Assign projects to specific teams
2. Limit cross-team access
3. Separate production projects

**Step 2: Configure Permissions**
1. Set team-level permissions
2. Restrict sensitive projects
3. Audit project access

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
- Owner and admin accounts can change SSO, billing, DSNs, data scrubbing, and member roles, giving them full control over the organization's security posture
- Keeping the number of privileged accounts small reduces the attack surface attackers can target
- Requiring SSO and 2FA on every admin account hardens the highest-value logins against takeover
- Monitoring admin activity gives early warning of misuse or a compromised privileged session

**Attack Prevented:** Privileged-account takeover, configuration tampering, insider abuse, security-control rollback

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review owners and admins
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit owner to 2-3 users
2. Require 2FA/SSO for admins
3. Monitor admin activity

#### Code Implementation

{% include pack-code.html vendor="sentry" section="2.3" %}

---

### 2.4 Use Organization Auth Tokens for Automation

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 3.11 |
| NIST 800-53 | AC-6, IA-5 |

#### Description
Use **organization auth tokens** for CI/CD and automation, and keep **personal auth tokens** out of shared pipelines entirely — a personal token carries its owner's access across every Sentry organization they belong to, and it dies when they leave.

#### Rationale
**Why This Matters:**
- A personal auth token is scoped to the **user**, not to one organization: it can reach every organization that user is a member of, so a personal token committed to a build config quietly grants cross-organization access far beyond the project it was added for
- Personal tokens are revoked when the member is removed, which means a pipeline depending on one breaks at offboarding — the operational failure is what pushes teams to share tokens or re-add departed accounts
- Organization tokens are bound to a single organization with a fixed permission set, and any owner or manager can revoke one without touching a person's account
- Knowing that personal and organization token permissions are immutable after creation changes the process: reducing a token's access means issuing a replacement and revoking the original, not editing it

**Attack Prevented:** Cross-organization access via leaked personal tokens, standing access after offboarding, over-privileged CI credentials, unrevocable shared credentials

**Pick the token type deliberately:**

| Token type | Scope | Permissions | Where to use it |
|------------|-------|-------------|-----------------|
| Organization auth token | One organization | Fixed at creation, not editable | CI/CD and automation — the recommended default |
| Personal auth token | The user, across **all** organizations they belong to | Fixed at creation, not editable; revoked when the member is removed | A person's own local scripts only — never in shared pipelines |
| Internal integration token | One organization | Full API access, permissions **are** editable | Org-specific integrations needing broad or changing access |

**L1 posture: organization tokens in CI, never personal tokens.**

#### ClickOps Implementation

**Step 1: Create Organization Tokens**
1. Navigate to: **Settings** → **Developer Settings** → **Organization Tokens**
2. Create a token per pipeline or per purpose, so revoking one does not break everything
3. Record the token's purpose and owning team — permissions cannot be changed later, so the record is how you know when to reissue

**Step 2: Purge Personal Tokens from Shared Automation**
1. Audit CI/CD secret stores, build configs, and release scripts for personal auth tokens
2. Replace each with a purpose-scoped organization token
3. Revoke the personal tokens once the replacement is verified

**Step 3: Establish Revocation Ownership**
1. Confirm that owners and managers know they can revoke organization tokens directly
2. Add token revocation to your incident-response and offboarding runbooks
3. Reissue rather than edit when a token's access needs to shrink

#### Validation & Testing
Search your CI configuration and secret manager for Sentry tokens and confirm each one is an organization token. Verify revocation works by revoking a test token and confirming the associated API call fails.

Source: [Auth Tokens](https://docs.sentry.io/account/auth-tokens/)

---

## 3. Data Security

### 3.1 Configure Data Scrubbing

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SI-12 |

#### Description
Scrub sensitive data from error reports.

#### Rationale
**Why This Matters:**
- Stack traces and request payloads frequently capture passwords, tokens, session cookies, and PII that should never be stored in a monitoring system
- Server-side scrubbing provides a backstop, while client-side beforeSend filtering keeps sensitive values from ever leaving the application
- Minimizing stored sensitive data shrinks the impact of any breach and supports GDPR, HIPAA, and PCI obligations
- Unscrubbed secrets captured in events become live credentials anyone with Sentry access can harvest

**Attack Prevented:** Sensitive-data exposure, secret leakage, PII overcollection, compliance violations

#### ClickOps Implementation

**Step 1: Enable Server-Side Scrubbing**
1. Navigate to: **Settings** → **Security & Privacy**
2. Enable **Data Scrubber**
3. Configure sensitive fields

**Step 2: Configure Client-Side Scrubbing**
1. Use SDK beforeSend hooks
2. Filter PII before transmission
3. Test scrubbing effectiveness

**Step 3: Configure Defaults**
1. Enable default safe fields
2. Add custom sensitive fields
3. Document scrubbing rules

**Step 4: Add Advanced Data Scrubbing Rules**
1. Navigate to: **Settings** → **Security and Privacy** at the organization level, and again at the project level for project-specific rules
2. In **Advanced Data Scrubbing**, build each rule from three parts:
   - **Method** — Remove, Mask, Hash, or Replace
   - **Data Type** — credit card numbers, passwords, IP addresses, email addresses, UUIDs, US Social Security numbers, MAC addresses, or a custom regular expression
   - **Source** — a selector naming where to apply it, such as `$string`, `$error.value`, `extra.**`, or `$user.ip_address`
3. Order matters: rules run in sequence, so put broad removals after the narrower transformations you want preserved

**Advanced rules override Safe Fields.** A field you added to Safe Fields is **not** protected from an advanced data scrubbing rule that matches it — the advanced rule wins. If a value is disappearing from events despite being marked safe, look for the advanced rule that is matching it before assuming a bug. ([Advanced Data Scrubbing](https://docs.sentry.io/security-legal-pii/scrubbing/advanced-datascrubbing/))

**Scrubbing has sibling surfaces that are easy to forget:** event **attachments** (crash dumps, screenshots, logs) and **Session Replay** each have their own privacy configuration. Scrubbing event bodies while shipping unredacted attachments or replays leaves the same data exposed by a different path. ([Scrubbing sensitive data](https://docs.sentry.io/security-legal-pii/scrubbing/))

---

### 3.2 Configure DSN Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Secure Data Source Names (DSNs).

#### Rationale
**Why This Matters:**
- A leaked DSN lets anyone submit arbitrary events to your project, polluting error data and burning your event quota
- Rate limits and quotas on each DSN contain abuse and prevent denial of service through event flooding
- Rotating compromised DSNs promptly cuts off attackers without disrupting legitimate clients
- Tracking DSN usage makes it possible to detect anomalous ingestion and unauthorized clients

**Attack Prevented:** DSN abuse, event flooding, quota exhaustion, data poisoning

#### ClickOps Implementation

**Step 1: Review DSNs**
1. Navigate to: **Project Settings** → **Client Keys (DSN)**
2. Review all DSNs
3. Document DSN usage

**Step 2: Configure Rate Limiting**
1. Configure DSN rate limits
2. Set event quotas
3. Alert on abuse

**Step 3: Rotate If Needed**
1. Rotate compromised DSNs
2. Update applications
3. Disable old DSNs

#### Code Implementation

{% include pack-code.html vendor="sentry" section="3.2" %}

---

### 3.3 Configure IP Filtering

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17 |

#### Description
Filter events by IP address.

#### Rationale
**Why This Matters:**
- Restricting event ingestion to known network ranges blocks spoofed or junk events submitted with a leaked DSN from unexpected sources
- Filtering reduces noise and prevents attackers from flooding projects with bogus data that masks real errors
- IP allowlists add a network-layer control on top of DSN secrecy, enforcing defense in depth
- Documented filtering rules make ingestion sources auditable and anomalies easy to spot

**Attack Prevented:** Event spoofing, data poisoning, quota exhaustion, ingestion abuse

#### ClickOps Implementation

**Step 1: Configure Allowed IPs**
1. Configure IP filters for projects
2. Filter internal networks
3. Document filtering rules

---

### 3.4 Deploy Relay for In-Network PII Scrubbing

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 13.5 |
| NIST 800-53 | SI-12, SC-7 |

#### Description
Relay is a standalone Sentry service you run inside your own network: SDKs send events to Relay, Relay scrubs PII according to centrally managed configuration, and only the scrubbed event leaves your perimeter.

#### Rationale
**Why This Matters:**
- Server-side scrubbing ([3.1](#31-configure-data-scrubbing)) happens **after** the raw event reaches Sentry — Relay moves the scrubbing boundary inside your network so sensitive values never cross it at all
- Client-side `beforeSend` filtering depends on every SDK in every service being configured correctly; Relay enforces the policy centrally regardless of what individual applications do
- For regulated workloads where a data-protection obligation attaches at the point of egress, "we scrub it at the vendor" is a materially weaker answer than "it never left"
- Relay also functions as an opaque proxy, letting you restrict application outbound traffic to a single custom domain you control instead of allowing direct connections to Sentry's ingest endpoints

**Attack Prevented:** PII egress before scrubbing, SDK misconfiguration leaking sensitive fields, uncontrolled outbound connections from application hosts

#### Prerequisites
- Infrastructure to run and operate the Relay service (it is a service you host, monitor, and keep patched)
- Network paths from application hosts to Relay, and from Relay outbound to Sentry

#### ClickOps Implementation

**Step 1: Deploy Relay**
1. Stand up Relay inside your network following Sentry's Relay documentation
2. Point your SDK DSNs at the Relay endpoint rather than directly at Sentry
3. Verify events arrive in Sentry through Relay before decommissioning any direct path

**Step 2: Centralize Scrubbing Configuration**
1. Manage PII scrubbing rules centrally in Relay so policy does not depend on per-service SDK configuration
2. Mirror the data types covered by your Advanced Data Scrubbing rules ([3.1](#31-configure-data-scrubbing)) so the two layers do not disagree
3. Review the configuration whenever a new service starts sending events

**Step 3: Use Relay as an Egress Chokepoint**
1. Configure Relay as an opaque proxy on a custom domain
2. Restrict application hosts' outbound HTTP so Sentry traffic must traverse Relay
3. Monitor Relay for availability — it is now in the ingestion path

#### Validation & Testing
Send a test event containing a known sensitive value from an application host and confirm the value is absent in the event Sentry receives. Confirm from an application host that direct connections to Sentry's ingest endpoints are blocked and only the Relay domain is reachable.

Source: [Relay](https://docs.sentry.io/product/relay/)

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

#### Rationale
**Why This Matters:**
- Audit logs record authentication, permission changes, DSN modifications, and data access so security-relevant actions are attributable
- Without a reliable log trail, account compromise and configuration tampering can go undetected and unattributed
- Monitoring permission and DSN changes catches privilege escalation and exfiltration setup early
- Retained logs are essential evidence for incident response, forensics, and SOC 2 / ISO 27001 audits

**Attack Prevented:** Undetected intrusion, repudiation, unauthorized configuration changes, audit-trail gaps

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Settings** → **Audit Log**
2. Review logged events
3. Configure retention

**Step 2: Monitor Events**
1. User authentication
2. Permission changes
3. DSN modifications
4. Data access events

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Sentry Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Team access | [2.1](#21-configure-team-access) |
| CC6.7 | DSN security | [3.2](#32-configure-dsn-security) |
| CC7.2 | Audit logs | [4.1](#41-configure-audit-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Sentry Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-6 | Team access | [2.1](#21-configure-team-access) |
| IA-5 | Auth token management | [2.4](#24-use-organization-auth-tokens-for-automation) |
| SI-12 | Data scrubbing | [3.1](#31-configure-data-scrubbing) |
| SC-7 | Relay egress control | [3.4](#34-deploy-relay-for-in-network-pii-scrubbing) |
| AU-2 | Audit logs | [4.1](#41-configure-audit-logs) |

---

## Appendix A: References

**Official Sentry Documentation:**
- [Sentry Documentation](https://docs.sentry.io/)
- [Single Sign-On](https://docs.sentry.io/organization/authentication/sso/)
- [Two-Factor Authentication](https://docs.sentry.io/organization/authentication/two-factor-authentication/)
- [Auth Tokens](https://docs.sentry.io/account/auth-tokens/)
- [Scrubbing Sensitive Data](https://docs.sentry.io/security-legal-pii/scrubbing/)
- [Advanced Data Scrubbing](https://docs.sentry.io/security-legal-pii/scrubbing/advanced-datascrubbing/)
- [Relay](https://docs.sentry.io/product/relay/)

*Two documentation paths this guide previously cited have been retired: `/product/accounts/sso/` is now `/organization/authentication/sso/`, and `/product/data-management-settings/scrubbing/` is now `/security-legal-pii/scrubbing/`.*

**API & Developer Resources:**
- [Sentry API Documentation](https://docs.sentry.io/api/)

**Compliance:**
- SOC 2 Type II, ISO 27001, HIPAA -- via [Sentry SOC2 & ISO 27001 Documentation](https://docs.sentry.io/security-legal-pii/security/soc2/)

**Security Incidents:**
- No major public security breaches of Sentry's platform infrastructure have been identified.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | ai-drafted | Added api Code Packs for §2.3 (member-role inventory, owner-ceiling check, and stale-invite audit via the org members endpoint) and §3.2 (client-key rate-limit audit, rate-limit enforcement, and compromised-key deactivation via the project keys endpoints), verified against docs.sentry.io API references; no pack for §4.1 because the current Sentry API docs expose no audit-log endpoint | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass: rewrote 1.2 as an either/or after confirming Require 2FA is unavailable with SSO, with the correct Organization Settings path, Owner requirement, and the member-removal blast radius; added 2.4 organization auth tokens and 3.4 Relay; added Advanced Data Scrubbing (methods, data types, source selectors, and its precedence over Safe Fields) plus attachment and Session Replay privacy pointers to 3.1; documented SAML2 provider list, Google/GitHub SSO on Trial/Team, and the member-on-all-teams and two-week-session defaults in 1.1; corrected two retired documentation paths and removed the Trust Center and security marketing links | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO, teams, and data scrubbing | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
