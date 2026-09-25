---
layout: guide
title: "Snyk Hardening Guide"
vendor: "Snyk"
slug: "snyk"
tier: "5"
category: "Security"
description: "AppSec platform security for service accounts, SCM integrations, and Broker configs"
version: "0.3.0"
maturity: ["ai-drafted"]
last_updated: "2026-09-25"
---


## Overview

Snyk provides developer security for vulnerability scanning across code, dependencies, containers, and IaC. REST API, CLI tokens, and SCM integrations access source code repositories and vulnerability data. Compromised access exposes vulnerability findings and potentially enables code access through integrations.

### Intended Audience
- Security engineers managing AppSec tools
- DevSecOps administrators
- GRC professionals assessing development security
- Third-party risk managers evaluating security scanning tools


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Snyk security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Integration Security](#2-integration-security)
3. [Data Security](#3-data-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO through your corporate identity provider and enforce multi-factor authentication for every user who accesses the Snyk platform.

#### Rationale
**Why This Matters:**
- Centralizes Snyk authentication in your IdP so MFA, conditional access, and session policies apply to every login
- Snyk has no native password: users sign in with a GitHub, Google, Bitbucket, Entra ID, or Docker ID account or with company SSO, and accounts that bypass company SSO sit outside your IdP's MFA, conditional-access, and deprovisioning controls
- SSO with automated deprovisioning removes departed users' access immediately, preventing orphaned accounts from reaching vulnerability data
- Snyk holds your organization's known-vulnerability inventory and SCM connections, so a single compromised login can reveal exactly where you are exploitable

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Enterprise)**
1. Navigate to: **Group → Settings → SSO** (classic navigation) · **Settings → Security and access → SSO** at Group scope (new navigation)
2. Copy the **Entity ID**, **ACS URL**, and Snyk **signing certificate URL** into your IdP's SAML application; then enter the IdP sign-in URL, the IdP signing certificate, and your email domains in Snyk and select **Create Connection**
3. Choose how new users join: **Require an invite** rather than **Open to all**
4. Verify the connection with the direct login URL shown at the top of **Step 3** before rolling it out

**Step 2: Remove Non-SSO Access and Enforce MFA at the Identity Provider**
1. In **Group → Members**, remove users who previously signed in with a social login and any personal accounts used during a pilot, so every remaining account is governed by your IdP
2. Enforce MFA in your IdP for the Snyk application. Snyk has no Snyk-side MFA setting; on Free and Team plans (no SSO), MFA can only be enforced on the GitHub, Google, Bitbucket, Entra ID, or Docker ID account used to sign in

#### Code Implementation

{% include pack-code.html vendor="snyk" section="1.1" %}

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Assign Snyk group and organization members the least-privileged role required for their function instead of granting broad administrative access by default.

#### Rationale
**Why This Matters:**
- Least-privilege roles limit how much a single compromised or insider account can change, export, or expose
- Group Admin and Org Admin can alter integrations, ignore policies, and member access, so these rights should be tightly held
- The pre-defined Org Collaborator role can add and remove Projects and create, edit, and remove ignores, so developers who only need to view and test belong in a narrower custom role
- Clear role separation makes access reviews and audit attribution far easier across many organizations

**Attack Prevented:** Privilege escalation, insider misuse, unauthorized configuration changes, lateral movement

#### ClickOps Implementation

**Step 1: Know the Roles**

| Role | Scope | Key permissions |
|------|-------|-----------------|
| Group Admin | Group | Every permission in every Organization of the Group, including SSO, service accounts, and Group audit logs |
| Group Viewer | Group | Read-only access to the Group and to every Organization in it |
| Group Member | Group | Sees the Group's list of Organizations only, until an Organization role is granted |
| Org Admin | Organization | Manage members, integrations, and service accounts; approve ignores |
| Org Collaborator | Organization | Add, test, and remove Projects; **create, edit, and remove ignores**; view Organization audit logs |
| Custom role (Enterprise) | Tenant, Group, or Organization | Built under **Group → Settings → Member roles** |

Tenant-level roles (Tenant Admin, Tenant Viewer, Tenant Member) do not grant Group or Organization access. Pre-defined role permissions cannot be edited; use a custom role to narrow them. See [Pre-defined roles](https://docs.snyk.io/platform-administration/user-management/pre-defined-roles).

**Step 2: Configure Organization Access**
1. Navigate to: **Organization → Members** (classic navigation) · **Settings → Security and access → Members** (new navigation)
2. Click a member's **Role** entry and select the least-privileged role the person needs
3. Keep Group Admin and Org Admin to named owners, and review the member list on a fixed cadence
4. Org Collaborator can ignore issues by default — restrict ignores to admins with control 3.2

#### Code Implementation

{% include pack-code.html vendor="snyk" section="1.2" %}

---

## 2. Integration Security

### 2.1 Secure Service Account Tokens

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Choose the right service-account credential type for every non-interactive Snyk integration, and manage those credentials on a defined lifecycle. Snyk offers three service-account authentication types with materially different security properties — API key, access token, and OAuth 2.0 — and the choice determines whether the credential ever expires.

#### Rationale
**Why This Matters:**
- Service account credentials are non-interactive and bypass MFA, so a leaked credential grants direct API access with the service account's full role
- **API keys never expire.** Snyk documents the API key service account as a legacy type and explicitly states it is *not recommended* — an API key leaked into a CI log or repository is a permanent credential until someone notices and deletes the account
- Access tokens cap out at a **one-year maximum expiry**, and Snyk documents no in-place rotation: when an access token expires you must create a **new service account** and re-plumb every consumer, so the rotation has to be planned rather than discovered at expiry
- OAuth 2.0 service accounts issue short-lived tokens with automated refresh, which is why they are the recommended type for CI/CD and any long-running integration
- Snyk credentials can read vulnerability findings and drive SCM operations, so exposure reveals exploitable weaknesses and integration reach

**Attack Prevented:** Token theft, credential leakage in CI/CD, standing-credential abuse, unauthorized data export

**Attack Scenario:** Exposed API token enables vulnerability data export; attackers gain insight into exploitable vulnerabilities before patches.

#### Prerequisites
- **Enterprise plan** — Snyk documents service accounts as available only on Enterprise plans; Free and Team organizations have personal user tokens only

#### ClickOps Implementation

**Step 1: Choose the Credential Type**

| Type | Expiry | Rotation | Snyk guidance |
|------|--------|----------|---------------|
| API key | Never expires | Manual only (delete + recreate) | Legacy — explicitly **not recommended** |
| Access token | Configurable, **1 year maximum** | No in-place rotation — requires a **new service account** | Acceptable where OAuth is not supported; plan around the 1-year ceiling |
| OAuth 2.0 | Short-lived access token | Automated refresh | **Recommended** — use for CI/CD and all new integrations |

Default to OAuth 2.0. Never create API-key service accounts for new integrations, and treat any existing API-key service account as a standing credential to be migrated. See [Choose a service account type](https://docs.snyk.io/platform-administration/service-accounts/choose-a-service-account-type-to-use-with-snyk-apis).

**Step 2: Audit Service Accounts**
1. Navigate to: **Settings → Service accounts** at Group or Organization level (classic navigation) · Group scope **Settings → Security and access → Service accounts**, Organization scope **Settings → Organization settings → Service accounts** (new navigation)
2. Review all service accounts and record the credential type of each
3. Remove unused accounts
4. Flag every API-key service account for migration to OAuth 2.0

**Step 3: Credential Lifecycle**
1. Create one service account per CI/CD pipeline or integration — never share credentials across consumers
2. Assign the least-privileged role the integration needs
3. For access tokens, diary the expiry date and schedule the replacement service account **before** it lapses (there is no in-place renewal)
4. Store credentials in a secrets manager; never commit them or echo them in pipeline logs

#### Code Implementation

{% include pack-code.html vendor="snyk" section="2.1" %}

---

### 2.2 SCM Integration Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Review and restrict Snyk's source-code-management integrations so each connection has only the repository access it needs, and route private-repo access through the Snyk Broker. Snyk ships the Broker in two deployment models — **Universal Broker** and **Classic Broker** — and new deployments should target Universal Broker.

#### Rationale
**Why This Matters:**
- SCM integrations grant Snyk read access to source repositories, so an over-scoped or stale connection widens what a platform compromise can reach
- The Snyk Broker keeps private repositories behind your perimeter and brokers only approved requests instead of exposing direct SCM credentials — Snyk documents that with Broker, "credentials remain within your network and are never stored by or transmitted to Snyk"
- Universal Broker consolidates many connection types (GitHub, GitLab, Artifactory, Jira, container registry) behind a single client or set of replicas, so there is one hardened egress path to govern instead of one Broker deployment per integration
- Classic Broker uses per-integration deployments that pass only requests on a default approved-data list (tuned with ACCEPT rule flags); a custom `accept.json` replaces that list and disables the ACCEPT flags, so keeping it minimal becomes your job
- Limiting repository scope contains the impact if a token or integration is abused, preventing access to unrelated codebases

**Attack Prevented:** Source code exposure, over-scoped integration abuse, supply chain reconnaissance, credential leakage

> **Changed default (April 2026):** Snyk Broker now runs in **high-availability mode by default**. Deployments provisioned before this change may still be running single-instance; confirm your replica configuration rather than assuming the old default. Source: [Snyk What's New](https://docs.snyk.io/whats-new).

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Settings → Integrations** (classic and new navigation; Broker connections are under **Settings → Integrations → Snyk Broker** in the new navigation)
2. Review SCM connections
3. Limit repository access

**Step 2: Choose a Broker Deployment Model (Enterprise)**

| Model | Shape | Use it for |
|-------|-------|------------|
| [Universal Broker](https://docs.snyk.io/platform-administration/snyk-broker/universal-broker) | One Broker client (or replica set) serving many connection types — GitHub, GitLab, Artifactory, Jira, container registry | **New deployments.** Fewer moving parts, one egress path, centrally managed connections |
| [Classic Broker](https://docs.snyk.io/platform-administration/snyk-broker/classic-broker) | One Broker deployment per integration type, each with its own approved-data list | Existing estates already running per-integration Brokers |

**Step 3: Harden the Broker Deployment**
1. Deploy the Broker inside your network so SCM credentials never leave your perimeter
2. Restrict the permitted request set — in Classic Broker, the default approved-data list tuned with ACCEPT rule flags, or a custom `accept.json` that replaces it (and disables those flags); in Universal Broker, per-connection configuration
3. Limit exposed endpoints to the minimum the Snyk integration requires
4. Verify high-availability replica count matches your availability requirement

#### Code Implementation

{% include pack-code.html vendor="snyk" section="2.2" %}

---

## 3. Data Security

### 3.1 Project Visibility

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Limit who can see vulnerability findings, Project history, and reports by controlling Organization membership and, on Enterprise plans, the view permissions in custom roles. Snyk documents no per-Project visibility setting, so the Organization is the visibility boundary.

#### Rationale
**Why This Matters:**
- Vulnerability findings describe exactly where your software is exploitable, so over-broad visibility hands attackers a roadmap
- Limiting who can view issue details and share findings keeps sensitive security data on a need-to-know basis
- Controlling report generation and export prevents bulk exfiltration of findings outside monitored channels
- Auditing report access lets you detect unusual harvesting of vulnerability data before it is misused

**Attack Prevented:** Information disclosure, vulnerability reconnaissance, data exfiltration, insider leakage

#### ClickOps Implementation

**Step 1: Scope Visibility with Organizations**
1. Every pre-defined Organization role can view the Organization's Projects, ignores, and reports. Put sensitive repositories in a dedicated Organization and invite only the people who need them
2. Navigate to: **Organization → Members** (classic navigation) · **Settings → Security and access → Members** (new navigation), and remove anyone who no longer needs access

**Step 2: Narrow Read Rights with Custom Roles (Enterprise)**
1. Navigate to: **Group → Settings → Member roles** (classic navigation) · **Settings → Security and access → Member roles** at Group scope (new navigation)
2. Create a role without **View Organization reports** and **View Project History** for members who only need to run tests, and assign it in place of Org Collaborator

**Step 3: Report Access**
1. Keep **Edit Organization reports** with Org Admins (Org Collaborators cannot edit reports by default), and add report permissions to custom roles only where a person needs them
2. Review who holds report permissions in every access review (control 1.2)

#### Code Implementation

{% include pack-code.html vendor="snyk" section="3.1" %}

---

### 3.2 Ignore Policy

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Govern how vulnerabilities are ignored by requiring a documented reason, an expiration date, and periodic review of all suppressed findings.

#### Rationale
**Why This Matters:**
- Unbounded ignores silently suppress real vulnerabilities, letting exploitable issues ship while dashboards appear clean
- Requiring a reason and approver creates accountability and an audit trail for every accepted risk
- Expiration forces re-evaluation so a temporary exception does not quietly become permanent blindness
- Auditing ignored issues catches abuse where suppression is used to bypass security gates rather than manage genuine false positives

**Attack Prevented:** Risk-acceptance abuse, suppressed-vulnerability exploitation, security-gate bypass, audit evasion

#### ClickOps Implementation

**Step 1: Restrict Who Can Ignore and Require a Reason**
1. Navigate to: **Organization → Settings → General → Ignores** (classic navigation) · Organization scope **Settings → Organization settings → General → Ignores** (new navigation)
2. Under **Ignore an issue or edit ignore settings using Snyk Web UI or Snyk API**, select **Group and Org Admin users (Default user roles only)** — by default Org Collaborators can create, edit, and remove ignores. This also prevents ignores being added through the CLI
3. Under **Require reason for each ignore**, select **Required**

**Step 2: Approval Workflow for Snyk Code (Optional)**
1. Enable Snyk Code Consistent Ignores, then in **Organization → Settings** (classic navigation) · **Settings** at Organization scope (new navigation) enable **Ignore Approval Workflow for Snyk Code** (Organization level only)
2. When Consistent Ignores is enabled, the admin-only setting from Step 1 is disregarded — rely on the approval workflow instead

**Step 3: Bound and Audit Every Ignore**
1. Always set an expiry. CLI ignores default to 30 days, and a `.snyk` `expires:` value that is not in `YYYY-MM-DDThh:mm:ss.fffZ` form makes the ignore persist indefinitely
2. Review ignored issues on a fixed cadence

#### Code Implementation

{% include pack-code.html vendor="snyk" section="3.2" %}

---

## 4. Monitoring & Detection

### 4.1 Audit Logs (Enterprise)

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Review Snyk audit logs and forward them to your SIEM to retain a record of user and administrative activity across the platform. Snyk's audit logs are an **Enterprise-plan** capability with a **90-day rolling retention** window, and they **exclude login and logout events** — both facts drive how the control must be implemented.

#### Rationale
**Why This Matters:**
- Audit logs provide the authoritative record of who changed integrations, roles, ignore policies, and tokens
- **Retention is a rolling 90 days.** Any investigation, compliance evidence, or retrospective beyond that window is impossible from Snyk alone, which makes SIEM forwarding mandatory rather than optional
- **Login and logout events are excluded from the audit-log endpoints.** Authentication activity must be reconstructed from your identity provider's logs — treat the IdP as the system of record for Snyk sign-in, and correlate it with Snyk audit events in the SIEM
- Without centralized logging, account compromise and configuration tampering can go undetected until damage is done
- Reviewing activity supports incident response, forensics, and compliance evidence for access and change controls

**Attack Prevented:** Undetected account compromise, configuration tampering, audit gaps, delayed incident response

#### Prerequisites
- **Enterprise plan** — audit logs are not available on Free or Team

#### ClickOps Implementation

> **Console location unconfirmed:** Snyk documents audit-log retrieval for the Snyk platform through the API only. Its [audit-log how-to](https://docs.snyk.io/platform-administration/user-management/user-management-with-the-api/retrieve-audit-logs-of-user-initiated-activity-by-api-for-an-org-or-group) covers the Group and Organization search endpoints, and its [navigation map](https://docs.snyk.io/navigate-the-snyk-web-ui) lists no Audit logs page at Tenant, Group, or Organization scope. The Web UI audit-log reports Snyk also documents belong to Snyk API & Web, a separate product. Plan on the API until your Enterprise console shows a page.

**Step 1: Retrieve and Review Audit Logs**
1. Search the Group's and each Organization's audit logs through the API — Step 2 schedules this, and the read-only export under Code Implementation below runs it
2. Review user activities against the Detection Focus list below

**Step 2: Forward to SIEM Before the 90-Day Window Closes**
1. Pull group- and org-level audit events via the [audit logs API](https://docs.snyk.io/platform-administration/user-management/user-management-with-the-api/retrieve-audit-logs-of-user-initiated-activity-by-api-for-an-org-or-group)
2. Schedule collection at an interval well inside the 90-day retention window so no events age out uncollected
3. Retain forwarded events in the SIEM per your own retention policy — Snyk will not hold them

**Step 3: Fill the Authentication Gap from the IdP**
1. Forward Snyk SSO sign-in and sign-out events from your identity provider (the Snyk audit endpoints do not carry them)
2. Correlate IdP authentication events with Snyk audit events to reconstruct a complete session-to-action trail

#### Code Implementation

{% include pack-code.html vendor="snyk" section="4.1" %}

#### Detection Focus

Snyk documents these event classes in its audit logs; alert on them in the SIEM:

- Users invited, added, or removed, or a user's role changed
- A service account created, modified, or deleted
- A license rule or policy modified
- A Group or Organization added or removed, or a setting changed
- Sign-in is not in these logs — alert on Snyk SSO events in the IdP instead

---

## Appendix A: Edition Compatibility

Snyk's plans page lists Free, Team, and Enterprise.

| Control | Free | Team | Enterprise |
|---------|------|------|------------|
| SAML SSO (1.1) | ❌ | ❌ | ✅ |
| Custom member roles (1.2, 3.1) | ❌ | ❌ | ✅ |
| Service Accounts (2.1) | ❌ | ❌ | ✅ |
| Snyk Broker (2.2) | ❌ | ❌ | ✅ |
| Audit Logs (4.1) | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Snyk Documentation:**
- [User Docs](https://docs.snyk.io)
- [What's New (release notes)](https://docs.snyk.io/whats-new)
- [SSO Setup Guide](https://docs.snyk.io/platform-administration/user-management/single-sign-on-sso-for-authentication-to-snyk/set-up-snyk-single-sign-on-sso)
- [Service Accounts](https://docs.snyk.io/platform-administration/service-accounts/service-accounts)
- [Choose a Service Account Type](https://docs.snyk.io/platform-administration/service-accounts/choose-a-service-account-type-to-use-with-snyk-apis)
- [Snyk Broker](https://docs.snyk.io/platform-administration/snyk-broker/snyk-broker)
- [Universal Broker](https://docs.snyk.io/platform-administration/snyk-broker/universal-broker)
- [Classic Broker](https://docs.snyk.io/platform-administration/snyk-broker/classic-broker)
- [Vulnerability Disclosure Program](https://snyk.io/report-a-vulnerability/)

**API Documentation:**
- [API Overview](https://docs.snyk.io/developer-tools/snyk-api/snyk-api)
- [Interactive REST API Docs](https://apidocs.snyk.io/)
- [Retrieve Audit Logs by API](https://docs.snyk.io/platform-administration/user-management/user-management-with-the-api/retrieve-audit-logs-of-user-initiated-activity-by-api-for-an-org-or-group)
- [Authentication for API](https://docs.snyk.io/developer-tools/snyk-api/authentication-for-api)

**Compliance Frameworks:**
- ISO 27001, ISO 27017, SOC 2 Type II — via [Trust Center](https://trust.snyk.io/)
- [Platform Compliance](https://snyk.io/platform/compliance/)

**Security Incidents:**
- No major public incidents involving Snyk identified

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-09-25 | 0.3.0 | ai-drafted | validate-hth-guide fix loop, run offline against Snyk's docs and REST spec (the console was signed out, so 0 surfaces were exercised live and the guide is not ai-validated): corrected SSO to Enterprise-only at Group scope with IdP-side MFA (1.1); replaced the role table and member paths (1.2); added the Enterprise gate and new-navigation paths to service accounts (2.1); rewrote Project Visibility around Organization membership and custom roles (3.1) and Ignore Policy around Organization Settings → General → Ignores, with classic and new navigation paths (3.2); refreshed Classic Broker approved-data wording (2.2); replaced 4.1's unconfirmed Settings → Audit logs console path with API retrieval, the only route Snyk documents, and filled its Detection Focus; corrected Appendix A to Free/Team/Enterprise and removed the SCIM row (no SCIM control in this guide); repaired three redirecting Appendix B links; added read-only api Code Packs for 1.1, 1.2, 2.2, and 3.1; fixed fail-open, pagination, portability, and exit-code defects in the 2.1, 3.2, and 4.1 packs | Claude Code (Opus 5.5) |
| 2026-08-08 | 0.2.1 | ai-drafted | Added api Code Packs for §2.1 (service-account credential-type audit + legacy-key deletion via the REST service_accounts endpoints) and §4.1 (org/group audit-log export via audit_logs/search inside the 90-day window), plus a cli Code Pack for §3.2 (snyk ignore with mandatory reason and expiry, .snyk suppression audit), all verified against docs.snyk.io API and CLI references | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass (Tier 1 only): rewrote 2.1 for the three service-account credential types (API key never expires and is not recommended; access token 1-year max with no in-place rotation; OAuth 2.0 recommended); added Universal vs Classic Broker and the April 2026 Broker high-availability default to 2.2; documented Enterprise-only audit logs, 90-day rolling retention, and the login/logout exclusion in 4.1; repaired rotted docs.snyk.io links to the platform-administration tree and removed Trust Center / marketing pages from Appendix B. Tier 3/4 research sweep out of scope this pass. | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | ai-drafted | Initial Snyk hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
