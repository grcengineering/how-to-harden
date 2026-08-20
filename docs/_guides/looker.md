---
layout: guide
title: "Looker Hardening Guide"
vendor: "Looker"
slug: "looker"
tier: "5"
category: "Data"
description: "Google BI security for model access, embed secrets, and database connections"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---


## Overview

Looker (Google Cloud) provides business intelligence with LookML modeling and data exploration. REST API, embed secrets, and database connections access enterprise data warehouses. Compromised access exposes business metrics, customer analytics, and data warehouse credentials.

### Intended Audience
- Security engineers managing BI platforms
- Looker administrators
- GRC professionals assessing analytics security
- Third-party risk managers evaluating Google Cloud integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Looker security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Content Security](#2-content-security)
3. [Database Connection Security](#3-database-connection-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML or Google OAuth single sign-on with MFA for all Looker access and disable local Looker password logins.

#### Rationale
**Why This Matters:**
- Centralizes Looker authentication in your corporate IdP so MFA and conditional access apply to every login to the BI platform
- Local Looker password accounts bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO with directory provisioning deprovisions departed users automatically, eliminating orphaned accounts with standing access to dashboards and data
- Looker brokers direct connections to enterprise data warehouses, so a single compromised login can expose business metrics and customer analytics

**Attack Prevented:** Credential theft, phishing, MFA bypass, orphaned-account access

#### ClickOps Implementation

**Step 1: Configure SAML SSO**
1. Navigate to: **Admin → Authentication → SAML**
2. Configure SAML IdP
3. Enable: **Bypass login page**

**Step 2: Google OAuth**
1. Navigate to: **Admin → Authentication → Google**
2. Enable Google OAuth
3. Configure domain restrictions

---

### 1.2 Role-Based Access

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define least-privilege roles by pairing Looker permission sets with model sets, and assign each user the minimum role they need (Admin, Developer, User, or Viewer).

#### Rationale
**Why This Matters:**
- Looker roles combine permission sets and model sets to scope both what a user can do and which LookML models (and underlying data) they can reach
- Over-broad roles let ordinary users develop LookML, manage connections, or view content outside their need-to-know
- The Admin role can change database connections, embed secrets, and authentication settings, so it must be tightly restricted to a small group
- Least privilege limits the blast radius if any single account is compromised

**Attack Prevented:** Privilege escalation, unauthorized data access, lateral movement, insider misuse

#### ClickOps Implementation

**Step 1: Define Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full access |
| Developer | Model development |
| User | Explore and save |
| Viewer | View only |

**Step 2: Configure Model Sets**
1. Navigate to: **Admin → Roles**
2. Create custom roles
3. Assign model/permission sets

**Step 3: Govern the AI-Assistant Roles**

Looker ships dedicated roles for its Gemini and Conversational Analytics surfaces. Treat them as data-access grants, because that is what they are:

| Role | Notes |
|------|-------|
| Gemini in Looker | Cannot be renamed or deleted; grant only to users cleared for AI-assisted exploration |
| Conversational Analytics Viewer | Added in Looker 26.12 — grants use of Conversational Analytics against permitted models |
| Conversational Analytics Advanced Editor / Basic Editor | Added in Looker 26.4 — support the authoring side of Conversational Analytics agents |

1. Navigate to: **Admin → Users → Roles**
2. Review who holds each AI-surface role
3. Remove the roles from users who do not need AI-assisted analysis

**Note:** Looker's AI chat surfaces are gated on the underlying `access_data` permission — a user cannot ask the assistant for data they could not query directly. Do not treat the AI roles as a substitute for correct model-set scoping. ([Looker roles documentation](https://docs.cloud.google.com/looker/docs/admin-panel-users-roles))

---

### 1.3 Govern Looker-Native Multi-Factor Authentication

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Verify and govern Looker's built-in multi-factor authentication for password-based logins via **Admin → General → Auto enablement of MFA**, so that any account not covered by IdP-enforced MFA still presents a second factor.

#### Rationale
**Changed default (Looker 26.12, released 2026-08-05):** Looker-native MFA for password logins is now **enabled by default**. New instances and upgraded instances inherit MFA-on unless an administrator changes the **Auto enablement of MFA** setting. Verify the current state rather than assuming your historical configuration survived the upgrade. ([Looker release notes](https://docs.cloud.google.com/looker/docs/release-notes) · [Admin General settings](https://docs.cloud.google.com/looker/docs/admin-panel-general-settings))

**Why This Matters:**
- SSO enforcement (control 1.1) covers federated logins, but break-glass, contractor, and legacy password accounts often sit outside the IdP — Looker-native MFA is the only second factor those accounts get
- Because the default changed, an instance that previously had MFA deliberately off may now be on (breaking automation that logs in with a password) or an instance assumed to be on may have been explicitly turned off years ago — either way the setting needs an explicit decision, not an inherited one
- Password-only BI logins are directly reachable from the internet and lead straight to warehouse-backed dashboards, making them a high-value credential-stuffing target

**Attack Prevented:** Credential stuffing, password reuse, phishing of non-federated accounts, silent drift after a platform upgrade

#### ClickOps Implementation

**Step 1: Verify the MFA Setting**
1. Navigate to: **Admin → General**
2. Locate **Auto enablement of MFA**
3. Confirm it is enabled; document the decision if you deliberately disable it

**Step 2: Reconcile With SSO**
1. Inventory accounts that authenticate with a Looker password rather than through SAML or Google OAuth
2. Migrate every one you can to SSO (control 1.1)
3. Leave Looker-native MFA on for the remainder, including break-glass accounts

#### Validation & Testing
1. Log in as a password-based test user and confirm the MFA enrollment or challenge prompt appears
2. Re-check the setting after each Looker platform upgrade — defaults have changed once and can change again

---

### 1.4 Harden API Credentials and Service Accounts

**Profile Level:** L2 (Walk)
**NIST 800-53:** IA-5, AC-6

#### Description
Use dedicated, minimum-privilege service-account users for Looker API access rather than attaching API credentials to human accounts, and track the platform changes to how API credentials are created and transmitted.

#### Rationale
**Changed behavior (Looker 26.8):** administrators can no longer create or manage API credentials on behalf of standard users — API credentials for a standard user are now self-managed by that user. Administrators retain the ability to manage credentials for service-account users. If your onboarding runbook has an admin minting API keys for analysts, that step no longer works. ([Looker API authentication](https://docs.cloud.google.com/looker/docs/api-auth) · [release notes](https://docs.cloud.google.com/looker/docs/release-notes))

**Changed behavior (Looker 26.18, October 2026):** the `/login` endpoint accepts credentials **only in the request body**. Integrations that pass `client_id` and `client_secret` as URL query parameters will break — and were leaking secrets into proxy, load-balancer, and access logs in the meantime.

**Why This Matters:**
- API credentials bound to a human account inherit that person's full role set and survive as an unmonitored access path after they change teams; a dedicated service-account user can be scoped to exactly the models and permissions one integration needs
- Credentials passed in a URL are written to every log along the request path, so the query-parameter form has to be eliminated before the platform forces the issue
- Separating human and machine identity makes API activity attributable in System Activity and lets you revoke one integration without disturbing anyone's interactive access

**Attack Prevented:** API credential theft, secret leakage through logs, over-privileged automation, orphaned machine access

#### ClickOps Implementation

**Step 1: Create Dedicated Service-Account Users**
1. Navigate to: **Admin → Users**
2. Create a distinct user per integration, named for the integration
3. Assign a custom role (control 1.2) scoped to only the models and permissions that integration needs
4. Generate API credentials on that user via **Edit → API Keys**

**Step 2: Retire Human-Bound API Credentials**
1. Review existing API keys held by human accounts
2. Repoint each consuming integration at its new service-account credential
3. Delete the human-bound keys

**Step 3: Move Credentials Into the Request Body**
1. Audit every integration that authenticates to `/login`
2. Confirm `client_id` and `client_secret` are sent in the POST body, not the query string
3. Rotate any secret that has previously travelled as a URL parameter — assume it is in logs

#### Validation & Testing
1. Confirm each API key in **Admin → Users** belongs to a service-account user, not a person
2. Exercise each integration against `/login` and confirm it authenticates without query-string credentials

---

## 2. Content Security

### 2.1 Configure Folder Permissions

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3

#### Description
Control content access through folder hierarchy.

#### Rationale
**Why This Matters:**
- Folder permissions are the primary control over who can view and manage dashboards, Looks, and saved content
- Default-open or broadly shared folders expose executive dashboards and competitive metrics to users outside their need-to-know
- Granular access levels (View versus Manage) prevent users from editing or resharing content beyond their role

**Attack Prevented:** Unauthorized content access, data leakage of executive dashboards and competitive metrics, oversharing of sensitive dashboards

#### ClickOps Implementation

**Step 1: Establish the Folder Structure**
1. Navigate to: **Browse → Folders**
2. Create a folder per audience (for example: Finance, Executive, Sales, Shared Reporting) rather than relying on the default shared space
3. Keep sensitive content out of top-level shared folders — content inherits access from its parent folder, so structure is the control
4. Reserve personal folders for drafts; anything with an audience belongs in a governed folder

**Step 2: Configure Access**
1. Navigate to: **Browse → Folder → Manage Access**
2. Set appropriate permissions
3. Limit "View" access default

---

### 2.2 Embed Security

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-21

#### Description
Rotate embed secrets, restrict embedding to an allowlisted set of domains, and use signed SSO embed URLs with short session lengths and user attributes to scope the data each viewer can see.

#### Rationale
**Why This Matters:**
- Embed secrets sign the URLs that grant access to embedded Looker content, so a leaked or stale secret lets an attacker forge authenticated embed sessions
- A domain allowlist prevents attacker-controlled sites from hosting your embedded dashboards and harvesting data
- User attributes in signed SSO embeds enforce row-level and access filtering so each embedded viewer sees only their own data
- Short session lengths limit how long a stolen or replayed embed URL remains usable

**Attack Prevented:** Embed URL forgery, secret leakage, cross-tenant data exposure, unauthorized embedding

#### ClickOps Implementation

**Step 1: Enable Embedding and Manage the Signing Secret**
1. Navigate to: **Admin → Platform → Embed**
2. Set **Embed SSO Authentication** to **Enabled** — the signing secret is not revealed until this is on
3. Use **Set Secret** to create the signing secret on a new instance, or **Reset Secret** to rotate it

   > **Resetting the embed secret immediately breaks every existing signed embed URL.** There is no grace period and no dual-secret window. Schedule the rotation, update every signing integration in the same change, and treat it as a breaking deployment — not a routine hygiene task.

4. Store the secret in your secrets manager; never commit it to the application repository that signs embed URLs

**Step 2: Restrict Where Content May Be Embedded**
1. In the same panel, populate the **Embedded Domain Allowlist** with the exact origins permitted to frame Looker content
2. Enter origins **without trailing slashes** — a trailing slash causes the entry not to match and the embed to fail (or sends you hunting for the wrong problem)
3. Remove development and staging origins from production instances

**Step 3: Prefer Cookieless Embed**
1. For new integrations use **cookieless embed** (available from Looker 23.8), which avoids third-party cookie dependence and is the direction the platform is moving
2. Cookieless embed is authenticated with the separate **Embed JWT secret** — generate it in the same **Admin → Platform → Embed** panel and manage it with the same rigor as the signed-URL secret

**Step 4: Scope Each Embedded Session**
1. Use signed embed URLs (or the cookieless equivalent) rather than exposing Looker content directly
2. Set short session lengths so a captured URL expires quickly
3. Pass user attributes in the signed payload to enforce row-level filtering per embedded viewer

Reference: [Looker embed platform settings](https://docs.cloud.google.com/looker/docs/admin-panel-platform-embed)

#### Validation & Testing
1. Attempt to load an embed URL from an origin not on the allowlist and confirm it is refused
2. After any secret reset, confirm every downstream integration produces working URLs before closing the change

---

### 2.3 Restrict and Audit Public URLs

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-21

#### Description
Govern Looker's **Public URLs** setting, which allows a Look or dashboard to be shared through a link that requires no authentication at all, and periodically audit which content has such a link outstanding.

#### Rationale
**Why This Matters:**
- A public URL is a fully unauthenticated link to query results — anyone who obtains it reads the data, and links leak through email, tickets, chat, and browser history far beyond the person who created it
- The capability is instance-wide until you constrain it: leaving Public URLs enabled with a broadly granted permission means any content author can turn a governed dashboard into an anonymous endpoint without an approval step
- Public URLs bypass every other control in this guide — folder permissions, roles, model sets, and user attributes all stop applying once the content is published anonymously
- Links are durable: content published years ago keeps serving current data until someone finds and revokes it, so the audit matters as much as the setting

**Attack Prevented:** Anonymous data exposure, access-control bypass, uncontrolled data leakage through shared links, long-lived unmonitored exposure

#### ClickOps Implementation

**Step 1: Decide the Instance Posture**
1. Navigate to: **Admin → General**
2. Locate the **Public URLs** setting
3. Disable it outright if your organization has no legitimate need for anonymous sharing — this is the L1 recommendation for instances holding customer or financial data

**Step 2: Restrict the Permission Where Public URLs Are Needed**
1. Navigate to: **Admin → Users → Roles**
2. Grant the public-content permission only through a narrowly held role, not through your general content-author role
3. Pair the grant with an internal approval process for what may be published

**Step 3: Audit Existing Public Content**
1. Navigate to: **Admin → System Activity**
2. Query the content tables for Looks and dashboards flagged as publicly accessible
3. Revoke every public link that no longer has a documented owner and business justification
4. Re-run this audit on a fixed cadence, not only at rollout

References: [Admin General settings](https://docs.cloud.google.com/looker/docs/admin-panel-general-settings) · [How to keep Looker secure](https://docs.cloud.google.com/looker/docs/best-practices/how-to-keep-looker-secure)

#### Validation & Testing
1. Open a known public URL in a private browser window with no Looker session and confirm the expected behavior (refused if you disabled the feature)
2. Confirm the System Activity audit returns zero unowned public content

---

### 2.4 Harden Content Delivery and Egress Paths

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-4, SC-7, SI-10

#### Description
Constrain the paths by which data leaves Looker — scheduled deliveries, data actions, downloaded spreadsheets, and outgoing webhooks — using the egress controls in **Admin → General**.

#### Rationale
**Why This Matters:**
- Scheduled deliveries are a supported, logged, entirely legitimate way to email a full dataset to an arbitrary external address; without an **Email Domain Allowlist for Scheduled Content**, a compromised or malicious account can exfiltrate on a recurring schedule and it looks like normal reporting
- Data actions POST query results to a URL the LookML author specifies — a **URL Allowlist for Data Actions** is what stops that URL from being attacker-controlled
- Downloaded CSV and Excel files carry a formula-injection risk: a cell whose value begins with `=`, `+`, `-`, or `@` is executed by the recipient's spreadsheet application, turning an exported report into code execution on an analyst's workstation. **Block Formulas and Macros in CSV/Excel** neutralizes this
- **Block Inline Embedded Images in Query Results** prevents rendered results from calling out to attacker-controlled image hosts, a classic pixel-based tracking and data-leak channel
- The **Outgoing Webhook Token** lets receiving systems verify a webhook genuinely came from your Looker instance rather than from anyone who learned the endpoint

**Attack Prevented:** Scheduled data exfiltration, CSV/Excel formula injection, server-side request forgery through data actions, tracking-pixel leakage, webhook spoofing

#### ClickOps Implementation

**Step 1: Constrain Scheduled Delivery**
1. Navigate to: **Admin → General**
2. Populate **Email Domain Allowlist for Scheduled Content** with your corporate domains and any explicitly approved partner domains
3. Treat additions to this list as a reviewed change, not a self-service request

**Step 2: Constrain Data Actions and Webhooks**
1. Populate the **URL Allowlist for Data Actions** with the exact destinations your data actions are permitted to call
2. Set an **Outgoing Webhook Token** and configure receiving systems to verify it

**Step 3: Harden Exported and Rendered Content**
1. Enable **Block Formulas and Macros in CSV/Excel**
2. Enable **Block Inline Embedded Images in Query Results**

**Step 4: Consider Closed System (L3)**
1. For multi-tenant or strictly compartmented instances, enable **Closed System**, which prevents users in one group from discovering users and content in another
2. Validate against your support workflows first — closed system changes what administrators and support staff can see

Reference: [Admin General settings](https://docs.cloud.google.com/looker/docs/admin-panel-general-settings)

#### Validation & Testing
1. Attempt to schedule a delivery to an address outside the allowlist and confirm it is rejected
2. Export a Look containing a cell whose value begins with `=` and confirm the downloaded file renders it as text, not a formula
3. Confirm a data action to an unlisted URL is refused

---

## 3. Database Connection Security

### 3.1 Secure Database Connections

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Configure Looker database connections to use SSL/TLS with a least-privilege, read-only service account, and use separate restricted credentials with limited temp-schema access for persistent derived tables (PDTs).

#### Rationale
**Why This Matters:**
- Looker stores the credentials it uses to query your data warehouse, making the connection account a high-value target
- A read-only service account ensures a compromised Looker instance cannot modify or delete source data
- SSL/TLS protects warehouse credentials and query results in transit from interception
- Separate, scoped PDT credentials with restricted temp-schema access confine write access to only the schemas Looker actually needs

**Attack Prevented:** Credential theft, data tampering, man-in-the-middle interception, lateral movement into the data warehouse

#### ClickOps Implementation

**Step 1: Connection Security**
1. Navigate to: **Admin → Database → Connections**
2. Use SSL/TLS connections
3. Configure service account with read-only

**Step 2: PDT Credentials**
1. Limit PDT write permissions
2. Use separate credentials
3. Restrict temp schema access

**Step 3: Review Additional JDBC Parameters**

> **Changed behavior (2026-03-30):** Looker now enforces an allowlist on additional JDBC parameters supplied on a database connection. Parameters that are not supported for the dialect are stripped or cause the connection to error rather than being passed through to the driver. ([Looker release notes](https://docs.cloud.google.com/looker/docs/release-notes))

1. Navigate to: **Admin → Database → Connections** and open each connection
2. Review the **Additional JDBC parameters** field
3. Remove any parameter not documented as supported for that dialect — including any that historically loosened TLS or certificate validation, which is exactly the class of setting this change is meant to stop
4. Re-test the connection after editing; a silently stripped parameter that your queries depended on will surface here rather than in production

---

### 3.2 Query Cost Controls

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7

#### Description
Set query timeouts and row limits so that a single Explore or query cannot exhaust data warehouse resources.

#### Rationale
**Why This Matters:**
- Unbounded queries can consume excessive data warehouse compute, driving runaway costs and starving other workloads
- Query timeouts and row limits cap the resources any single user or query can consume
- These limits blunt denial-of-service attempts and accidental runaway queries against shared infrastructure
- Predictable resource ceilings protect availability for all users sharing the database connection

**Attack Prevented:** Denial of service, resource exhaustion, runaway query cost abuse

#### Implementation

**Step 1: Configure Limits**
1. Navigate to: **Admin → General → Query**
2. Set query timeout
3. Configure row limits

---

## 4. Monitoring & Detection

### 4.1 System Activity

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Review Looker's built-in System Activity dashboards to monitor user activity, query performance, and content usage for anomalies.

#### Rationale
**Why This Matters:**
- System Activity surfaces who is logging in, what they are querying, and which content they access — the data needed to detect misuse
- Without regular review, credential compromise, data scraping, and privilege abuse can go undetected
- Query and content-usage dashboards reveal anomalous bulk extraction or access to sensitive dashboards
- Activity records support incident investigation and compliance audit requirements

**Attack Prevented:** Undetected account compromise, data exfiltration, insider misuse, audit gaps

#### ClickOps Implementation

**Step 1: Access System Activity**
1. Navigate to: **Admin → System Activity**
2. Review dashboards:
   - User Activity
   - Query Performance
   - Content Usage

#### Detection Focus

Point your System Activity reviews at the events the controls in this guide depend on:

| Signal | Why it matters | Related control |
|--------|----------------|-----------------|
| Looks and dashboards with a public URL outstanding | An anonymous link bypasses every other access control | [2.3](#23-restrict-and-audit-public-urls) |
| Scheduled deliveries to non-corporate email domains | Recurring, legitimate-looking data exfiltration | [2.4](#24-harden-content-delivery-and-egress-paths) |
| API activity attributed to human accounts rather than service-account users | Indicates un-migrated or unmanaged API credentials | [1.4](#14-harden-api-credentials-and-service-accounts) |
| Password-based logins on accounts expected to use SSO | Break-glass or legacy accounts drifting outside IdP control | [1.1](#11-enforce-sso-with-mfa), [1.3](#13-govern-looker-native-multi-factor-authentication) |
| Role and permission-set changes, especially grants of Admin or AI-surface roles | Privilege escalation and unreviewed data-access expansion | [1.2](#12-role-based-access) |
| Users running unusually large or unusually many queries against sensitive models | Bulk extraction ahead of exfiltration | [3.2](#32-query-cost-controls) |
| Embed-secret and connection changes | High-impact configuration events that break or widen access | [2.2](#22-embed-security), [3.1](#31-secure-database-connections) |

---

## Appendix A: Edition Compatibility

| Control | Standard | Enterprise | Embed |
|---------|----------|------------|-------|
| SAML SSO | ✅ | ✅ | ✅ |
| Custom Roles | ✅ | ✅ | ✅ |
| System Activity | ✅ | ✅ | ✅ |
| SSO Embed | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Looker / Google Cloud Documentation:**
- [Looker Documentation](https://docs.cloud.google.com/looker/docs)
- [How to Keep Looker Secure](https://docs.cloud.google.com/looker/docs/best-practices/how-to-keep-looker-secure)
- [Admin Panel: General Settings](https://docs.cloud.google.com/looker/docs/admin-panel-general-settings)
- [Admin Panel: Platform — Embed](https://docs.cloud.google.com/looker/docs/admin-panel-platform-embed)
- [Admin Panel: Users — Roles](https://docs.cloud.google.com/looker/docs/admin-panel-users-roles)
- [Looker API Authentication](https://docs.cloud.google.com/looker/docs/api-auth)
- [Looker Release Notes](https://docs.cloud.google.com/looker/docs/release-notes)

> **Host note:** `cloud.google.com/looker/*` URLs now redirect (HTTP 301) to `docs.cloud.google.com/looker/*`. This guide cites the canonical post-redirect host throughout; update any bookmarks or internal runbooks that still point at the old path.

**API & Developer Resources:**
- [Looker REST API Reference](https://docs.cloud.google.com/looker/docs/reference/looker-api/latest)
- [Looker SDK](https://docs.cloud.google.com/looker/docs/api-sdk)

**Compliance Frameworks:**
- Looker (Google Cloud) inherits Google Cloud Platform compliance certifications including SOC 2, SOC 3, ISO 27001, ISO 27017, ISO 27018, FedRAMP, and HIPAA. Obtain current attestation reports through your Google Cloud account team — certification inheritance is not a hardening control, and nothing in this section substitutes for the configuration work above.

**Security Incidents:**
- **GCP-2026-049 / CVE-2026-15810 (published 2026-07-22, High):** a reflected cross-site scripting vulnerability in Looker exploitable against authenticated administrators. Looker-hosted (Google-managed) instances were mitigated automatically; **Looker (original) customer-hosted deployments must be patched to the fixed versions listed in the bulletin.** If you run self-hosted Looker, confirm your version against the bulletin's patch floors. — [Google Cloud security bulletins](https://docs.cloud.google.com/support/bulletins)
- Beyond the above, no major Looker-specific public breach has been identified. Google Cloud publishes ongoing security bulletins at [docs.cloud.google.com/support/bulletins](https://docs.cloud.google.com/support/bulletins) — subscribe rather than polling.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass. New controls: 1.3 Looker-native MFA (enabled by default from 26.12), 1.4 API credential and service-account hygiene (26.8 and 26.18 changes), 2.3 Public URLs, 2.4 delivery/egress hardening. Corrected 2.2 to real embed setting names and added the secret-reset breaking-change callout; added AI-surface roles to 1.2 and the JDBC parameter allowlist to 3.1; populated 2.1 folder structure and 4.1 Detection Focus; added CVE-2026-15810 to the incidents section; removed Trust Center and Compliance Reports Manager references and migrated all links to the canonical docs.cloud.google.com host. Tier 3/4 research not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Looker hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)
