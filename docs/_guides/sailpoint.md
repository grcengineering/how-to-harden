---
layout: guide
title: "SailPoint Hardening Guide"
vendor: "SailPoint"
slug: "sailpoint"
tier: "3"
category: "Identity"
description: "Identity Security Cloud hardening for tenant access, API clients and PATs, sessions, network restrictions, and audit reporting"
version: "0.2.1"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

SailPoint is the **#1 IGA (Identity Governance and Administration) vendor** controlling provisioning/deprovisioning workflows across enterprises. SCIM connector tokens, governance APIs, and credential provider integrations (Vault, AWS Secrets Manager, CyberArk) create attack chains. Compromised access enables identity manipulation at scale including backdoor account creation.

**Product naming:** SailPoint's SaaS platform is **Identity Security Cloud** (formerly **IdentityNow**); SailPoint's current documentation index presents the SaaS portfolio under the **SailPoint Human Fabric** umbrella. Older console paths and third-party write-ups still say "IdentityNow" — this guide uses the current names and console paths (**Admin → Global → …**, **Admin → Identity Management → Identity Profiles**). **IdentityIQ** is the separate on-premises product; where a control or advisory applies only to IdentityIQ, this guide says so.

### Intended Audience
- Security engineers managing identity governance
- IT administrators configuring SailPoint
- GRC professionals assessing identity compliance
- Third-party risk managers evaluating IGA integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers SailPoint Identity Security Cloud security configurations including authentication, tenant and vendor access, session and network controls, API credential management, provisioning, and audit reporting.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Source Connector & API Credential Security](#2-source-connector--api-credential-security)
3. [Provisioning Security](#3-provisioning-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce MFA for Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require strong MFA for all SailPoint administrative access — enforced at the identity provider for federated users, and enforced natively in Identity Security Cloud for any elevated account that can sign in without the IdP.

#### Rationale
**Why This Matters:**
- SailPoint controls identity provisioning enterprise-wide
- Admin compromise enables mass identity manipulation
- Governance APIs provide identity lifecycle control
- IdP-only enforcement leaves a gap: any account that can authenticate directly against the tenant bypasses every conditional-access rule the IdP applies

**Attack Prevented:** Backdoor account creation via a stolen SCIM token or admin session; certification tampering; IdP-bypass sign-in by an elevated local account.

#### Prerequisites
- Administrator access to **Admin → Identity Management → Identity Profiles**
- A configured SAML/OIDC identity provider for federated sign-in

#### ClickOps Implementation

**Step 1: Configure SSO**
1. Navigate to: **Admin → Identity Management → Identity Profiles**
2. Select the identity profile, open its **Sign-in Method** (Sign-In and Security) settings
3. Configure SAML with your IdP and require MFA at the IdP level

**Step 2: Register Native Strong Authentication for IdP-Bypass Accounts**
1. In the identity profile's **Sign-in Method** settings, enable SailPoint's native strong authentication
2. SailPoint documents **TOTP (Authenticator App)** among the strong-authentication methods available on the identity profile
3. Have every break-glass and elevated account that can sign in without the IdP register a TOTP authenticator — otherwise those accounts are single-factor precisely where the IdP controls do not reach

**Step 3: Restrict Admin Access**
1. Navigate to: **Admin → Global → User Level Matrix** (or the admin user list) and review who holds elevated levels
2. Limit the number of accounts holding org-wide levels
3. Require additional verification for privileged actions

#### Validation & Testing
1. Attempt an admin sign-in that does not traverse the IdP and confirm the strong-authentication prompt appears
2. Confirm each elevated account has a registered strong-authentication method

**Gotcha:** SailPoint documents that a `#` character in a username can break strong-authentication registration and sign-in flows. Avoid `#` in usernames for accounts that will register native strong authentication.

---

### 1.2 Scope Administration With Documented User Levels

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Assign each administrator the narrowest documented Identity Security Cloud user level for their job, and prefer the governance-group-scoped **sub-admin** levels over org-wide levels wherever the work can be scoped.

#### Rationale
**Why This Matters:**
- `ORG_ADMIN` grants full control over identity provisioning and certifications across the tenant, so a single compromised account can manipulate access for everyone
- SailPoint documents distinct, purpose-built levels — assigning by job function rather than defaulting to org admin is the difference between a contained incident and a tenant-wide one
- The **sub-admin** levels (`ROLE_SUBADMIN`, `SOURCE_SUBADMIN`) are scoped by governance group membership, which is the platform's real least-privilege mechanism: the admin can only act on the roles or sources their governance group owns
- Fewer full-privilege accounts mean a smaller, more auditable attack surface and easier detection of anomalous admin behavior

**Attack Prevented:** Privilege escalation, lateral movement, insider abuse, blast-radius expansion from a compromised admin account

#### ClickOps Implementation

**Step 1: Review Documented User Levels**

SailPoint's user level matrix documents the levels below. Assign the narrowest one that covers the job:

| User Level | Scope |
|------------|-------|
| `ORG_ADMIN` | Org-wide administration — treat as the tenant's most privileged level |
| `CERT_ADMIN` | Certification campaign administration |
| `HELPDESK` | Help-desk support tasks |
| `REPORT_ADMIN` | Reporting |
| `ROLE_ADMIN` | Role administration across the tenant |
| `ROLE_SUBADMIN` | Role administration scoped to the admin's governance groups |
| `SOURCE_ADMIN` | Source administration across the tenant |
| `SOURCE_SUBADMIN` | Source administration scoped to the admin's governance groups |
| `SOURCE_CONFIG_ASSIGNEE` | Assigned source-configuration work only |
| `CLOUD_GOV_*` | Cloud governance levels (admin/user tiers) |
| `IDENTITY_GRAPH_*` | Identity graph levels (admin/user tiers) |

**Step 2: Prefer Scoped Sub-Admin Levels**
1. Create governance groups that reflect real ownership boundaries (which team owns which sources or roles)
2. Assign `ROLE_SUBADMIN` / `SOURCE_SUBADMIN` and add the admins to the owning governance group, instead of granting `ROLE_ADMIN` / `SOURCE_ADMIN`
3. Reserve `ORG_ADMIN` for a small, documented set of accounts

**Step 3: Review Regularly**
1. Re-review level assignments on a defined cadence and after every role change
2. Remove levels that are no longer justified

#### Validation & Testing
1. Sign in as a scoped sub-admin and confirm sources or roles outside the governance group are not visible or editable
2. Export the admin list and confirm the `ORG_ADMIN` count matches the documented set

---

### 1.3 Control Grant Tenant Access for SailPoint Support

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-2, AC-3, AU-2 |

#### Description
Review and bound **Grant Tenant Access** — the setting that lets SailPoint Support (and, separately, external tenants) sign in to your tenant — and treat it as a standing third-party identity in your most privileged system.

> **Changed default — check this first.** SailPoint documents that when an organization's tenant is created, **SailPoint Support is automatically granted tenant access for six months**. This is on by default and expires silently; most tenants never review it. It is a vendor identity inside the system that governs every other identity you own.

#### Rationale
**Why This Matters:**
- A standing support-access grant is an authenticated path into the IGA tenant that does not belong to any of your employees and is not covered by your IdP's conditional access
- The default six-month grant at tenant creation means the access exists before anyone has made a decision about it — the absence of a decision is not the absence of access
- **External Tenant Access** is a separate slider that permits access from other SailPoint tenants; it is its own trust relationship and needs its own justification
- Support sessions are attributable: SailPoint documents that support sign-ins appear in the tenant's default audit reports under the `slpt.support` and `slpt.services` domains — but only if someone is reading those reports

**Attack Prevented:** Unreviewed standing vendor access to the identity-governance control plane; unbounded third-party sessions; unnoticed external-tenant trust.

#### ClickOps Implementation

**Step 1: Review the Current Grant**
1. Navigate to: **Admin → Global → Grant Tenant Access**
2. Record whether SailPoint Support access is currently enabled and what its expiration date is
3. Review the **External Tenant Access** slider separately and disable it unless a documented cross-tenant use case exists

**Step 2: Bound the Expiration**
1. SailPoint requires the expiration to fall between **one week and one year** — set it to the shortest window that covers an open support case, not the maximum
2. Re-enable per case rather than leaving a standing grant, and diary the expiry

**Step 3: Understand the Blast Radius of Disabling It**
1. Disabling tenant access **immediately invalidates all personal access tokens owned by `slpt.services` accounts** — any SailPoint-managed integration or support tooling authenticating with those tokens stops working at once
2. Confirm with your SailPoint contact which, if any, active integrations depend on those tokens before disabling during an incident

#### Validation & Testing
1. Run the tenant's default audit reports and search for sign-ins from the `slpt.support` and `slpt.services` domains — confirm every session maps to a support case you opened
2. Re-check **Admin → Global → Grant Tenant Access** on a recurring schedule and confirm the expiration is still the intended one

---

### 1.4 Configure Session Lengths

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-11, AC-12 |

#### Description
Set maximum and idle session lengths for Identity Security Cloud so an unattended or hijacked browser session cannot hold governance privileges indefinitely.

#### Rationale
**Why This Matters:**
- SailPoint's documented default maximum session length is **12 hours**, with a configurable ceiling of **7 days** — a session that outlives the workday is a session available to whoever reaches the device next
- The documented default idle timeout is **15 minutes**, configurable up to **24 hours**; raising it for convenience directly extends the window for session theft
- The **end session when browser closes** checkbox matters: SailPoint documents that when it is deselected, closing the browser does **not** end the session — the session persists until it hits the max or idle limit
- Sessions are where governance privilege actually lives; token-level controls do nothing for an already-authenticated browser

**Attack Prevented:** Session hijacking, unattended-device access, token replay against a long-lived governance session

#### ClickOps Implementation

**Step 1: Set Session Lengths**
1. Navigate to: **Admin → Global → Security Settings → Session Lengths**
2. Set **maximum session length** below the 12-hour default — a value within the working day is the goal, not the 7-day ceiling
3. Set **idle session length** at or below the 15-minute default (L2/L3: shorter)

**Step 2: End Sessions on Browser Close**
1. Select the option to end the session when the browser closes
2. If it is deselected, document why — the consequence is that browser closure leaves the session live

#### Validation & Testing
1. Sign in, close the browser, reopen and navigate to the tenant — confirm re-authentication is required
2. Leave a session idle past the configured idle limit and confirm it terminates

**Gotcha:** SailPoint documents that session-length changes do **not** apply to sessions that are already active. Existing sessions run out under the old settings — plan a cutover or terminate active sessions if the change is a response to an incident.

---

### 1.5 Restrict Tenant Access by Network and Geography

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Use network settings to block sign-in to the tenant from outside defined corporate networks or from untrusted geographies, applied per identity profile.

#### Rationale
**Why This Matters:**
- Network restrictions deny a valid stolen credential when it is presented from attacker infrastructure, which no amount of password policy achieves
- Applying restrictions per identity profile lets you hold contractors or high-privilege populations to a tighter network boundary than the general workforce
- Geographic blocking removes a large volume of automated credential-stuffing traffic from regions where you have no users

**Attack Prevented:** Credential-theft exploitation from attacker infrastructure, sign-in from untrusted regions, remote access with stolen credentials

#### ClickOps Implementation

**Step 1: Define Networks**
1. Navigate to: **Admin → Global → System Settings → Network Settings**
2. Define the corporate network ranges your users actually sign in from

**Step 2: Apply Restrictions Per Identity Profile**
1. Enable **Block Access From Off Network** and/or **Block Access From Untrusted Geographies** for the relevant identity profiles
2. Roll out to a pilot identity profile before applying broadly

#### Validation & Testing
1. Attempt a sign-in from outside the defined network for a restricted identity profile and confirm it is blocked
2. Confirm unrestricted profiles are unaffected

> **Two caveats SailPoint documents explicitly — both are lockout or false-assurance risks:**
>
> - **If no network is defined, enabling "Block Access From Off Network" blocks everyone.** Define the network ranges before turning the restriction on.
> - **These restrictions do not apply when users sign in through SSO.** Federated sign-in bypasses them. If your users authenticate via an IdP — which is the recommended configuration — network and geographic enforcement must be implemented at the IdP, and this control alone will not deliver it.

---

### 1.6 Configure Lockout Management

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | AC-7 |

#### Description
Configure lockout thresholds so repeated failed authentication attempts against the tenant lock the account rather than allowing unlimited guessing.

#### Rationale
**Why This Matters:**
- Without a lockout threshold, an attacker can run automated password and one-time-code guessing against tenant accounts indefinitely
- SailPoint documents that lockout applies to **password attempts, MFA/strong-authentication attempts, and password-reset attempts** — so the threshold also blunts one-time-code brute forcing, not just password guessing
- A documented working configuration is **5 failed attempts within 5 minutes producing a 15-minute lockout**, which stops automated tooling while keeping the help-desk burden manageable

**Attack Prevented:** Brute-force password guessing, password spraying, one-time-code brute forcing, reset-flow abuse

#### ClickOps Implementation

**Step 1: Configure Lockout**
1. Navigate to: **Admin → Global → Security Settings → Lockout Management**
2. Configure:
   - **Maximum failed attempts** before lockout (e.g. 5)
   - **Reset window** over which failed attempts are counted (e.g. 5 minutes)
   - **Lockout duration** in minutes (e.g. 15)

**Step 2: Pair With Detection**
1. Ensure lockout events are visible in the tenant's audit reporting (see [4.1](#41-audit-logging-and-reporting))
2. Treat a spike in lockouts as a spray indicator, not a help-desk metric

#### Validation & Testing
1. Deliberately exceed the threshold with a test account and confirm the lockout engages for the configured duration
2. Confirm the lockout events appear in audit reporting

---

## 2. Source Connector & API Credential Security

### 2.1 Secure SCIM Connectors

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2 |
| NIST 800-53 | IA-5 |

#### Description
Harden SCIM connector configurations.

#### Rationale
**Why This Matters:**
- SCIM connector tokens grant SailPoint the standing ability to create, modify, and delete accounts in connected HR, cloud, and directory systems
- A stolen or long-lived connector credential lets an attacker provision backdoor accounts or alter entitlements directly in downstream targets
- Regular token rotation and least-privilege service accounts shrink the window an exposed credential remains useful

**Attack Prevented:** Credential theft, backdoor account creation, unauthorized provisioning, supply-chain pivot into connected systems

#### Implementation

**Step 1: Audit Source Connections**
1. Navigate to: **Admin → Connections → Sources**
2. Review all active sources
3. Document credentials and permissions

**Step 2: Rotate SCIM Tokens**

| Source Type | Rotation Frequency |
|-------------|-------------------|
| HR Systems | Quarterly |
| Cloud Applications | Quarterly |
| Active Directory | Semi-annually |

---

### 2.2 Govern API Clients and Personal Access Tokens

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2, 6.8 |
| NIST 800-53 | IA-5, AC-6, AU-2 |

#### Description
Manage the tenant's API clients and personal access tokens (PATs) centrally — bound expiration, least-privilege scopes, and an owner for every non-managed token.

#### Rationale
**Why This Matters:**
- PATs authenticate to the same governance APIs an administrator uses; a leaked token is admin-equivalent within its scopes and carries no MFA prompt
- SailPoint documents that a PAT's expiration defaults to **6 months**, and that **leaving the expiration field blank creates a token that never expires** — the most dangerous configuration in the product is one keystroke away from the default
- SailPoint documents a limit of **10 PATs per user**, and that expired tokens remain **restorable for 3 months** — an expired token is not yet a revoked token
- The token secret is **displayed only once at creation**; a token that is not recorded and inventoried at creation time is a credential nobody owns
- SailPoint's own guidance is to **select only the scopes the integration requires** — broad scopes on a long-lived token is the worst combination available

**Attack Prevented:** Standing admin-equivalent API access via leaked or forgotten tokens, over-scoped integrations, orphaned credentials outliving their owners

#### Prerequisites
- `ORG_ADMIN` (or equivalent) access to **Admin → Global → Security Settings**

#### ClickOps Implementation

**Step 1: Inventory Tokens Org-Wide**
1. Navigate to: **Admin → Global → Security Settings → API Management** (personal access tokens)
2. SailPoint documents that administrators can view **all non-managed tokens across the organization**, including owner and last-used information — use this as the inventory, not a spreadsheet
3. Identify tokens with no expiration and tokens whose owner has left

**Step 2: Bound Expiration**
1. Never leave the expiration field blank — blank means the token never expires
2. Set expirations to the shortest window the integration tolerates; the 6-month default is a ceiling, not a target
3. SailPoint documents bulk expiration updates for non-managed tokens **25 at a time** — use this to bring an inherited estate back under policy

**Step 3: Scope Least Privilege**
1. Grant only the scopes the integration actually calls
2. SailPoint documents that scope changes can take **up to 30 minutes** to take effect — do not treat a scope reduction as an instant containment action
3. Note the refresh-token default lifetime of **1 month** when designing integration re-authentication

**Step 4: Handle the Secret Correctly**
1. The client secret / token value is shown **once** — capture it directly into your secrets manager at creation
2. If it is lost, rotate rather than working around it

#### Code Implementation

{% include pack-code.html vendor="sailpoint" section="2.2" %}

#### Validation & Testing
1. Review the org-wide token list and confirm every token has an expiration, a named owner, and a documented purpose
2. Confirm recent `last used` values — tokens with no recent use are rotation or revocation candidates

**Honest limitation:** SailPoint's API key documentation describes per-token and bulk (25-at-a-time) expiration updates for non-managed tokens. **No org-wide "revoke all tokens" kill-switch is documented on that page.** Plan incident response accordingly: bulk expiration in batches is the documented mechanism, and disabling **Grant Tenant Access** (see [1.3](#13-control-grant-tenant-access-for-sailpoint-support)) invalidates only `slpt.services`-owned tokens, not your own.

---

## 3. Provisioning Security

### 3.1 Implement Provisioning Controls

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.1 |
| NIST 800-53 | AC-2 |

#### Description
Configure provisioning policies that require approval for privileged access, grant time-limited access, automatically deprovision departed or role-changed users, and alert on anomalous provisioning events.

#### Rationale
**Why This Matters:**
- Provisioning is where access is actually granted, so uncontrolled provisioning lets privileged entitlements be assigned with no oversight
- Approval gates and time-limited access prevent standing privilege accumulation and enforce just-in-time access
- Automatic deprovisioning closes the orphaned-account gap when users leave or change roles, removing a common attacker foothold
- Alerting on out-of-band or privileged provisioning surfaces backdoor account creation before it can be abused

**Attack Prevented:** Orphaned-account access, privilege creep, out-of-band backdoor provisioning, unauthorized entitlement grants

#### ClickOps Implementation

**Step 1: Configure Provisioning Policies**
1. Require approval for privileged access
2. Implement time-limited access
3. Enable automatic deprovisioning

**Step 2: Monitor Provisioning Events**
1. Alert on privileged account creation
2. Alert on out-of-band provisioning
3. Alert on failed deprovisioning

---

## 4. Monitoring & Detection

### 4.1 Audit Logging and Reporting

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-11 |

#### Description
Run and review Identity Security Cloud's built-in audit reports, and understand the platform's documented audit retention window before relying on it for investigation or evidence.

#### Rationale
**Why This Matters:**
- Identity governance actions such as provisioning, certification decisions, and source changes are high-value targets, and without reviewing the audit surface their abuse is invisible
- SailPoint's default audit reports are the documented place where third-party sign-ins appear — including SailPoint Support sessions from the `slpt.support` and `slpt.services` domains (see [1.3](#13-control-grant-tenant-access-for-sailpoint-support))
- Retention is bounded: SailPoint documents audit data availability of **the current month plus one year**, with older data obtainable **up to five years** through an Audit History Request — an investigation that starts late may need a request, not a report
- Retained audit trails are required for forensic investigation and to satisfy SOC 2, ISO 27001, and FedRAMP evidence requirements

**Attack Prevented:** Undetected privilege abuse, backdoor account creation, certification tampering, unnoticed vendor sign-ins, log gaps that defeat forensics

#### ClickOps Implementation

**Step 1: Run the Default Audit Reports**
1. Navigate to: **Admin → Global → Reports**
2. SailPoint documents six default audit reports covering the tenant's activity surfaces:
   - **User Login Report**
   - **Password Change Report**
   - **Source Account Report**
   - **User Registration Report**
   - **Provisioning Activity Report**
   - **Access Request Report**
3. Establish a review cadence per report, and assign an owner

**Step 2: Search the Audit Data**
1. Use the audit search to filter by action, actor, and date range — for example, filtering the login report by the `slpt.support` or `slpt.services` domains surfaces SailPoint Support sign-ins, and filtering by `type` narrows to a specific event class
2. Save the searches your responders will need under pressure rather than composing them during an incident

**Step 3: Plan for Retention Limits**
1. Treat **current month + 1 year** as the self-service window
2. For anything older, raise an **Audit History Request** with SailPoint — documented as reaching back up to **five years**
3. If your retention obligation exceeds the self-service window, export on a schedule rather than discovering the limit during an investigation

#### Code Implementation

{% include pack-code.html vendor="sailpoint" section="4.1" %}

#### Validation & Testing
1. Run each default report and confirm it returns data for the expected period
2. Perform a known admin action and confirm it appears in the corresponding report

**Honest limitation:** SailPoint's audit reports documentation describes in-console reports, search, and the Audit History Request process. **It does not document an API or native SIEM-export mechanism for these reports.** Do not assume streaming export exists on the basis of this control — verify the current integration options with SailPoint before designing a SIEM pipeline around them.

---

## Appendix B: References

**Official SailPoint Documentation:**
- [SailPoint Documentation](https://documentation.sailpoint.com/)
- [Grant Tenant Access](https://documentation.sailpoint.com/saas/help/common/grant-tenant-access.html)
- [Manage API Keys and Personal Access Tokens](https://documentation.sailpoint.com/saas/help/common/api_keys.html)
- [Session Lengths](https://documentation.sailpoint.com/saas/help/common/session_lengths.html)
- [Restrict Tenant Access](https://documentation.sailpoint.com/saas/help/access/restrict_access.html)
- [Lockout Management](https://documentation.sailpoint.com/saas/help/setup/lockout.html)
- [Strong Authentication](https://documentation.sailpoint.com/saas/help/common/strong_auth.html)
- [User Level Matrix](https://documentation.sailpoint.com/saas/help/common/users/user_level_matrix.html)
- [Audit Reports](https://documentation.sailpoint.com/saas/help/common/audit-reports.html)
- [Security Advisories](https://www.sailpoint.com/security-advisories)

**API & Developer Resources:**
- [SailPoint Developer Portal](https://developer.sailpoint.com/docs/api/v3/)

**Compliance & Certifications:**
- SOC 1 Type II, SOC 2 Type II, SOC 3, ISO 27001, ISO 15408, FedRAMP

**Security Incidents:**

| CVE | Product | Disclosed | CVSS | Summary |
|-----|---------|-----------|------|---------|
| CVE-2026-12341 | IdentityIQ | 2026-07-20 | 8.8 | Improper OAuth bearer-token validation permitting unauthenticated access to API endpoints. Addressed by SailPoint fix **IIQSR-982**. |
| CVE-2026-5712 | SailPoint | 2026 | — | Listed in SailPoint's security advisories index; consult the advisory for affected versions and remediation. |
| CVE-2026-4857 | SailPoint | 2026 | — | Listed in SailPoint's security advisories index; consult the advisory for affected versions and remediation. |
| CVE-2024-10905 | IdentityIQ | 2024-12 | 10.0 | Directory traversal allowing unauthorized access to content stored within the application directory. Affected versions up to patch levels 8.4p2, 8.3p5, and 8.2p8; e-fixes released for all impacted versions. No reports of exploitation in the wild at time of disclosure. |

Consult [SailPoint Security Advisories](https://www.sailpoint.com/security-advisories) for the authoritative, current list and per-advisory remediation detail.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Add Code Packs: 2.2 (v3 Personal Access Tokens API — inventory, never-expiring/stale-token detection via documented lastUsed filters, revocation) and 4.1 (SailPoint CLI `sail search` against the events index — provisioning events, slpt support sign-ins, 90-day provisioning template) — verified against the SailPoint CLI docs and the official v3 OpenAPI specification | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | draft | Add Grant Tenant Access control (SailPoint Support auto-granted 6 months at tenant creation — changed default); expand thin guide with API client/PAT governance, session lengths, network and geographic restrictions, and lockout management; correct 1.2 to documented user levels and sub-admin scoping; rebuild 4.1 on the six documented audit reports and retention limits; sharpen 1.1 with native TOTP strong authentication; rename to Identity Security Cloud (formerly IdentityNow) with current console paths; add 2026 CVEs; drop Trust Center links | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial SailPoint hardening guide | Claude Code (Opus 4.5) |

**Source coverage note:** This revision is built on SailPoint's Tier 1 Identity Security Cloud documentation and SailPoint's own security advisories. **No Tier 2 benchmark coverage was confirmed** for SailPoint (no CIS Benchmark, DISA STIG, or CISA SCuBA baseline located for this product). Tier 3/4 independent research was **not surveyed** for this revision.

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
